import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Queue, type ConnectionOptions } from 'bullmq';
import type { PhotoProcessingJob } from './upload.types';

const PHOTO_PROCESSING_QUEUE_NAME = 'photo-processing';
const TOOL_PHOTO_UPLOADED_JOB = 'tool-photo-uploaded';

export { PHOTO_PROCESSING_QUEUE_NAME, TOOL_PHOTO_UPLOADED_JOB };

@Injectable()
export class PhotoProcessingQueue implements OnModuleDestroy {
  private readonly queue: Queue<
    PhotoProcessingJob,
    void,
    typeof TOOL_PHOTO_UPLOADED_JOB
  >;

  constructor(config: ConfigService) {
    this.queue = new Queue<
      PhotoProcessingJob,
      void,
      typeof TOOL_PHOTO_UPLOADED_JOB
    >(PHOTO_PROCESSING_QUEUE_NAME, {
      connection: this.getConnectionOptions(config),
    });
  }

  async addToolPhotoUploaded(job: PhotoProcessingJob): Promise<void> {
    await this.queue.add(TOOL_PHOTO_UPLOADED_JOB, job, {
      attempts: 3,
      removeOnComplete: true,
      removeOnFail: 100,
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.queue.close();
  }

  private getConnectionOptions(config: ConfigService): ConnectionOptions {
    const redisUrl = new URL(
      config.get<string>('REDIS_URL') ?? 'redis://localhost:6379',
    );

    return {
      host: redisUrl.hostname,
      port: Number(redisUrl.port || 6379),
      username: redisUrl.username || undefined,
      password: redisUrl.password || undefined,
      db: redisUrl.pathname ? Number(redisUrl.pathname.slice(1)) || 0 : 0,
      maxRetriesPerRequest: 1,
    };
  }
}
