import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { AdminCapability, ItemStatus } from '@prisma/client';
import { createHash } from 'crypto';
import sharp from 'sharp';
import { PrismaService } from '../prisma/prisma.service';
import { ConfirmItemPhotoUploadDto } from './dto/confirm-item-photo-upload.dto';
import { RequestUploadUrlDto } from './dto/request-upload-url.dto';
import { PhotoProcessingQueue } from './photo-processing.queue';
import { S3StorageService } from './s3-storage.service';
import { UploadService } from './upload.service';
import { UploadPurpose } from './upload.types';

type TestItem = {
  id: string;
  ownerId: string;
  status: ItemStatus;
  rejectReason: string | null;
};

type TestPhoto = {
  id: string;
  itemId: string;
  uploadIntentId: string | null;
  originalUrl: string | null;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

type TestUploadIntent = {
  id: string;
  actorId: string;
  purpose: string;
  entityId: string;
  bucket: string;
  objectKey: string;
  contentType: string;
  sizeBytes: number;
  expiresAt: Date;
  confirmedAt: Date | null;
};

function createService() {
  const items = new Map<string, TestItem>([
    [
      'item-1',
      {
        id: 'item-1',
        ownerId: 'user-1',
        status: ItemStatus.APPROVED,
        rejectReason: null,
      },
    ],
    [
      'item-2',
      {
        id: 'item-2',
        ownerId: 'user-2',
        status: ItemStatus.APPROVED,
        rejectReason: null,
      },
    ],
  ]);
  const unfinishedBookings = new Set<string>();
  const photos: TestPhoto[] = [];
  const uploadIntents: TestUploadIntent[] = [];
  const users = new Map([
    ['user-1', { id: 'user-1', avatarUrl: null as string | null }],
  ]);
  const now = new Date('2026-06-02T12:00:00.000Z');

  const prisma = {
    item: {
      findFirst: jest.fn(
        ({ where }: { where: { id: string; ownerId: string } }) => {
          const item = items.get(where.id);
          return Promise.resolve(
            item?.ownerId === where.ownerId ? { id: item.id } : null,
          );
        },
      ),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: { status: ItemStatus; rejectReason: null };
        }) => {
          const item = items.get(where.id);
          if (!item) {
            throw new Error('Item not found');
          }
          Object.assign(item, data);
          return Promise.resolve(item);
        },
      ),
    },
    booking: {
      findFirst: jest.fn(({ where }: { where: { itemId: string } }) => {
        return Promise.resolve(
          unfinishedBookings.has(where.itemId) ? { id: 'booking-1' } : null,
        );
      }),
    },
    uploadIntent: {
      create: jest.fn(
        ({ data }: { data: Omit<TestUploadIntent, 'id' | 'confirmedAt'> }) => {
          const intent = {
            id: `intent-${uploadIntents.length + 1}`,
            ...data,
            confirmedAt: null,
          };
          uploadIntents.push(intent);
          return Promise.resolve({ id: intent.id });
        },
      ),
      findFirst: jest.fn(
        ({
          where,
        }: {
          where: { id: string; actorId: string; purpose: string };
        }) => {
          return Promise.resolve(
            uploadIntents.find(
              (intent) =>
                intent.id === where.id &&
                intent.actorId === where.actorId &&
                intent.purpose === where.purpose,
            ) ?? null,
          );
        },
      ),
    },
    itemPhoto: {
      findUnique: jest.fn(
        ({ where }: { where: { uploadIntentId: string } }) => {
          return Promise.resolve(
            photos.find(
              (photo) => photo.uploadIntentId === where.uploadIntentId,
            ) ?? null,
          );
        },
      ),
    },
    $transaction: jest.fn((callback: (tx: unknown) => Promise<unknown>) => {
      return callback({
        uploadIntent: {
          findFirst: jest.fn(
            ({
              where,
            }: {
              where: { id: string; actorId: string; purpose: string };
            }) => {
              return Promise.resolve(
                uploadIntents.find(
                  (intent) =>
                    intent.id === where.id &&
                    intent.actorId === where.actorId &&
                    intent.purpose === where.purpose,
                ) ?? null,
              );
            },
          ),
          updateMany: jest.fn(
            ({
              where,
              data,
            }: {
              where: {
                id: string;
                actorId: string;
                confirmedAt: null;
                expiresAt: { gt: Date };
              };
              data: { confirmedAt: Date };
            }) => {
              const intent = uploadIntents.find(
                (candidate) =>
                  candidate.id === where.id &&
                  candidate.actorId === where.actorId &&
                  candidate.confirmedAt === null &&
                  candidate.expiresAt > where.expiresAt.gt,
              );
              if (!intent) {
                return Promise.resolve({ count: 0 });
              }

              intent.confirmedAt = data.confirmedAt;
              return Promise.resolve({ count: 1 });
            },
          ),
        },
        itemPhoto: {
          findUnique: jest.fn(
            ({ where }: { where: { uploadIntentId: string } }) => {
              return Promise.resolve(
                photos.find(
                  (photo) => photo.uploadIntentId === where.uploadIntentId,
                ) ?? null,
              );
            },
          ),
          count: jest.fn(({ where }: { where: { itemId: string } }) => {
            return Promise.resolve(
              photos.filter((photo) => photo.itemId === where.itemId).length,
            );
          }),
          updateMany: jest.fn(({ where }: { where: { itemId: string } }) => {
            let count = 0;
            for (const photo of photos) {
              if (photo.itemId === where.itemId) {
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
        item: {
          update: jest.fn(
            ({
              where,
              data,
            }: {
              where: { id: string };
              data: { status: ItemStatus; rejectReason: null };
            }) => {
              const item = items.get(where.id);
              if (!item) {
                throw new Error('Item not found');
              }
              Object.assign(item, data);
              return Promise.resolve(item);
            },
          ),
        },
        user: {
          update: jest.fn(
            ({
              where,
              data,
            }: {
              where: { id: string };
              data: { avatarUrl: string };
            }) => {
              const user = users.get(where.id);
              if (!user) {
                throw new Error('User not found');
              }
              user.avatarUrl = data.avatarUrl;
              return Promise.resolve(user);
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
    createPresignedPostUpload: jest.fn(
      (bucket: string, key: string, contentType: string) => {
        return Promise.resolve({
          uploadUrl: `https://upload.test/${bucket}/${key}`,
          fields: {
            key,
            'Content-Type': contentType,
            Policy: 'signed-policy',
          },
        });
      },
    ),
    createPresignedDownloadUrl: jest.fn((bucket: string, key: string) =>
      Promise.resolve(`https://download.test/${bucket}/${key}?signed=true`),
    ),
    inspectUploadedObject: jest.fn(() =>
      Promise.resolve({
        sizeBytes: 1024,
        contentType: 'image/jpeg',
        prefix: Buffer.from([0xff, 0xd8, 0xff]),
      }),
    ),
    getObjectBuffer: jest.fn(),
    putObject: jest.fn(() => Promise.resolve(undefined)),
    deleteObject: jest.fn(() => Promise.resolve(undefined)),
  };

  const photoQueue = {
    addItemPhotoUploaded: jest.fn(() => Promise.resolve(undefined)),
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
    uploadIntents,
    users,
    items,
    unfinishedBookings,
  };
}

describe('UploadService', () => {
  it('creates a presigned URL for an owned item photo', async () => {
    const { service, storage, uploadIntents } = createService();
    const dto: RequestUploadUrlDto = {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'drill.png',
      contentType: 'image/png',
      sizeBytes: 1024,
    };

    const result = await service.requestUploadUrl('user-1', dto);

    expect(result.bucket).toBe('private-bucket');
    expect(result.intentId).toBe('intent-1');
    expect(result.key).toMatch(/^quarantine\/item-photos\/item-1\/.+\.png$/);
    expect(result).toMatchObject({
      method: 'POST',
      expiresInSeconds: 900,
      fields: {
        key: result.key,
        'Content-Type': 'image/png',
        Policy: 'signed-policy',
      },
      constraints: {
        contentType: 'image/png',
        sizeBytes: 1024,
      },
    });
    expect(result.publicUrl).toBeNull();
    expect(storage.createPresignedPostUpload).toHaveBeenCalledWith(
      'private-bucket',
      result.key,
      'image/png',
      1024,
      900,
    );
    expect(uploadIntents[0]).toMatchObject({
      actorId: 'user-1',
      purpose: UploadPurpose.ITEM_PHOTO,
      entityId: 'item-1',
      bucket: 'private-bucket',
      objectKey: result.key,
      contentType: 'image/png',
      sizeBytes: 1024,
      confirmedAt: null,
    });
    expect(uploadIntents[0].expiresAt.getTime()).toBeGreaterThan(Date.now());
  });

  it('creates a quarantined presigned URL for the current user avatar', async () => {
    const { service, uploadIntents } = createService();

    const result = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.AVATAR,
      fileName: 'avatar.png',
      contentType: 'image/png',
      sizeBytes: 1024,
    });

    expect(result.key).toMatch(/^quarantine\/avatars\/user-1\/.+\.png$/);
    expect(uploadIntents[0]).toMatchObject({
      actorId: 'user-1',
      purpose: UploadPurpose.AVATAR,
      entityId: 'user-1',
    });
  });

  it('sanitizes a confirmed avatar before replacing the profile URL', async () => {
    const { service, storage, uploadIntents, users } = createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.AVATAR,
      fileName: 'avatar.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });
    const source = await sharp({
      create: {
        width: 2,
        height: 2,
        channels: 3,
        background: '#0f766e',
      },
    })
      .jpeg()
      .toBuffer();
    storage.getObjectBuffer.mockResolvedValueOnce(source);

    const result = await service.confirmAvatarUpload('user-1', {
      intentId: upload.intentId,
    });

    expect(result.avatarUrl).toBe(
      `https://cdn.test/public-bucket/avatars/user-1/${upload.intentId}.webp`,
    );
    expect(users.get('user-1')?.avatarUrl).toBe(result.avatarUrl);
    expect(storage.putObject).toHaveBeenCalledWith(
      'public-bucket',
      `avatars/user-1/${upload.intentId}.webp`,
      expect.any(Buffer),
      'image/webp',
    );
    expect(storage.deleteObject).toHaveBeenCalledWith(
      'private-bucket',
      upload.key,
    );
    expect(uploadIntents[0].confirmedAt).toBeInstanceOf(Date);
  });

  it('rejects unsupported file content types', async () => {
    const { service, storage, uploadIntents } = createService();
    const dto: RequestUploadUrlDto = {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'drill.gif',
      contentType: 'image/gif',
      sizeBytes: 1024,
    };

    await expect(
      service.requestUploadUrl('user-1', dto),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(uploadIntents).toHaveLength(0);
    expect(storage.createPresignedPostUpload).not.toHaveBeenCalled();
  });

  it('rejects KYC documents before an accepted LOCAL_KYC ADR', async () => {
    const { service, storage } = createService();
    const dto: RequestUploadUrlDto = {
      purpose: UploadPurpose.KYC_DOCUMENT,
      fileName: 'passport.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 2048,
    };

    await expect(
      service.requestUploadUrl('user-1', dto),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(storage.createPresignedPostUpload).not.toHaveBeenCalled();
  });

  it('confirms an uploaded item photo and queues processing', async () => {
    const { service, photos, photoQueue, uploadIntents, items } =
      createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });
    const dto: ConfirmItemPhotoUploadDto = {
      intentId: upload.intentId,
    };

    const result = await service.confirmItemPhotoUpload('user-1', dto);

    expect(result.id).toBe('photo-1');
    expect(result.isCover).toBe(true);
    expect(result.sortOrder).toBe(0);
    expect(result.originalUrl).toBeNull();
    expect(photos).toHaveLength(1);
    expect(photoQueue.addItemPhotoUploaded).toHaveBeenCalledWith({
      itemPhotoId: 'photo-1',
      itemId: 'item-1',
      sourceBucket: 'private-bucket',
      sourceKey: upload.key,
    });
    expect(uploadIntents[0].confirmedAt).toBeInstanceOf(Date);
    expect(items.get('item-1')).toMatchObject({
      status: ItemStatus.PENDING,
      rejectReason: null,
    });
  });

  it('rejects an item photo above the per-listing limit', async () => {
    const { service, photos, photoQueue } = createService();

    for (let index = 0; index < 5; index += 1) {
      const upload = await service.requestUploadUrl('user-1', {
        purpose: UploadPurpose.ITEM_PHOTO,
        itemId: 'item-1',
        fileName: `photo-${index}.jpg`,
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      });
      await service.confirmItemPhotoUpload('user-1', {
        intentId: upload.intentId,
      });
    }

    const extra = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo-extra.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });

    await expect(
      service.confirmItemPhotoUpload('user-1', {
        intentId: extra.intentId,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(photos).toHaveLength(5);
    expect(photoQueue.addItemPhotoUploaded).toHaveBeenCalledTimes(5);
  });

  it('rejects a new photo while an unfinished booking exists', async () => {
    const { service, unfinishedBookings } = createService();
    unfinishedBookings.add('item-1');

    await expect(
      service.requestUploadUrl('user-1', {
        purpose: UploadPurpose.ITEM_PHOTO,
        itemId: 'item-1',
        fileName: 'photo.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('returns a short download URL only for the private intent owner', async () => {
    const { service, storage } = createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });

    await expect(
      service.getPrivateFileDownloadUrl('user-2', upload.intentId),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(
      service.getPrivateFileDownloadUrl('user-1', upload.intentId),
    ).resolves.toEqual({
      downloadUrl: `https://download.test/private-bucket/${upload.key}?signed=true`,
      expiresInSeconds: 60,
    });
    expect(storage.createPresignedDownloadUrl).toHaveBeenCalledWith(
      'private-bucket',
      upload.key,
      60,
    );
  });

  it('rejects an upload intent owned by another actor', async () => {
    const { service } = createService();
    const upload = await service.requestUploadUrl('user-2', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-2',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });

    await expect(
      service.confirmItemPhotoUpload('user-1', {
        intentId: upload.intentId,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns the same photo for replay without duplicate side effects', async () => {
    const { service, photos, photoQueue } = createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });

    const first = await service.confirmItemPhotoUpload('user-1', {
      intentId: upload.intentId,
    });
    const replay = await service.confirmItemPhotoUpload('user-1', {
      intentId: upload.intentId,
      sortOrder: 99,
      isCover: false,
    });

    expect(replay).toEqual(first);
    expect(photos).toHaveLength(1);
    expect(photoQueue.addItemPhotoUploaded).toHaveBeenCalledTimes(1);
  });

  it('rechecks entity ownership when confirming an intent', async () => {
    const { service, uploadIntents } = createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });
    uploadIntents[0].entityId = 'item-2';
    uploadIntents[0].objectKey =
      'quarantine/item-photos/item-2/00000000-0000-4000-8000-000000000000.jpg';

    await expect(
      service.confirmItemPhotoUpload('user-1', {
        intentId: upload.intentId,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it.each([
    {
      name: 'bucket',
      mutate: (intent: TestUploadIntent) => {
        intent.bucket = 'public-bucket';
      },
    },
    {
      name: 'object key',
      mutate: (intent: TestUploadIntent) => {
        intent.objectKey = 'quarantine/item-photos/item-2/foreign.jpg';
      },
    },
  ])('rejects a mismatched intent $name', async ({ mutate }) => {
    const { service, storage, uploadIntents } = createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });
    mutate(uploadIntents[0]);

    await expect(
      service.confirmItemPhotoUpload('user-1', {
        intentId: upload.intentId,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(storage.inspectUploadedObject).not.toHaveBeenCalled();
  });

  it.each([
    {
      name: 'missing object',
      object: null,
    },
    {
      name: 'size mismatch',
      object: {
        sizeBytes: 1025,
        contentType: 'image/jpeg',
        prefix: Buffer.from([0xff, 0xd8, 0xff]),
      },
    },
    {
      name: 'content type mismatch',
      object: {
        sizeBytes: 1024,
        contentType: 'image/png',
        prefix: Buffer.from([0xff, 0xd8, 0xff]),
      },
    },
    {
      name: 'magic bytes mismatch',
      object: {
        sizeBytes: 1024,
        contentType: 'image/jpeg',
        prefix: Buffer.from('not-an-image'),
      },
    },
  ])('rejects $name reported by storage', async ({ object }) => {
    const { service, storage, photos } = createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });
    storage.inspectUploadedObject.mockResolvedValueOnce(object);

    await expect(
      service.confirmItemPhotoUpload('user-1', {
        intentId: upload.intentId,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(photos).toHaveLength(0);
  });

  it('rejects an expired upload intent', async () => {
    const { service, photos, photoQueue, uploadIntents } = createService();
    const upload = await service.requestUploadUrl('user-1', {
      purpose: UploadPurpose.ITEM_PHOTO,
      itemId: 'item-1',
      fileName: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });
    uploadIntents[0].expiresAt = new Date(Date.now() - 1);

    await expect(
      service.confirmItemPhotoUpload('user-1', {
        intentId: upload.intentId,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(photos).toHaveLength(0);
    expect(photoQueue.addItemPhotoUploaded).not.toHaveBeenCalled();
  });

  it('rejects unknown items', async () => {
    const { service } = createService();

    await expect(
      service.requestUploadUrl('user-1', {
        purpose: UploadPurpose.ITEM_PHOTO,
        itemId: 'missing-item',
        fileName: 'drill.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('sanitizes participant-bound evidence and hashes the safe bytes', async () => {
    const image = await sharp({
      create: {
        width: 2,
        height: 2,
        channels: 3,
        background: '#0f766e',
      },
    })
      .jpeg()
      .toBuffer();
    const malwareMarker = Buffer.from('EICAR-POLYGLOT-MARKER');
    const objectBytes = Buffer.concat([image, malwareMarker]);
    const prisma = {
      booking: {
        findFirst: jest.fn().mockResolvedValue({ id: 'booking-1' }),
      },
      uploadIntent: {
        findFirst: jest.fn().mockResolvedValue({
          id: '11111111-1111-4111-8111-111111111111',
          entityId: 'booking-1',
          bucket: 'private-bucket',
          objectKey:
            'quarantine/booking-evidence/booking-1/user-1/evidence.jpg',
          contentType: 'image/jpeg',
          sizeBytes: objectBytes.length,
        }),
      },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      inspectUploadedObject: jest.fn().mockResolvedValue({
        sizeBytes: objectBytes.length,
        contentType: 'image/jpeg',
        prefix: objectBytes,
      }),
      getObjectBuffer: jest.fn().mockResolvedValue(objectBytes),
      putObject: jest
        .fn<Promise<void>, [string, string, Buffer, string]>()
        .mockResolvedValue(undefined),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );

    const result = await service.verifyBookingEvidenceIntent(
      'user-1',
      'booking-1',
      '11111111-1111-4111-8111-111111111111',
    );
    const sanitized = storage.putObject.mock.calls[0][2];

    expect(result).toMatchObject({
      objectKey: 'quarantine/booking-evidence/booking-1/user-1/evidence.jpg',
    });
    expect(result.sha256).toBe(
      createHash('sha256').update(sanitized).digest('hex'),
    );
    expect(sanitized.includes(malwareMarker)).toBe(false);
    expect(storage.putObject).toHaveBeenCalledWith(
      'private-bucket',
      'quarantine/booking-evidence/booking-1/user-1/evidence.jpg',
      expect.any(Buffer),
      'image/jpeg',
    );
  });

  it('does not presign an admin support attachment when its audit fails', async () => {
    const auditError = new Error('audit unavailable');
    const prisma = {
      supportTicket: {
        findFirst: jest.fn().mockResolvedValue({ id: 'ticket-1' }),
      },
      supportAttachment: {
        findFirst: jest.fn().mockResolvedValue({
          uploadIntent: {
            bucket: 'private-bucket',
            objectKey: 'support/ticket-1/attachment.webp',
          },
        }),
      },
      adminAuditLog: {
        create: jest.fn().mockRejectedValue(auditError),
      },
    };
    const storage = {
      createPresignedDownloadUrl: jest.fn(),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );

    await expect(
      service.getSupportAttachmentDownloadUrl(
        'admin-1',
        'ticket-1',
        'attachment-1',
        true,
        {
          requestId: 'support-download-request',
          ipAddress: '127.0.0.1',
          deviceId: 'device-hash',
        },
      ),
    ).rejects.toBe(auditError);

    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: {
        adminId: 'admin-1',
        action: 'SUPPORT_ATTACHMENT_DOWNLOAD_REQUESTED',
        entityType: 'SupportAttachment',
        entityId: 'attachment-1',
        capability: 'SUPPORT',
        requestId: 'support-download-request',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
        metadata: { supportTicketId: 'ticket-1' },
      },
    });
    expect(storage.createPresignedDownloadUrl).not.toHaveBeenCalled();
  });

  it('creates a participant-bound private dispute evidence intent', async () => {
    const prisma = {
      financialDispute: {
        findFirst: jest.fn().mockResolvedValue({ id: 'dispute-1' }),
      },
      uploadIntent: {
        create: jest
          .fn<Promise<{ id: string }>, [unknown]>()
          .mockResolvedValue({ id: 'intent-1' }),
      },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      createPresignedPostUpload: jest.fn().mockResolvedValue({
        uploadUrl: 'https://private.example/upload',
        fields: {},
      }),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );

    const result = await service.requestUploadUrl('borrower-1', {
      purpose: UploadPurpose.DISPUTE_EVIDENCE,
      disputeId: '11111111-1111-4111-8111-111111111111',
      fileName: 'evidence.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 1024,
    });

    expect(prisma.financialDispute.findFirst).toHaveBeenCalledWith({
      where: {
        id: '11111111-1111-4111-8111-111111111111',
        booking: {
          OR: [{ borrowerId: 'borrower-1' }, { lenderId: 'borrower-1' }],
        },
      },
      select: { id: true },
    });
    expect(prisma.uploadIntent.create).toHaveBeenCalledTimes(1);
    const createCall = prisma.uploadIntent.create.mock.calls[0][0] as {
      data: Record<string, unknown>;
      select: Record<string, unknown>;
    };
    expect(createCall.data).toMatchObject({
      actorId: 'borrower-1',
      purpose: UploadPurpose.DISPUTE_EVIDENCE,
      entityId: '11111111-1111-4111-8111-111111111111',
      bucket: 'private-bucket',
    });
    expect(createCall.data.objectKey).toEqual(expect.any(String));
    expect(String(createCall.data.objectKey)).toMatch(
      /^quarantine\/dispute-evidence\/11111111-1111-4111-8111-111111111111\/borrower-1\/.+\.jpg$/,
    );
    expect(createCall.select).toEqual({ id: true });
    expect(result.publicUrl).toBeNull();
  });

  it('does not create a dispute evidence intent for an outsider', async () => {
    const prisma = {
      financialDispute: { findFirst: jest.fn().mockResolvedValue(null) },
      uploadIntent: { create: jest.fn() },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      createPresignedPostUpload: jest.fn(),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );

    await expect(
      service.requestUploadUrl('outsider-1', {
        purpose: UploadPurpose.DISPUTE_EVIDENCE,
        disputeId: '11111111-1111-4111-8111-111111111111',
        fileName: 'evidence.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.uploadIntent.create).not.toHaveBeenCalled();
    expect(storage.createPresignedPostUpload).not.toHaveBeenCalled();
  });

  it('sanitizes and hashes immutable dispute evidence intent bytes', async () => {
    const image = await sharp({
      create: {
        width: 2,
        height: 2,
        channels: 3,
        background: '#0f766e',
      },
    })
      .jpeg()
      .toBuffer();
    const unsafeMarker = Buffer.from('UNSAFE-TRAILER');
    const objectBytes = Buffer.concat([image, unsafeMarker]);
    const prisma = {
      financialDispute: {
        findFirst: jest.fn().mockResolvedValue({ id: 'dispute-1' }),
      },
      uploadIntent: {
        findFirst: jest.fn().mockResolvedValue({
          id: '11111111-1111-4111-8111-111111111111',
          entityId: 'dispute-1',
          bucket: 'private-bucket',
          objectKey:
            'quarantine/dispute-evidence/dispute-1/borrower-1/evidence.jpg',
          contentType: 'image/jpeg',
          sizeBytes: objectBytes.length,
        }),
      },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      inspectUploadedObject: jest.fn().mockResolvedValue({
        sizeBytes: objectBytes.length,
        contentType: 'image/jpeg',
        prefix: objectBytes,
      }),
      getObjectBuffer: jest.fn().mockResolvedValue(objectBytes),
      putObject: jest
        .fn<Promise<void>, [string, string, Buffer, string]>()
        .mockResolvedValue(undefined),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );

    const result = await service.verifyDisputeEvidenceIntent(
      'borrower-1',
      'dispute-1',
      '11111111-1111-4111-8111-111111111111',
    );
    const sanitized = storage.putObject.mock.calls[0][2];

    expect(result.sha256).toBe(
      createHash('sha256').update(sanitized).digest('hex'),
    );
    expect(sanitized.includes(unsafeMarker)).toBe(false);
    expect(result.objectKey).toBe(
      'quarantine/dispute-evidence/dispute-1/borrower-1/evidence.jpg',
    );
  });

  it('rejects a dispute intent whose immutable actor path is changed', async () => {
    const prisma = {
      uploadIntent: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'intent-1',
          entityId: 'dispute-1',
          bucket: 'private-bucket',
          objectKey:
            'quarantine/dispute-evidence/dispute-1/other-user/evidence.jpg',
          contentType: 'image/jpeg',
          sizeBytes: 10,
        }),
      },
    };
    const storage = {
      getPrivateBucket: jest.fn().mockReturnValue('private-bucket'),
      inspectUploadedObject: jest.fn(),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );

    await expect(
      service.verifyDisputeEvidenceIntent(
        'borrower-1',
        'dispute-1',
        'intent-1',
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(storage.inspectUploadedObject).not.toHaveBeenCalled();
  });

  it('re-authorizes every private dispute evidence download', async () => {
    const prisma = {
      disputeEvidence: {
        findFirst: jest
          .fn()
          .mockResolvedValueOnce({
            uploadIntent: {
              bucket: 'private-bucket',
              objectKey: 'private/evidence.jpg',
            },
          })
          .mockResolvedValueOnce(null),
      },
    };
    const storage = {
      createPresignedDownloadUrl: jest
        .fn()
        .mockResolvedValue('https://private.example/download'),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );

    await expect(
      service.getDisputeEvidenceDownloadUrl(
        'borrower-1',
        'booking-1',
        'dispute-1',
        'evidence-1',
      ),
    ).resolves.toEqual({
      downloadUrl: 'https://private.example/download',
      expiresInSeconds: 60,
    });
    await expect(
      service.getDisputeEvidenceDownloadUrl(
        'outsider-1',
        'booking-1',
        'dispute-1',
        'evidence-1',
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.disputeEvidence.findFirst).toHaveBeenCalledTimes(2);
    expect(storage.createPresignedDownloadUrl).toHaveBeenCalledTimes(1);
  });

  it('does not presign admin dispute evidence when its audit fails', async () => {
    const auditError = new Error('audit unavailable');
    const prisma = {
      disputeEvidence: {
        findFirst: jest.fn().mockResolvedValue({
          uploadIntent: {
            bucket: 'private-bucket',
            objectKey: 'private/evidence.jpg',
          },
        }),
      },
      adminAuditLog: { create: jest.fn().mockRejectedValue(auditError) },
    };
    const storage = {
      createPresignedDownloadUrl: jest.fn(),
    };
    const service = new UploadService(
      prisma as unknown as PrismaService,
      storage as unknown as S3StorageService,
      {} as PhotoProcessingQueue,
    );
    await expect(
      service.getAdminDisputeEvidenceDownloadUrl(
        'admin-1',
        'dispute-1',
        'evidence-1',
        AdminCapability.DISPUTE,
        {
          requestId: 'evidence-download-request',
          ipAddress: '127.0.0.1',
          deviceId: 'device-hash',
        },
      ),
    ).rejects.toBe(auditError);

    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: {
        adminId: 'admin-1',
        action: 'FINANCIAL_DISPUTE_EVIDENCE_DOWNLOAD_REQUESTED',
        entityType: 'DisputeEvidence',
        entityId: 'evidence-1',
        capability: AdminCapability.DISPUTE,
        requestId: 'evidence-download-request',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
        metadata: { disputeId: 'dispute-1' },
      },
    });
    expect(storage.createPresignedDownloadUrl).not.toHaveBeenCalled();
  });
});
