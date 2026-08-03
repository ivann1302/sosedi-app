import { ConfigService } from '@nestjs/config';
import sharp from 'sharp';
import { PrismaService } from '../prisma/prisma.service';
import { PhotoProcessingWorker } from './photo-processing.worker';
import { S3StorageService } from './s3-storage.service';

describe('PhotoProcessingWorker', () => {
  it('skips a job when the photo owner is blocked or deleted', async () => {
    const prisma = {
      itemPhoto: {
        findFirst: jest.fn().mockResolvedValue(null),
        update: jest.fn().mockResolvedValue(undefined),
      },
    };
    const onePixelPng = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      'base64',
    );
    const storage = {
      getPublicBucket: jest.fn().mockReturnValue('public-bucket'),
      getObjectBuffer: jest.fn().mockResolvedValue(onePixelPng),
      putObject: jest.fn().mockResolvedValue(undefined),
      deleteObject: jest.fn().mockResolvedValue(undefined),
      getPublicUrl: jest.fn().mockReturnValue('https://cdn.test/photo.webp'),
    };
    const config = {
      get: jest.fn().mockReturnValue('test'),
    };
    const worker = new PhotoProcessingWorker(
      config as unknown as ConfigService,
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      { recordOperation: jest.fn() } as never,
    );

    await worker.processItemPhotoUploaded({
      data: {
        itemPhotoId: 'photo-1',
        itemId: 'item-1',
        sourceBucket: 'private-bucket',
        sourceKey: 'quarantine/item-photos/item-1/photo-1.png',
      },
    });

    expect(prisma.itemPhoto.findFirst).toHaveBeenCalledWith({
      where: {
        id: 'photo-1',
        itemId: 'item-1',
        item: {
          owner: {
            isBlocked: false,
            deletedAt: null,
          },
        },
      },
      select: { id: true },
    });
    expect(storage.getObjectBuffer).not.toHaveBeenCalled();
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(prisma.itemPhoto.update).not.toHaveBeenCalled();
  });

  it('re-encodes a valid image without EXIF/GPS before publishing it', async () => {
    const source = await sharp({
      create: {
        width: 20,
        height: 10,
        channels: 3,
        background: '#336699',
      },
    })
      .jpeg()
      .withExif({
        IFD0: { Copyright: 'private-owner' },
        IFD3: {
          GPSLatitudeRef: 'N',
          GPSLatitude: '55/1 45/1 0/1',
          GPSLongitudeRef: 'E',
          GPSLongitude: '37/1 37/1 0/1',
        },
      })
      .toBuffer();
    const prisma = {
      itemPhoto: {
        findFirst: jest.fn().mockResolvedValue({ id: 'photo-1' }),
        update: jest.fn().mockResolvedValue(undefined),
      },
    };
    const stored = new Map<string, Buffer>();
    const storage = {
      getPublicBucket: jest.fn().mockReturnValue('public-bucket'),
      getObjectBuffer: jest.fn().mockResolvedValue(source),
      putObject: jest.fn((_bucket: string, key: string, body: Buffer) => {
        stored.set(key, body);
        return Promise.resolve();
      }),
      deleteObject: jest.fn().mockResolvedValue(undefined),
      getPublicUrl: jest.fn(
        (bucket: string, key: string) => `https://cdn.test/${bucket}/${key}`,
      ),
    };
    const worker = new PhotoProcessingWorker(
      { get: jest.fn().mockReturnValue('test') } as unknown as ConfigService,
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      { recordOperation: jest.fn() } as never,
    );

    await worker.processItemPhotoUploaded({
      data: {
        itemPhotoId: 'photo-1',
        itemId: 'item-1',
        sourceBucket: 'private-bucket',
        sourceKey: 'quarantine/item-photos/item-1/upload.jpg',
      },
    });

    const sanitized = stored.get('items/item-1/original/photo-1.webp');
    expect(sanitized).toBeDefined();
    const metadata = await sharp(sanitized).metadata();
    expect(metadata.format).toBe('webp');
    expect(metadata.exif).toBeUndefined();
    expect(storage.putObject).toHaveBeenCalledTimes(3);
    expect(prisma.itemPhoto.update).toHaveBeenCalledWith({
      where: { id: 'photo-1' },
      data: {
        originalUrl:
          'https://cdn.test/public-bucket/items/item-1/original/photo-1.webp',
        thumbnailUrl:
          'https://cdn.test/public-bucket/items/item-1/thumbnail/photo-1.webp',
        previewUrl:
          'https://cdn.test/public-bucket/items/item-1/preview/photo-1.webp',
      },
    });
    expect(storage.deleteObject).toHaveBeenCalledWith(
      'private-bucket',
      'quarantine/item-photos/item-1/upload.jpg',
    );
  });

  it('does not publish or delete an image that cannot be decoded', async () => {
    const prisma = {
      itemPhoto: {
        findFirst: jest.fn().mockResolvedValue({ id: 'photo-1' }),
        update: jest.fn().mockResolvedValue(undefined),
      },
    };
    const storage = {
      getPublicBucket: jest.fn().mockReturnValue('public-bucket'),
      getObjectBuffer: jest.fn().mockResolvedValue(Buffer.from('broken')),
      putObject: jest.fn().mockResolvedValue(undefined),
      deleteObject: jest.fn().mockResolvedValue(undefined),
      getPublicUrl: jest.fn(),
    };
    const worker = new PhotoProcessingWorker(
      { get: jest.fn().mockReturnValue('test') } as unknown as ConfigService,
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      { recordOperation: jest.fn() } as never,
    );

    await expect(
      worker.processItemPhotoUploaded({
        data: {
          itemPhotoId: 'photo-1',
          itemId: 'item-1',
          sourceBucket: 'private-bucket',
          sourceKey: 'quarantine/item-photos/item-1/broken.jpg',
        },
      }),
    ).rejects.toThrow();

    expect(storage.putObject).not.toHaveBeenCalled();
    expect(prisma.itemPhoto.update).not.toHaveBeenCalled();
    expect(storage.deleteObject).not.toHaveBeenCalled();
  });
});
