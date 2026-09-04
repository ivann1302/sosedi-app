import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AdminCapability, BookingStatus, ItemStatus } from '@prisma/client';
import { createHash, randomUUID } from 'crypto';
import sharp from 'sharp';
import type { AdminAuditContext } from '../admin/admin-audit-context';
import { PrismaService } from '../prisma/prisma.service';
import { ConfirmAvatarUploadDto } from './dto/confirm-avatar-upload.dto';
import { ConfirmItemPhotoUploadDto } from './dto/confirm-item-photo-upload.dto';
import { RequestUploadUrlDto } from './dto/request-upload-url.dto';
import { PhotoProcessingQueue } from './photo-processing.queue';
import { S3StorageService } from './s3-storage.service';
import {
  ALLOWED_UPLOAD_CONTENT_TYPES,
  AVATAR_SIZE,
  MAX_UPLOAD_SIZE_BYTES,
  MAX_ITEM_PHOTO_COUNT,
  PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
  PRESIGNED_UPLOAD_EXPIRES_SECONDS,
} from './upload.constants';
import {
  PresignedUploadResponse,
  AvatarUploadResponse,
  ItemPhotoUploadResponse,
  PrivateFileDownloadResponse,
  UploadPurpose,
  VerifiedBookingEvidence,
  VerifiedDisputeEvidence,
  VerifiedSupportAttachment,
} from './upload.types';

const contentTypeExtensions: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

@Injectable()
export class UploadService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: S3StorageService,
    private readonly photoQueue: PhotoProcessingQueue,
  ) {}

  async requestUploadUrl(
    userId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    if (dto.purpose === UploadPurpose.KYC_DOCUMENT) {
      throw new ForbiddenException(
        'Загрузка KYC-документов отключена до принятия LOCAL_KYC ADR',
      );
    }

    this.ensureAllowedFile(dto.contentType, dto.sizeBytes);

    if (dto.purpose === UploadPurpose.AVATAR) {
      return this.createAvatarUploadUrl(userId, dto);
    }
    if (dto.purpose === UploadPurpose.BOOKING_EVIDENCE) {
      return this.createBookingEvidenceUploadUrl(userId, dto);
    }
    if (dto.purpose === UploadPurpose.DISPUTE_EVIDENCE) {
      return this.createDisputeEvidenceUploadUrl(userId, dto);
    }
    if (dto.purpose === UploadPurpose.SUPPORT_ATTACHMENT) {
      return this.createSupportAttachmentUploadUrl(userId, dto, false);
    }

    return this.createItemPhotoUploadUrl(userId, dto);
  }

  requestAdminSupportAttachmentUploadUrl(
    adminId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    this.ensureAllowedFile(dto.contentType, dto.sizeBytes);
    if (dto.purpose !== UploadPurpose.SUPPORT_ATTACHMENT) {
      throw new BadRequestException(
        'Operator upload поддерживает только SUPPORT_ATTACHMENT',
      );
    }
    return this.createSupportAttachmentUploadUrl(adminId, dto, true);
  }

  async verifyBookingEvidenceIntent(
    userId: string,
    bookingId: string,
    intentId: string,
  ): Promise<VerifiedBookingEvidence> {
    const intent = await this.prisma.uploadIntent.findFirst({
      where: {
        id: intentId,
        actorId: userId,
        entityId: bookingId,
        purpose: UploadPurpose.BOOKING_EVIDENCE,
        confirmedAt: null,
        expiresAt: { gt: new Date() },
      },
      select: {
        id: true,
        entityId: true,
        bucket: true,
        objectKey: true,
        contentType: true,
        sizeBytes: true,
      },
    });
    if (!intent) {
      throw new NotFoundException('Upload intent не найден');
    }

    this.ensureBookingEvidenceIntentBinding(userId, intent);
    await this.ensureBookingParticipant(userId, bookingId);
    await this.ensureUploadedObject(intent);
    const bytes = await this.storage.getObjectBuffer(
      intent.bucket,
      intent.objectKey,
    );
    const sanitized = await this.sanitizePrivateImage(intent, bytes);
    return {
      intentId: intent.id,
      bucket: intent.bucket,
      objectKey: intent.objectKey,
      sha256: createHash('sha256').update(sanitized).digest('hex'),
    };
  }

  async verifyDisputeEvidenceIntent(
    userId: string,
    disputeId: string,
    intentId: string,
  ): Promise<VerifiedDisputeEvidence> {
    const intent = await this.prisma.uploadIntent.findFirst({
      where: {
        id: intentId,
        actorId: userId,
        entityId: disputeId,
        purpose: UploadPurpose.DISPUTE_EVIDENCE,
        confirmedAt: null,
        expiresAt: { gt: new Date() },
      },
      select: {
        id: true,
        entityId: true,
        bucket: true,
        objectKey: true,
        contentType: true,
        sizeBytes: true,
      },
    });
    if (!intent) {
      throw new NotFoundException('Upload intent не найден');
    }

    this.ensureDisputeEvidenceIntentBinding(userId, intent);
    await this.ensureDisputeParticipant(userId, disputeId);
    await this.ensureUploadedObject(intent);
    const bytes = await this.storage.getObjectBuffer(
      intent.bucket,
      intent.objectKey,
    );
    const sanitized = await this.sanitizePrivateImage(intent, bytes);
    return {
      intentId: intent.id,
      bucket: intent.bucket,
      objectKey: intent.objectKey,
      sha256: createHash('sha256').update(sanitized).digest('hex'),
    };
  }

  async getDisputeEvidenceDownloadUrl(
    userId: string,
    bookingId: string,
    disputeId: string,
    evidenceId: string,
  ): Promise<PrivateFileDownloadResponse> {
    const evidence = await this.prisma.disputeEvidence.findFirst({
      where: {
        id: evidenceId,
        disputeId,
        dispute: {
          bookingId,
          booking: {
            OR: [{ borrowerId: userId }, { lenderId: userId }],
          },
        },
        uploadIntent: { confirmedAt: { not: null } },
      },
      select: {
        uploadIntent: {
          select: { bucket: true, objectKey: true },
        },
      },
    });
    if (!evidence) {
      throw new NotFoundException('Evidence не найден');
    }
    return {
      downloadUrl: await this.storage.createPresignedDownloadUrl(
        evidence.uploadIntent.bucket,
        evidence.uploadIntent.objectKey,
        PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
      ),
      expiresInSeconds: PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
    };
  }

  async getBookingEvidenceDownloadUrl(
    userId: string,
    bookingId: string,
    evidenceId: string,
  ): Promise<PrivateFileDownloadResponse> {
    const evidence = await this.prisma.bookingEvidence.findFirst({
      where: {
        id: evidenceId,
        act: {
          bookingId,
          booking: {
            OR: [{ borrowerId: userId }, { lenderId: userId }],
          },
        },
        uploadIntent: { confirmedAt: { not: null } },
      },
      select: {
        uploadIntent: {
          select: { bucket: true, objectKey: true },
        },
      },
    });
    if (!evidence) {
      throw new NotFoundException('Evidence не найден');
    }
    return {
      downloadUrl: await this.storage.createPresignedDownloadUrl(
        evidence.uploadIntent.bucket,
        evidence.uploadIntent.objectKey,
        PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
      ),
      expiresInSeconds: PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
    };
  }

  async verifySupportAttachmentIntent(
    actorId: string,
    ticketId: string,
    intentId: string,
    allowAdmin: boolean,
  ): Promise<VerifiedSupportAttachment> {
    const intent = await this.prisma.uploadIntent.findFirst({
      where: {
        id: intentId,
        actorId,
        entityId: ticketId,
        purpose: UploadPurpose.SUPPORT_ATTACHMENT,
        confirmedAt: null,
        expiresAt: { gt: new Date() },
      },
      select: {
        id: true,
        entityId: true,
        bucket: true,
        objectKey: true,
        contentType: true,
        sizeBytes: true,
      },
    });
    if (!intent) {
      throw new NotFoundException('Upload intent не найден');
    }

    this.ensureSupportAttachmentIntentBinding(actorId, intent);
    await this.ensureSupportTicketAccess(actorId, ticketId, allowAdmin);
    await this.ensureUploadedObject(intent);
    const bytes = await this.storage.getObjectBuffer(
      intent.bucket,
      intent.objectKey,
    );
    const sanitized = await this.sanitizePrivateImage(intent, bytes);
    return {
      intentId: intent.id,
      bucket: intent.bucket,
      objectKey: intent.objectKey,
      sha256: createHash('sha256').update(sanitized).digest('hex'),
    };
  }

  async getSupportAttachmentDownloadUrl(
    actorId: string,
    ticketId: string,
    attachmentId: string,
    allowAdmin: boolean,
    context?: AdminAuditContext,
  ): Promise<PrivateFileDownloadResponse> {
    await this.ensureSupportTicketAccess(actorId, ticketId, allowAdmin);
    const attachment = await this.prisma.supportAttachment.findFirst({
      where: {
        id: attachmentId,
        message: { ticketId },
        uploadIntent: { confirmedAt: { not: null } },
      },
      select: {
        uploadIntent: {
          select: { bucket: true, objectKey: true },
        },
      },
    });
    if (!attachment) {
      throw new NotFoundException('Вложение не найдено');
    }
    if (allowAdmin) {
      if (!context) {
        throw new Error('Admin audit context is required');
      }
      await this.prisma.adminAuditLog.create({
        data: {
          adminId: actorId,
          action: 'SUPPORT_ATTACHMENT_DOWNLOAD_REQUESTED',
          entityType: 'SupportAttachment',
          entityId: attachmentId,
          capability: AdminCapability.SUPPORT,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          metadata: { supportTicketId: ticketId },
        },
      });
    }
    return {
      downloadUrl: await this.storage.createPresignedDownloadUrl(
        attachment.uploadIntent.bucket,
        attachment.uploadIntent.objectKey,
        PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
      ),
      expiresInSeconds: PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
    };
  }

  async confirmItemPhotoUpload(
    userId: string,
    dto: ConfirmItemPhotoUploadDto,
  ): Promise<ItemPhotoUploadResponse> {
    const intent = await this.prisma.uploadIntent.findFirst({
      where: {
        id: dto.intentId,
        actorId: userId,
        purpose: UploadPurpose.ITEM_PHOTO,
      },
      select: {
        id: true,
        entityId: true,
        bucket: true,
        objectKey: true,
        contentType: true,
        sizeBytes: true,
        expiresAt: true,
        confirmedAt: true,
      },
    });

    if (!intent) {
      throw new NotFoundException('Upload intent не найден');
    }

    this.ensureItemPhotoIntentBinding(intent);
    await this.ensureOwnedItem(userId, intent.entityId);

    if (intent.confirmedAt) {
      const existingPhoto = await this.prisma.itemPhoto.findUnique({
        where: { uploadIntentId: intent.id },
      });
      if (!existingPhoto) {
        throw new BadRequestException('Upload intent уже использован');
      }
      return this.toItemPhotoResponse(existingPhoto);
    }

    await this.ensureNoUnfinishedBookings(intent.entityId);

    if (intent.expiresAt <= new Date()) {
      throw new BadRequestException('Upload intent истёк');
    }

    await this.ensureUploadedObject(intent);

    const confirmed = await this.prisma.$transaction(async (tx) => {
      const confirmedAt = new Date();
      const consumed = await tx.uploadIntent.updateMany({
        where: {
          id: intent.id,
          actorId: userId,
          confirmedAt: null,
          expiresAt: { gt: confirmedAt },
        },
        data: { confirmedAt },
      });
      if (consumed.count !== 1) {
        const existingPhoto = await tx.itemPhoto.findUnique({
          where: { uploadIntentId: intent.id },
        });
        if (existingPhoto) {
          return {
            photo: existingPhoto,
            sourceBucket: intent.bucket,
            sourceKey: intent.objectKey,
            shouldQueue: false,
          };
        }
        throw new BadRequestException(
          'Upload intent уже использован или истёк',
        );
      }

      const photoCount = await tx.itemPhoto.count({
        where: { itemId: intent.entityId },
      });
      if (photoCount >= MAX_ITEM_PHOTO_COUNT) {
        throw new BadRequestException(
          `У объявления может быть не больше ${MAX_ITEM_PHOTO_COUNT} фото`,
        );
      }
      const isCover = dto.isCover ?? photoCount === 0;

      if (isCover) {
        await tx.itemPhoto.updateMany({
          where: { itemId: intent.entityId },
          data: { isCover: false },
        });
      }

      const photo = await tx.itemPhoto.create({
        data: {
          itemId: intent.entityId,
          uploadIntentId: intent.id,
          originalUrl: null,
          thumbnailUrl: null,
          previewUrl: null,
          sortOrder: dto.sortOrder ?? photoCount,
          isCover,
        },
        select: {
          id: true,
          itemId: true,
          originalUrl: true,
          thumbnailUrl: true,
          previewUrl: true,
          sortOrder: true,
          isCover: true,
          createdAt: true,
        },
      });
      await tx.item.update({
        where: { id: intent.entityId },
        data: { status: ItemStatus.PENDING, rejectReason: null },
      });

      return {
        photo,
        sourceBucket: intent.bucket,
        sourceKey: intent.objectKey,
        shouldQueue: true,
      };
    });

    // Фото обрабатываются асинхронно, чтобы создание объявления не ждало thumbnail/preview.
    if (confirmed.shouldQueue) {
      await this.photoQueue.addItemPhotoUploaded({
        itemPhotoId: confirmed.photo.id,
        itemId: confirmed.photo.itemId,
        sourceBucket: confirmed.sourceBucket,
        sourceKey: confirmed.sourceKey,
      });
    }

    return this.toItemPhotoResponse(confirmed.photo);
  }

  async confirmAvatarUpload(
    userId: string,
    dto: ConfirmAvatarUploadDto,
  ): Promise<AvatarUploadResponse> {
    const intent = await this.prisma.uploadIntent.findFirst({
      where: {
        id: dto.intentId,
        actorId: userId,
        purpose: UploadPurpose.AVATAR,
      },
      select: {
        id: true,
        entityId: true,
        bucket: true,
        objectKey: true,
        contentType: true,
        sizeBytes: true,
        expiresAt: true,
        confirmedAt: true,
      },
    });
    if (!intent || intent.entityId !== userId) {
      throw new NotFoundException('Upload intent не найден');
    }

    this.ensureAvatarIntentBinding(intent);
    const publicBucket = this.storage.getPublicBucket();
    const publicKey = `avatars/${userId}/${intent.id}.webp`;
    const avatarUrl = this.storage.getPublicUrl(publicBucket, publicKey);

    if (intent.confirmedAt) {
      return { avatarUrl };
    }
    if (intent.expiresAt <= new Date()) {
      throw new BadRequestException('Upload intent истёк');
    }

    await this.ensureUploadedObject(intent);
    const source = await this.storage.getObjectBuffer(
      intent.bucket,
      intent.objectKey,
    );
    const avatar = await sharp(source, { failOn: 'warning' })
      .rotate()
      .resize(AVATAR_SIZE, AVATAR_SIZE, { fit: 'cover' })
      .webp({ quality: 85 })
      .toBuffer();
    await this.storage.putObject(publicBucket, publicKey, avatar, 'image/webp');

    await this.prisma.$transaction(async (tx) => {
      const confirmedAt = new Date();
      const consumed = await tx.uploadIntent.updateMany({
        where: {
          id: intent.id,
          actorId: userId,
          confirmedAt: null,
          expiresAt: { gt: confirmedAt },
        },
        data: { confirmedAt },
      });
      if (consumed.count !== 1) {
        const replay = await tx.uploadIntent.findFirst({
          where: {
            id: intent.id,
            actorId: userId,
            purpose: UploadPurpose.AVATAR,
            confirmedAt: { not: null },
          },
          select: { id: true },
        });
        if (!replay) {
          throw new BadRequestException(
            'Upload intent уже использован или истёк',
          );
        }
        return;
      }

      await tx.user.update({
        where: { id: userId },
        data: { avatarUrl },
      });
    });

    await this.storage
      .deleteObject(intent.bucket, intent.objectKey)
      .catch(() => undefined);
    return { avatarUrl };
  }

  async getPrivateFileDownloadUrl(
    userId: string,
    intentId: string,
  ): Promise<PrivateFileDownloadResponse> {
    const intent = await this.prisma.uploadIntent.findFirst({
      where: {
        id: intentId,
        actorId: userId,
        purpose: UploadPurpose.ITEM_PHOTO,
        expiresAt: { gt: new Date() },
      },
      select: {
        entityId: true,
        bucket: true,
        objectKey: true,
        contentType: true,
      },
    });

    if (!intent) {
      throw new NotFoundException('Private-файл не найден');
    }

    this.ensureItemPhotoIntentBinding(intent);
    await this.ensureOwnedItem(userId, intent.entityId);
    const object = await this.storage.inspectUploadedObject(
      intent.bucket,
      intent.objectKey,
    );
    if (!object) {
      throw new NotFoundException('Private-файл не найден');
    }

    return {
      downloadUrl: await this.storage.createPresignedDownloadUrl(
        intent.bucket,
        intent.objectKey,
        PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
      ),
      expiresInSeconds: PRESIGNED_DOWNLOAD_EXPIRES_SECONDS,
    };
  }

  private async createItemPhotoUploadUrl(
    userId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    if (!dto.itemId || dto.bookingId || dto.disputeId || dto.supportTicketId) {
      throw new BadRequestException('Для фото вещи нужен itemId');
    }

    await this.ensureOwnedItem(userId, dto.itemId);
    await this.ensureNoUnfinishedBookings(dto.itemId);

    return this.createPresignedUpload(
      userId,
      dto,
      dto.itemId,
      this.getItemQuarantinePrefix(dto.itemId),
    );
  }

  private createAvatarUploadUrl(
    userId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    if (dto.itemId || dto.bookingId || dto.disputeId || dto.supportTicketId) {
      throw new BadRequestException('Для аватара itemId не используется');
    }
    return this.createPresignedUpload(
      userId,
      dto,
      userId,
      this.getAvatarQuarantinePrefix(userId),
    );
  }

  private async createBookingEvidenceUploadUrl(
    userId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    if (!dto.bookingId || dto.itemId || dto.disputeId || dto.supportTicketId) {
      throw new BadRequestException('Для evidence нужен bookingId без itemId');
    }
    await this.ensureBookingParticipant(userId, dto.bookingId);
    return this.createPresignedUpload(
      userId,
      dto,
      dto.bookingId,
      this.getBookingEvidenceQuarantinePrefix(dto.bookingId, userId),
    );
  }

  private async createDisputeEvidenceUploadUrl(
    userId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    if (!dto.disputeId || dto.itemId || dto.bookingId || dto.supportTicketId) {
      throw new BadRequestException(
        'Для evidence спора нужен disputeId без других entity ID',
      );
    }
    await this.ensureDisputeParticipant(userId, dto.disputeId);
    return this.createPresignedUpload(
      userId,
      dto,
      dto.disputeId,
      this.getDisputeEvidenceQuarantinePrefix(dto.disputeId, userId),
    );
  }

  private async createSupportAttachmentUploadUrl(
    actorId: string,
    dto: RequestUploadUrlDto,
    allowAdmin: boolean,
  ): Promise<PresignedUploadResponse> {
    if (!dto.supportTicketId || dto.itemId || dto.bookingId || dto.disputeId) {
      throw new BadRequestException(
        'Для вложения нужен supportTicketId без itemId/bookingId',
      );
    }
    await this.ensureSupportTicketAccess(
      actorId,
      dto.supportTicketId,
      allowAdmin,
    );
    return this.createPresignedUpload(
      actorId,
      dto,
      dto.supportTicketId,
      this.getSupportAttachmentQuarantinePrefix(dto.supportTicketId, actorId),
    );
  }

  private async createPresignedUpload(
    userId: string,
    dto: RequestUploadUrlDto,
    entityId: string,
    prefix: string,
  ): Promise<PresignedUploadResponse> {
    const bucket = this.storage.getPrivateBucket();
    const key = `${prefix}${randomUUID()}.${this.getExtension(dto.contentType)}`;
    const intent = await this.prisma.uploadIntent.create({
      data: {
        actorId: userId,
        purpose: dto.purpose,
        entityId,
        bucket,
        objectKey: key,
        contentType: dto.contentType,
        sizeBytes: dto.sizeBytes,
        expiresAt: new Date(
          Date.now() + PRESIGNED_UPLOAD_EXPIRES_SECONDS * 1000,
        ),
      },
      select: { id: true },
    });
    const presignedPost = await this.storage.createPresignedPostUpload(
      bucket,
      key,
      dto.contentType,
      dto.sizeBytes,
      PRESIGNED_UPLOAD_EXPIRES_SECONDS,
    );

    return {
      intentId: intent.id,
      uploadUrl: presignedPost.uploadUrl,
      method: 'POST',
      bucket,
      key,
      publicUrl: null,
      expiresInSeconds: PRESIGNED_UPLOAD_EXPIRES_SECONDS,
      fields: presignedPost.fields,
      constraints: {
        contentType: dto.contentType,
        sizeBytes: dto.sizeBytes,
      },
    };
  }

  private ensureAllowedFile(contentType: string, sizeBytes: number): void {
    if (
      !ALLOWED_UPLOAD_CONTENT_TYPES.includes(
        contentType as (typeof ALLOWED_UPLOAD_CONTENT_TYPES)[number],
      )
    ) {
      throw new BadRequestException('Разрешены только JPEG, PNG и WebP');
    }

    if (sizeBytes < 1 || sizeBytes > MAX_UPLOAD_SIZE_BYTES) {
      throw new BadRequestException('Размер файла не может быть больше 10 МБ');
    }
  }

  private getExtension(contentType: string): string {
    const extension = contentTypeExtensions[contentType];

    if (!extension) {
      throw new BadRequestException('Неподдерживаемый тип файла');
    }

    return extension;
  }

  private getItemQuarantinePrefix(itemId: string): string {
    return `quarantine/item-photos/${itemId}/`;
  }

  private getAvatarQuarantinePrefix(userId: string): string {
    return `quarantine/avatars/${userId}/`;
  }

  private getBookingEvidenceQuarantinePrefix(
    bookingId: string,
    userId: string,
  ): string {
    return `quarantine/booking-evidence/${bookingId}/${userId}/`;
  }

  private getDisputeEvidenceQuarantinePrefix(
    disputeId: string,
    userId: string,
  ): string {
    return `quarantine/dispute-evidence/${disputeId}/${userId}/`;
  }

  private getSupportAttachmentQuarantinePrefix(
    ticketId: string,
    actorId: string,
  ): string {
    return `quarantine/support-attachments/${ticketId}/${actorId}/`;
  }

  private ensureBookingEvidenceIntentBinding(
    userId: string,
    intent: {
      entityId: string;
      bucket: string;
      objectKey: string;
      contentType: string;
    },
  ): void {
    const prefix = this.getBookingEvidenceQuarantinePrefix(
      intent.entityId,
      userId,
    );
    const extension = this.getExtension(intent.contentType);
    const fileName = intent.objectKey.slice(prefix.length);
    if (
      intent.bucket !== this.storage.getPrivateBucket() ||
      !intent.objectKey.startsWith(prefix) ||
      !fileName ||
      fileName.includes('/') ||
      !fileName.endsWith(`.${extension}`)
    ) {
      throw new BadRequestException(
        'Bucket или object key не соответствует upload intent',
      );
    }
  }

  private ensureDisputeEvidenceIntentBinding(
    userId: string,
    intent: {
      entityId: string;
      bucket: string;
      objectKey: string;
      contentType: string;
    },
  ): void {
    const prefix = this.getDisputeEvidenceQuarantinePrefix(
      intent.entityId,
      userId,
    );
    const extension = this.getExtension(intent.contentType);
    const fileName = intent.objectKey.slice(prefix.length);
    if (
      intent.bucket !== this.storage.getPrivateBucket() ||
      !intent.objectKey.startsWith(prefix) ||
      !fileName ||
      fileName.includes('/') ||
      !fileName.endsWith(`.${extension}`)
    ) {
      throw new BadRequestException(
        'Bucket или object key не соответствует upload intent',
      );
    }
  }

  private ensureSupportAttachmentIntentBinding(
    actorId: string,
    intent: {
      entityId: string;
      bucket: string;
      objectKey: string;
      contentType: string;
    },
  ): void {
    const prefix = this.getSupportAttachmentQuarantinePrefix(
      intent.entityId,
      actorId,
    );
    const extension = this.getExtension(intent.contentType);
    const fileName = intent.objectKey.slice(prefix.length);
    if (
      intent.bucket !== this.storage.getPrivateBucket() ||
      !intent.objectKey.startsWith(prefix) ||
      !fileName ||
      fileName.includes('/') ||
      !fileName.endsWith(`.${extension}`)
    ) {
      throw new BadRequestException(
        'Bucket или object key не соответствует upload intent',
      );
    }
  }

  private async ensureBookingParticipant(
    userId: string,
    bookingId: string,
  ): Promise<void> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        OR: [{ borrowerId: userId }, { lenderId: userId }],
        status: {
          in: [
            BookingStatus.CONFIRMED,
            BookingStatus.ACTIVE,
            BookingStatus.RETURNED,
          ],
        },
      },
      select: { id: true },
    });
    if (!booking) {
      throw new NotFoundException('Бронирование не найдено');
    }
  }

  private async ensureDisputeParticipant(
    userId: string,
    disputeId: string,
  ): Promise<void> {
    const dispute = await this.prisma.financialDispute.findFirst({
      where: {
        id: disputeId,
        booking: {
          OR: [{ borrowerId: userId }, { lenderId: userId }],
        },
      },
      select: { id: true },
    });
    if (!dispute) {
      throw new NotFoundException('Спор не найден');
    }
  }

  private async ensureSupportTicketAccess(
    actorId: string,
    ticketId: string,
    allowAdmin: boolean,
  ): Promise<void> {
    const ticket = await this.prisma.supportTicket.findFirst({
      where: {
        id: ticketId,
        type: 'GENERAL',
        ...(allowAdmin ? {} : { userId: actorId }),
      },
      select: { id: true },
    });
    if (!ticket) {
      throw new NotFoundException('Обращение не найдено');
    }
  }

  private ensureItemPhotoIntentBinding(intent: {
    entityId: string;
    bucket: string;
    objectKey: string;
    contentType: string;
  }): void {
    const prefix = this.getItemQuarantinePrefix(intent.entityId);
    const extension = this.getExtension(intent.contentType);
    const fileName = intent.objectKey.slice(prefix.length);

    if (
      intent.bucket !== this.storage.getPrivateBucket() ||
      !intent.objectKey.startsWith(prefix) ||
      !fileName ||
      fileName.includes('/') ||
      !fileName.endsWith(`.${extension}`)
    ) {
      throw new BadRequestException(
        'Bucket или object key не соответствует upload intent',
      );
    }
  }

  private ensureAvatarIntentBinding(intent: {
    entityId: string;
    bucket: string;
    objectKey: string;
    contentType: string;
  }): void {
    const prefix = this.getAvatarQuarantinePrefix(intent.entityId);
    const extension = this.getExtension(intent.contentType);
    const fileName = intent.objectKey.slice(prefix.length);

    if (
      intent.bucket !== this.storage.getPrivateBucket() ||
      !intent.objectKey.startsWith(prefix) ||
      !fileName ||
      fileName.includes('/') ||
      !fileName.endsWith(`.${extension}`)
    ) {
      throw new BadRequestException(
        'Bucket или object key не соответствует upload intent',
      );
    }
  }

  private async ensureUploadedObject(intent: {
    bucket: string;
    objectKey: string;
    contentType: string;
    sizeBytes: number;
  }): Promise<void> {
    const object = await this.storage.inspectUploadedObject(
      intent.bucket,
      intent.objectKey,
    );
    if (!object) {
      throw new BadRequestException('Загруженный объект не найден');
    }
    if (
      object.sizeBytes !== intent.sizeBytes ||
      object.contentType !== intent.contentType
    ) {
      throw new BadRequestException(
        'Размер или content type объекта не совпадает с upload intent',
      );
    }
    if (!this.hasExpectedMagicBytes(intent.contentType, object.prefix)) {
      throw new BadRequestException(
        'Содержимое файла не соответствует заявленному типу',
      );
    }
  }

  private async sanitizePrivateImage(
    intent: {
      bucket: string;
      objectKey: string;
      contentType: string;
    },
    source: Buffer,
  ): Promise<Buffer> {
    let sanitized: Buffer;
    try {
      const image = sharp(source, { failOn: 'warning' }).rotate();
      sanitized =
        intent.contentType === 'image/jpeg'
          ? await image.jpeg({ quality: 95 }).toBuffer()
          : intent.contentType === 'image/png'
            ? await image.png().toBuffer()
            : await image.webp({ quality: 90 }).toBuffer();
    } catch {
      throw new BadRequestException(
        'Изображение не удалось безопасно обработать',
      );
    }

    await this.storage.putObject(
      intent.bucket,
      intent.objectKey,
      sanitized,
      intent.contentType,
    );
    return sanitized;
  }

  private hasExpectedMagicBytes(contentType: string, bytes: Buffer): boolean {
    if (contentType === 'image/jpeg') {
      return (
        bytes.length >= 3 &&
        bytes[0] === 0xff &&
        bytes[1] === 0xd8 &&
        bytes[2] === 0xff
      );
    }
    if (contentType === 'image/png') {
      return bytes
        .subarray(0, 8)
        .equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
    }
    if (contentType === 'image/webp') {
      return (
        bytes.length >= 12 &&
        bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
        bytes.subarray(8, 12).toString('ascii') === 'WEBP'
      );
    }
    return false;
  }

  private toItemPhotoResponse(photo: {
    id: string;
    itemId: string;
    originalUrl: string | null;
    thumbnailUrl: string | null;
    previewUrl: string | null;
    sortOrder: number;
    isCover: boolean;
    createdAt: Date;
  }): ItemPhotoUploadResponse {
    return {
      id: photo.id,
      itemId: photo.itemId,
      originalUrl: photo.originalUrl,
      thumbnailUrl: photo.thumbnailUrl,
      previewUrl: photo.previewUrl,
      sortOrder: photo.sortOrder,
      isCover: photo.isCover,
      createdAt: photo.createdAt,
    };
  }

  private async ensureOwnedItem(userId: string, itemId: string): Promise<void> {
    const item = await this.prisma.item.findFirst({
      where: { id: itemId, ownerId: userId },
      select: { id: true },
    });

    if (!item) {
      throw new NotFoundException('Объявление не найдено');
    }
  }

  private async ensureNoUnfinishedBookings(itemId: string): Promise<void> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        itemId,
        status: {
          in: [
            BookingStatus.PENDING,
            BookingStatus.CONFIRMED,
            BookingStatus.ACTIVE,
            BookingStatus.RETURNED,
          ],
        },
      },
      select: { id: true },
    });
    if (booking) {
      throw new ConflictException({
        code: 'ITEM_HAS_UNFINISHED_BOOKINGS',
        message: 'Объявление нельзя изменить до завершения аренды',
      });
    }
  }
}
