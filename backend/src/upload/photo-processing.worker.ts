import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, type ConnectionOptions } from 'bullmq';
import sharp from 'sharp';
import { PrismaService } from '../prisma/prisma.service';
import {
  PHOTO_PROCESSING_QUEUE_NAME,
  TOOL_PHOTO_UPLOADED_JOB,
} from './photo-processing.queue';
import { S3StorageService } from './s3-storage.service';
import {
  TOOL_PHOTO_PREVIEW_HEIGHT,
  TOOL_PHOTO_PREVIEW_WIDTH,
  TOOL_PHOTO_THUMBNAIL_SIZE,
} from './upload.constants';
import type { PhotoProcessingJob } from './upload.types';

type PhotoProcessingJobPayload = {
  data: PhotoProcessingJob;
};

@Injectable()
export class PhotoProcessingWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PhotoProcessingWorker.name);
  private worker: Worker<
    PhotoProcessingJob,
    void,
    typeof TOOL_PHOTO_UPLOADED_JOB
  > | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly storage: S3StorageService,
  ) {}

  onModuleInit(): void {
    if (this.config.get<string>('NODE_ENV') === 'test') {
      return;
    }

    this.worker = new Worker<
      PhotoProcessingJob,
      void,
      typeof TOOL_PHOTO_UPLOADED_JOB
    >(
      PHOTO_PROCESSING_QUEUE_NAME,
      (job) => this.processToolPhotoUploaded(job),
      {
        connection: this.getConnectionOptions(),
        concurrency: 2,
      },
    );

    this.worker.on('failed', (job, error) => {
      const photoId = job?.data.toolPhotoId ?? 'unknown';
      this.logger.error(`Не удалось обработать фото ${photoId}`, error.stack);
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.worker?.close();
  }

  async processToolPhotoUploaded(
    job: PhotoProcessingJobPayload,
  ): Promise<void> {
    const bucket = this.storage.getPublicBucket();
    const original = await this.storage.getObjectBuffer(
      bucket,
      job.data.originalKey,
    );
    const thumbnailKey = this.getVariantKey(job.data, 'thumbnail');
    const previewKey = this.getVariantKey(job.data, 'preview');

    // Фото приводятся к стабильным размерам для каталога, карты и карточки.
    const [thumbnail, preview] = await Promise.all([
      sharp(original)
        .rotate()
        .resize(TOOL_PHOTO_THUMBNAIL_SIZE, TOOL_PHOTO_THUMBNAIL_SIZE, {
          fit: 'cover',
        })
        .webp({ quality: 80 })
        .toBuffer(),
      sharp(original)
        .rotate()
        .resize(TOOL_PHOTO_PREVIEW_WIDTH, TOOL_PHOTO_PREVIEW_HEIGHT, {
          fit: 'cover',
        })
        .webp({ quality: 82 })
        .toBuffer(),
    ]);

    await Promise.all([
      this.storage.putObject(bucket, thumbnailKey, thumbnail, 'image/webp'),
      this.storage.putObject(bucket, previewKey, preview, 'image/webp'),
    ]);

    await this.prisma.toolPhoto.update({
      where: { id: job.data.toolPhotoId },
      data: {
        thumbnailUrl: this.storage.getPublicUrl(bucket, thumbnailKey),
        previewUrl: this.storage.getPublicUrl(bucket, previewKey),
      },
    });
  }

  private getVariantKey(
    job: PhotoProcessingJob,
    variant: 'thumbnail' | 'preview',
  ): string {
    return `tools/${job.toolId}/${variant}/${job.toolPhotoId}.webp`;
  }

  private getConnectionOptions(): ConnectionOptions {
    const redisUrl = new URL(
      this.config.get<string>('REDIS_URL') ?? 'redis://localhost:6379',
    );

    return {
      host: redisUrl.hostname,
      port: Number(redisUrl.port || 6379),
      username: redisUrl.username || undefined,
      password: redisUrl.password || undefined,
      db: redisUrl.pathname ? Number(redisUrl.pathname.slice(1)) || 0 : 0,
      maxRetriesPerRequest: null,
    };
  }
}
