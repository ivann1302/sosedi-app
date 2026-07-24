import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { ConfirmToolPhotoUploadDto } from './dto/confirm-tool-photo-upload.dto';
import { RequestUploadUrlDto } from './dto/request-upload-url.dto';
import { PhotoProcessingQueue } from './photo-processing.queue';
import { S3StorageService } from './s3-storage.service';
import {
  ALLOWED_UPLOAD_CONTENT_TYPES,
  MAX_UPLOAD_SIZE_BYTES,
  PRESIGNED_UPLOAD_EXPIRES_SECONDS,
} from './upload.constants';
import {
  PresignedUploadResponse,
  ToolPhotoUploadResponse,
  UploadPurpose,
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
    this.ensureAllowedFile(dto.contentType, dto.sizeBytes);

    if (dto.purpose === UploadPurpose.TOOL_PHOTO) {
      return this.createToolPhotoUploadUrl(userId, dto);
    }

    return this.createKycDocumentUploadUrl(userId, dto);
  }

  async confirmToolPhotoUpload(
    userId: string,
    dto: ConfirmToolPhotoUploadDto,
  ): Promise<ToolPhotoUploadResponse> {
    await this.ensureOwnedTool(userId, dto.toolId);

    const expectedPrefix = this.getToolOriginalPrefix(dto.toolId);
    if (!dto.key.startsWith(expectedPrefix)) {
      throw new BadRequestException('Ключ фото не относится к объявлению');
    }

    const bucket = this.storage.getPublicBucket();
    const originalUrl = this.storage.getPublicUrl(bucket, dto.key);

    const photo = await this.prisma.$transaction(async (tx) => {
      const photoCount = await tx.toolPhoto.count({
        where: { toolId: dto.toolId },
      });
      const isCover = dto.isCover ?? photoCount === 0;

      if (isCover) {
        await tx.toolPhoto.updateMany({
          where: { toolId: dto.toolId },
          data: { isCover: false },
        });
      }

      return tx.toolPhoto.create({
        data: {
          toolId: dto.toolId,
          originalUrl,
          thumbnailUrl: null,
          previewUrl: null,
          sortOrder: dto.sortOrder ?? photoCount,
          isCover,
        },
        select: {
          id: true,
          toolId: true,
          originalUrl: true,
          thumbnailUrl: true,
          previewUrl: true,
          sortOrder: true,
          isCover: true,
          createdAt: true,
        },
      });
    });

    // Фото обрабатываются асинхронно, чтобы создание объявления не ждало thumbnail/preview.
    await this.photoQueue.addToolPhotoUploaded({
      toolPhotoId: photo.id,
      toolId: photo.toolId,
      originalKey: dto.key,
    });

    return photo;
  }

  private async createToolPhotoUploadUrl(
    userId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    if (!dto.toolId) {
      throw new BadRequestException('Для фото инструмента нужен toolId');
    }

    await this.ensureOwnedTool(userId, dto.toolId);

    const bucket = this.storage.getPublicBucket();
    const key = `${this.getToolOriginalPrefix(dto.toolId)}${randomUUID()}.${this.getExtension(dto.contentType)}`;
    const uploadUrl = await this.storage.createPresignedPutUrl(
      bucket,
      key,
      dto.contentType,
      PRESIGNED_UPLOAD_EXPIRES_SECONDS,
    );

    return {
      uploadUrl,
      method: 'PUT',
      bucket,
      key,
      publicUrl: this.storage.getPublicUrl(bucket, key),
      expiresInSeconds: PRESIGNED_UPLOAD_EXPIRES_SECONDS,
      headers: { contentType: dto.contentType },
    };
  }

  private async createKycDocumentUploadUrl(
    userId: string,
    dto: RequestUploadUrlDto,
  ): Promise<PresignedUploadResponse> {
    const bucket = this.storage.getPrivateBucket();
    const key = `kyc/${userId}/${randomUUID()}.${this.getExtension(dto.contentType)}`;
    const uploadUrl = await this.storage.createPresignedPutUrl(
      bucket,
      key,
      dto.contentType,
      PRESIGNED_UPLOAD_EXPIRES_SECONDS,
    );

    return {
      uploadUrl,
      method: 'PUT',
      bucket,
      key,
      publicUrl: null,
      expiresInSeconds: PRESIGNED_UPLOAD_EXPIRES_SECONDS,
      headers: { contentType: dto.contentType },
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

  private getToolOriginalPrefix(toolId: string): string {
    return `tools/${toolId}/original/`;
  }

  private async ensureOwnedTool(userId: string, toolId: string): Promise<void> {
    const tool = await this.prisma.tool.findUnique({
      where: { id: toolId },
      select: { id: true, ownerId: true },
    });

    if (!tool) {
      throw new NotFoundException('Объявление не найдено');
    }

    if (tool.ownerId !== userId) {
      throw new ForbiddenException(
        'Можно загружать фото только к своему объявлению',
      );
    }
  }
}
