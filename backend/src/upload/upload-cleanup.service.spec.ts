import { Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { S3StorageService } from './s3-storage.service';
import { UploadCleanupService } from './upload-cleanup.service';
import { UploadPurpose } from './upload.types';

describe('UploadCleanupService', () => {
  const now = new Date('2026-07-28T12:00:00.000Z');

  it('deletes expired, rejected and orphan quarantine data only', async () => {
    const intents = [
      {
        id: 'expired',
        purpose: UploadPurpose.ITEM_PHOTO,
        objectKey: 'quarantine/expired.jpg',
        expiresAt: new Date('2026-07-27T11:00:00.000Z'),
        confirmedAt: null,
      },
      {
        id: 'active',
        purpose: UploadPurpose.ITEM_PHOTO,
        objectKey: 'quarantine/active.jpg',
        expiresAt: new Date('2026-07-28T13:00:00.000Z'),
        confirmedAt: null,
      },
      {
        id: 'processed',
        purpose: UploadPurpose.ITEM_PHOTO,
        objectKey: 'quarantine/processed.jpg',
        expiresAt: new Date('2026-07-26T12:00:00.000Z'),
        confirmedAt: new Date('2026-07-26T12:00:00.000Z'),
      },
      {
        id: 'rejected',
        purpose: UploadPurpose.ITEM_PHOTO,
        objectKey: 'quarantine/rejected.jpg',
        expiresAt: new Date('2026-07-20T11:00:00.000Z'),
        confirmedAt: new Date('2026-07-20T12:00:00.000Z'),
      },
      {
        id: 'pending',
        purpose: UploadPurpose.ITEM_PHOTO,
        objectKey: 'quarantine/pending.jpg',
        expiresAt: new Date('2026-07-27T11:00:00.000Z'),
        confirmedAt: new Date('2026-07-27T11:00:00.000Z'),
      },
    ];
    const prisma = {
      uploadIntent: {
        findMany: jest.fn().mockResolvedValue(intents),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      itemPhoto: {
        findUnique: jest.fn(
          ({ where }: { where: { uploadIntentId: string } }) =>
            Promise.resolve(
              where.uploadIntentId === 'processed'
                ? { originalUrl: 'https://cdn.test/photo.webp' }
                : { originalUrl: null },
            ),
        ),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      listObjects: jest.fn().mockResolvedValue([
        {
          key: 'quarantine/orphan-old.jpg',
          lastModified: new Date('2026-07-27T10:00:00.000Z'),
        },
        {
          key: 'quarantine/orphan-fresh.jpg',
          lastModified: new Date('2026-07-28T11:00:00.000Z'),
        },
      ]),
      deleteObject: jest.fn().mockResolvedValue(undefined),
    };
    const service = new UploadCleanupService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
    );

    await expect(service.cleanupExpiredUploads(now)).resolves.toBe(4);

    expect(storage.deleteObject.mock.calls).toEqual([
      ['private-bucket', 'quarantine/expired.jpg'],
      ['private-bucket', 'quarantine/processed.jpg'],
      ['private-bucket', 'quarantine/rejected.jpg'],
      ['private-bucket', 'quarantine/orphan-old.jpg'],
    ]);
    expect(prisma.itemPhoto.deleteMany).toHaveBeenCalledTimes(1);
    expect(prisma.itemPhoto.deleteMany).toHaveBeenCalledWith({
      where: { uploadIntentId: 'rejected', originalUrl: null },
    });
    expect(prisma.uploadIntent.deleteMany).toHaveBeenCalledTimes(3);
  });

  it('keeps the database linkage when S3 deletion fails', async () => {
    const logError = jest
      .spyOn(Logger.prototype, 'error')
      .mockImplementation(() => undefined);
    const prisma = {
      uploadIntent: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'expired',
            purpose: UploadPurpose.ITEM_PHOTO,
            objectKey: 'quarantine/expired.jpg',
            expiresAt: new Date('2026-07-27T11:00:00.000Z'),
            confirmedAt: null,
          },
        ]),
        deleteMany: jest.fn(),
      },
      itemPhoto: {
        findUnique: jest.fn(),
        deleteMany: jest.fn(),
      },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      listObjects: jest.fn().mockResolvedValue([]),
      deleteObject: jest.fn().mockRejectedValue(new Error('S3 unavailable')),
    };
    const service = new UploadCleanupService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
    );

    await expect(service.cleanupExpiredUploads(now)).resolves.toBe(0);
    expect(prisma.itemPhoto.deleteMany).not.toHaveBeenCalled();
    expect(prisma.uploadIntent.deleteMany).not.toHaveBeenCalled();
    logError.mockRestore();
  });

  it('deletes only expired unconfirmed dispute evidence intents', async () => {
    const intents = [
      {
        id: 'expired-dispute',
        purpose: UploadPurpose.DISPUTE_EVIDENCE,
        objectKey: 'quarantine/expired-dispute.jpg',
        expiresAt: new Date('2026-07-27T11:00:00.000Z'),
        confirmedAt: null,
      },
      {
        id: 'confirmed-dispute',
        purpose: UploadPurpose.DISPUTE_EVIDENCE,
        objectKey: 'quarantine/confirmed-dispute.jpg',
        expiresAt: new Date('2026-07-27T11:00:00.000Z'),
        confirmedAt: new Date('2026-07-27T11:30:00.000Z'),
      },
      {
        id: 'active-dispute',
        purpose: UploadPurpose.DISPUTE_EVIDENCE,
        objectKey: 'quarantine/active-dispute.jpg',
        expiresAt: new Date('2026-07-28T13:00:00.000Z'),
        confirmedAt: null,
      },
    ];
    const prisma = {
      uploadIntent: {
        findMany: jest.fn(
          ({ where }: { where: { purpose: { in: UploadPurpose[] } } }) =>
            Promise.resolve(
              intents.filter((intent) =>
                where.purpose.in.includes(intent.purpose),
              ),
            ),
        ),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      itemPhoto: {
        findUnique: jest.fn().mockResolvedValue(null),
        deleteMany: jest.fn(),
      },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      listObjects: jest.fn().mockResolvedValue([
        {
          key: 'quarantine/confirmed-dispute.jpg',
          lastModified: new Date('2026-07-27T11:00:00.000Z'),
        },
      ]),
      deleteObject: jest.fn().mockResolvedValue(undefined),
    };
    const service = new UploadCleanupService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
    );

    await expect(service.cleanupExpiredUploads(now)).resolves.toBe(1);
    expect(storage.deleteObject).toHaveBeenCalledTimes(1);
    expect(storage.deleteObject).toHaveBeenCalledWith(
      'private-bucket',
      'quarantine/expired-dispute.jpg',
    );
    expect(prisma.uploadIntent.deleteMany).toHaveBeenCalledWith({
      where: { id: 'expired-dispute' },
    });
    expect(prisma.itemPhoto.findUnique).not.toHaveBeenCalled();
  });
});
