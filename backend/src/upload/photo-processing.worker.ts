import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, type ConnectionOptions } from 'bullmq';
import sharp from 'sharp';
import { MetricsService } from '../observability/metrics.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  PHOTO_PROCESSING_QUEUE_NAME,
  ITEM_PHOTO_UPLOADED_JOB,
} from './photo-processing.queue';
import { S3StorageService } from './s3-storage.service';
import {
  ITEM_PHOTO_PREVIEW_HEIGHT,
  ITEM_PHOTO_PREVIEW_WIDTH,
  ITEM_PHOTO_THUMBNAIL_SIZE,
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
    typeof ITEM_PHOTO_UPLOADED_JOB
  > | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly storage: S3StorageService,
    private readonly metrics: MetricsService,
  ) {}

  onModuleInit(): void {
    if (this.config.get<string>('NODE_ENV') === 'test') {
      return;
    }

    this.worker = new Worker<
      PhotoProcessingJob,
      void,
      typeof ITEM_PHOTO_UPLOADED_JOB
    >(
      PHOTO_PROCESSING_QUEUE_NAME,
      (job) => this.processItemPhotoUploaded(job),
      {
        connection: this.getConnectionOptions(),
        concurrency: 2,
      },
    );

    this.worker.on('failed', (job, error) => {
      const photoId = job?.data.itemPhotoId ?? 'unknown';
      this.logger.error({
        message: 'Не удалось обработать фото',
        photoId,
        error,
      });
      this.metrics.recordOperation('upload_processing', 'failure');
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.worker?.close();
  }

  async processItemPhotoUploaded(
    job: PhotoProcessingJobPayload,
  ): Promise<void> {
    const activePhoto = await this.prisma.itemPhoto.findFirst({
      where: {
        id: job.data.itemPhotoId,
        itemId: job.data.itemId,
        item: {
          owner: {
            isBlocked: false,
            deletedAt: null,
          },
        },
      },
      select: { id: true },
    });
    if (!activePhoto) {
      this.logger.warn(
        `Пропущена обработка фото ${job.data.itemPhotoId}: владелец недоступен`,
      );
      return;
    }

    const source = await this.storage.getObjectBuffer(
      job.data.sourceBucket,
      job.data.sourceKey,
    );
    const bucket = this.storage.getPublicBucket();
    const originalKey = this.getVariantKey(job.data, 'original');
    const thumbnailKey = this.getVariantKey(job.data, 'thumbnail');
    const previewKey = this.getVariantKey(job.data, 'preview');

    // По умолчанию Sharp удаляет EXIF/GPS и прочие метаданные при re-encode.
    const decoded = sharp(source, { failOn: 'warning' }).rotate();
    const [original, thumbnail, preview] = await Promise.all([
      decoded.clone().webp({ quality: 90 }).toBuffer(),
      decoded
        .clone()
        .resize(ITEM_PHOTO_THUMBNAIL_SIZE, ITEM_PHOTO_THUMBNAIL_SIZE, {
          fit: 'cover',
        })
        .webp({ quality: 80 })
        .toBuffer(),
      decoded
        .clone()
        .resize(ITEM_PHOTO_PREVIEW_WIDTH, ITEM_PHOTO_PREVIEW_HEIGHT, {
          fit: 'cover',
        })
        .webp({ quality: 82 })
        .toBuffer(),
    ]);

    await Promise.all([
      this.storage.putObject(bucket, originalKey, original, 'image/webp'),
      this.storage.putObject(bucket, thumbnailKey, thumbnail, 'image/webp'),
      this.storage.putObject(bucket, previewKey, preview, 'image/webp'),
    ]);

    await this.prisma.itemPhoto.update({
      where: { id: job.data.itemPhotoId },
      data: {
        originalUrl: this.storage.getPublicUrl(bucket, originalKey),
        thumbnailUrl: this.storage.getPublicUrl(bucket, thumbnailKey),
        previewUrl: this.storage.getPublicUrl(bucket, previewKey),
      },
    });

    await this.storage.deleteObject(job.data.sourceBucket, job.data.sourceKey);
    this.metrics.recordOperation('upload_processing', 'success');
  }

  private getVariantKey(
    job: PhotoProcessingJob,
    variant: 'original' | 'thumbnail' | 'preview',
  ): string {
    return `items/${job.itemId}/${variant}/${job.itemPhotoId}.webp`;
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
