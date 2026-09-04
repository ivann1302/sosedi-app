import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { S3StorageService } from './s3-storage.service';
import {
  REJECTED_UPLOAD_RETENTION_MS,
  UPLOAD_CLEANUP_INTERVAL_MS,
  UPLOAD_INTENT_CLEANUP_GRACE_MS,
} from './upload.constants';
import { UploadPurpose } from './upload.types';

const QUARANTINE_PREFIX = 'quarantine/';

@Injectable()
export class UploadCleanupService
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(UploadCleanupService.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: S3StorageService,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (process.env.NODE_ENV === 'test') {
      return;
    }

    await this.runCleanup();
    this.timer = setInterval(
      () => void this.runCleanup(),
      UPLOAD_CLEANUP_INTERVAL_MS,
    );
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  async cleanupExpiredUploads(now = new Date()): Promise<number> {
    const bucket = this.storage.getPrivateBucket();
    const listedObjects = await this.storage.listObjects(
      bucket,
      QUARANTINE_PREFIX,
    );
    const intents = await this.prisma.uploadIntent.findMany({
      where: {
        purpose: {
          in: [
            UploadPurpose.ITEM_PHOTO,
            UploadPurpose.AVATAR,
            UploadPurpose.DISPUTE_EVIDENCE,
          ],
        },
      },
      select: {
        id: true,
        purpose: true,
        objectKey: true,
        expiresAt: true,
        confirmedAt: true,
      },
    });
    const knownKeys = new Set(intents.map((intent) => intent.objectKey));
    const intentCutoff = new Date(
      now.getTime() - UPLOAD_INTENT_CLEANUP_GRACE_MS,
    );
    const rejectedCutoff = new Date(
      now.getTime() - REJECTED_UPLOAD_RETENTION_MS,
    );
    let deleted = 0;

    for (const intent of intents) {
      const isDisputeEvidence =
        intent.purpose === UploadPurpose.DISPUTE_EVIDENCE.toString();
      const photo =
        intent.confirmedAt &&
        intent.purpose === UploadPurpose.ITEM_PHOTO.toString()
          ? await this.prisma.itemPhoto.findUnique({
              where: { uploadIntentId: intent.id },
              select: { originalUrl: true },
            })
          : null;
      const isRejected =
        intent.purpose === UploadPurpose.ITEM_PHOTO.toString() &&
        intent.confirmedAt !== null &&
        !photo?.originalUrl &&
        intent.confirmedAt <= rejectedCutoff;
      const isExpired =
        intent.expiresAt <= intentCutoff &&
        (isDisputeEvidence
          ? intent.confirmedAt === null
          : intent.confirmedAt === null ||
            photo === null ||
            Boolean(photo?.originalUrl));

      if (!isRejected && !isExpired) {
        continue;
      }

      try {
        await this.storage.deleteObject(bucket, intent.objectKey);
        if (isRejected) {
          await this.prisma.itemPhoto.deleteMany({
            where: { uploadIntentId: intent.id, originalUrl: null },
          });
        }
        await this.prisma.uploadIntent.deleteMany({
          where: { id: intent.id },
        });
        deleted += 1;
      } catch (error) {
        this.logger.error(
          `Не удалось очистить upload intent ${intent.id}`,
          error,
        );
      }
    }

    for (const object of listedObjects) {
      if (
        knownKeys.has(object.key) ||
        !object.lastModified ||
        object.lastModified > intentCutoff
      ) {
        continue;
      }

      try {
        await this.storage.deleteObject(bucket, object.key);
        deleted += 1;
      } catch (error) {
        this.logger.error(
          `Не удалось очистить orphan object ${object.key}`,
          error,
        );
      }
    }

    return deleted;
  }

  private async runCleanup(): Promise<void> {
    try {
      await this.cleanupExpiredUploads();
    } catch (error) {
      this.logger.error('Не удалось выполнить upload cleanup', error);
    }
  }
}
