import { ConfigService } from '@nestjs/config';
import sharp from 'sharp';
import { PrismaService } from '../prisma/prisma.service';
import { PhotoProcessingWorker } from './photo-processing.worker';
import { S3StorageService } from './s3-storage.service';

describe('PhotoProcessingWorker', () => {
  it('generates thumbnail and preview and stores their URLs', async () => {
    const original = await sharp({
      create: {
        width: 1000,
        height: 800,
        channels: 3,
        background: '#ffffff',
      },
    })
      .jpeg()
      .toBuffer();

    const uploadedObjects: Array<{
      key: string;
      body: Buffer;
      contentType: string;
    }> = [];

    const storage = {
      getPublicBucket: jest.fn(() => 'public-bucket'),
      getObjectBuffer: jest.fn(() => Promise.resolve(original)),
      putObject: jest.fn(
        (bucket: string, key: string, body: Buffer, contentType: string) => {
          uploadedObjects.push({ key, body, contentType });
          return Promise.resolve();
        },
      ),
      getPublicUrl: jest.fn((bucket: string, key: string) => {
        return `https://cdn.test/${bucket}/${key}`;
      }),
    };

    const prisma = {
      toolPhoto: {
        update: jest.fn(() => Promise.resolve({ id: 'photo-1' })),
      },
    };

    const worker = new PhotoProcessingWorker(
      { get: jest.fn() } as unknown as ConfigService,
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
    );

    await worker.processToolPhotoUploaded({
      data: {
        toolPhotoId: 'photo-1',
        toolId: 'tool-1',
        originalKey: 'tools/tool-1/original/photo-1.jpg',
      },
    });

    expect(storage.getObjectBuffer).toHaveBeenCalledWith(
      'public-bucket',
      'tools/tool-1/original/photo-1.jpg',
    );
    expect(uploadedObjects).toHaveLength(2);
    expect(uploadedObjects.map((object) => object.key)).toEqual([
      'tools/tool-1/thumbnail/photo-1.webp',
      'tools/tool-1/preview/photo-1.webp',
    ]);
    expect(
      uploadedObjects.every((object) => object.contentType === 'image/webp'),
    ).toBe(true);

    await expect(
      sharp(uploadedObjects[0].body).metadata(),
    ).resolves.toMatchObject({
      width: 200,
      height: 200,
      format: 'webp',
    });
    await expect(
      sharp(uploadedObjects[1].body).metadata(),
    ).resolves.toMatchObject({
      width: 800,
      height: 600,
      format: 'webp',
    });
    expect(prisma.toolPhoto.update).toHaveBeenCalledWith({
      where: { id: 'photo-1' },
      data: {
        thumbnailUrl:
          'https://cdn.test/public-bucket/tools/tool-1/thumbnail/photo-1.webp',
        previewUrl:
          'https://cdn.test/public-bucket/tools/tool-1/preview/photo-1.webp',
      },
    });
  });
});
