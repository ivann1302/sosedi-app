import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConfirmToolPhotoUploadDto } from './dto/confirm-tool-photo-upload.dto';
import { RequestUploadUrlDto } from './dto/request-upload-url.dto';
import { PhotoProcessingQueue } from './photo-processing.queue';
import { S3StorageService } from './s3-storage.service';
import { UploadService } from './upload.service';
import { UploadPurpose } from './upload.types';

type TestTool = {
  id: string;
  ownerId: string;
};

type TestPhoto = {
  id: string;
  toolId: string;
  originalUrl: string;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

function createService() {
  const tools = new Map<string, TestTool>([
    ['tool-1', { id: 'tool-1', ownerId: 'user-1' }],
    ['tool-2', { id: 'tool-2', ownerId: 'user-2' }],
  ]);
  const photos: TestPhoto[] = [];
  const now = new Date('2026-06-02T12:00:00.000Z');

  const prisma = {
    tool: {
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(tools.get(where.id) ?? null);
      }),
    },
    $transaction: jest.fn((callback: (tx: unknown) => Promise<unknown>) => {
      return callback({
        toolPhoto: {
          count: jest.fn(({ where }: { where: { toolId: string } }) => {
            return Promise.resolve(
              photos.filter((photo) => photo.toolId === where.toolId).length,
            );
          }),
          updateMany: jest.fn(({ where }: { where: { toolId: string } }) => {
            let count = 0;
            for (const photo of photos) {
              if (photo.toolId === where.toolId) {
                photo.isCover = false;
                count += 1;
              }
            }
            return Promise.resolve({ count });
          }),
          create: jest.fn(
            ({ data }: { data: Omit<TestPhoto, 'id' | 'createdAt'> }) => {
              const photo = {
                id: `photo-${photos.length + 1}`,
                ...data,
                createdAt: now,
              };
              photos.push(photo);
              return Promise.resolve(photo);
            },
          ),
        },
      });
    }),
  };

  const storage = {
    getPublicBucket: jest.fn(() => 'public-bucket'),
    getPrivateBucket: jest.fn(() => 'private-bucket'),
    getPublicUrl: jest.fn((bucket: string, key: string) => {
      return `https://cdn.test/${bucket}/${key}`;
    }),
    createPresignedPutUrl: jest.fn(
      (bucket: string, key: string, contentType: string) => {
        return Promise.resolve(
          `https://upload.test/${bucket}/${key}?contentType=${contentType}`,
        );
      },
    ),
  };

  const photoQueue = {
    addToolPhotoUploaded: jest.fn(() => Promise.resolve(undefined)),
  };

  return {
    service: new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      photoQueue as unknown as PhotoProcessingQueue,
    ),
    photos,
    photoQueue,
    storage,
  };
}

describe('UploadService', () => {
  it('creates a presigned URL for an owned tool photo', async () => {
    const { service, storage } = createService();
    const dto: RequestUploadUrlDto = {
      purpose: UploadPurpose.TOOL_PHOTO,
      toolId: 'tool-1',
      fileName: 'drill.png',
      contentType: 'image/png',
      sizeBytes: 1024,
    };

    const result = await service.requestUploadUrl('user-1', dto);

    expect(result.bucket).toBe('public-bucket');
    expect(result.key).toMatch(/^tools\/tool-1\/original\/.+\.png$/);
    expect(result.publicUrl).toContain(
      'https://cdn.test/public-bucket/tools/tool-1/original/',
    );
    expect(storage.createPresignedPutUrl).toHaveBeenCalledWith(
      'public-bucket',
      result.key,
      'image/png',
      900,
    );
  });

  it('rejects unsupported file content types', async () => {
    const { service } = createService();
    const dto: RequestUploadUrlDto = {
      purpose: UploadPurpose.TOOL_PHOTO,
      toolId: 'tool-1',
      fileName: 'drill.gif',
      contentType: 'image/gif',
      sizeBytes: 1024,
    };

    await expect(
      service.requestUploadUrl('user-1', dto),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('uses the private bucket for KYC documents', async () => {
    const { service } = createService();
    const dto: RequestUploadUrlDto = {
      purpose: UploadPurpose.KYC_DOCUMENT,
      fileName: 'passport.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 2048,
    };

    const result = await service.requestUploadUrl('user-1', dto);

    expect(result.bucket).toBe('private-bucket');
    expect(result.key).toMatch(/^kyc\/user-1\/.+\.jpg$/);
    expect(result.publicUrl).toBeNull();
  });

  it('confirms an uploaded tool photo and queues processing', async () => {
    const { service, photos, photoQueue } = createService();
    const dto: ConfirmToolPhotoUploadDto = {
      toolId: 'tool-1',
      key: 'tools/tool-1/original/photo-1.jpg',
    };

    const result = await service.confirmToolPhotoUpload('user-1', dto);

    expect(result.id).toBe('photo-1');
    expect(result.isCover).toBe(true);
    expect(result.sortOrder).toBe(0);
    expect(photos).toHaveLength(1);
    expect(photoQueue.addToolPhotoUploaded).toHaveBeenCalledWith({
      toolPhotoId: 'photo-1',
      toolId: 'tool-1',
      originalKey: dto.key,
    });
  });

  it('rejects photos for another owner tool', async () => {
    const { service } = createService();

    await expect(
      service.confirmToolPhotoUpload('user-1', {
        toolId: 'tool-2',
        key: 'tools/tool-2/original/photo-1.jpg',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects unknown tools', async () => {
    const { service } = createService();

    await expect(
      service.requestUploadUrl('user-1', {
        purpose: UploadPurpose.TOOL_PHOTO,
        toolId: 'missing-tool',
        fileName: 'drill.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
