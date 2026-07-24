import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { PhotoProcessingQueue } from './photo-processing.queue';
import { PhotoProcessingWorker } from './photo-processing.worker';
import { S3StorageService } from './s3-storage.service';
import { UploadController } from './upload.controller';
import { UploadService } from './upload.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [UploadController],
  providers: [
    UploadService,
    S3StorageService,
    PhotoProcessingQueue,
    PhotoProcessingWorker,
  ],
  exports: [UploadService],
})
export class UploadModule {}
