import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingActStage,
  BookingStatus,
  CategoryListingPolicy,
  ItemCondition,
  UserRole,
} from '@prisma/client';
import sharp from 'sharp';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { PrismaService } from './../src/prisma/prisma.service';
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object response body');
  }

  return value as Record<string, unknown>;
}

describe('Upload API (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;

  const storage = {
    createPresignedPostUpload: jest.fn(
      (bucket: string, key: string, contentType: string) =>
        Promise.resolve({
          uploadUrl: 'https://upload.test/presigned',
          fields: {
            bucket,
            key,
            'Content-Type': contentType,
            Policy: 'signed-policy',
          },
        }),
    ),
    getPublicBucket: jest.fn(() => 'public-bucket'),
    getPrivateBucket: jest.fn(() => 'private-bucket'),
    getPublicUrl: jest.fn(
      (bucket: string, key: string) => `https://cdn.test/${bucket}/${key}`,
    ),
    createPresignedDownloadUrl: jest.fn((bucket: string, key: string) =>
      Promise.resolve(`https://download.test/${bucket}/${key}?signed=true`),
    ),
    inspectUploadedObject: jest.fn((_bucket: string, key: string) =>
      Promise.resolve({
        sizeBytes: 1024,
        contentType: key.endsWith('.png') ? 'image/png' : 'image/jpeg',
        prefix: key.endsWith('.png')
          ? Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
          : Buffer.from([0xff, 0xd8, 0xff]),
      }),
    ),
    getObjectBuffer: jest.fn(),
    putObject: jest.fn(),
    deleteObject: jest.fn().mockResolvedValue(undefined),
  };

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    return app.getHttpServer();
  }

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(S3StorageService)
      .useValue(storage)
      .compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
    jwt = app.get(JwtService);
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    jest.clearAllMocks();
    await resetTestState(app);
  });

  it('rejects KYC presign and confirm before an accepted LOCAL_KYC ADR', async () => {
    const owner = await prisma.user.create({
      data: {
        phone: '+79990000456',
        role: UserRole.USER,
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: owner.id,
        phone: owner.phone,
        role: owner.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );

    const presignResponse = await request(httpServer())
      .post('/api/v1/uploads/presigned-url')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        purpose: 'KYC_DOCUMENT',
        fileName: 'passport.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      })
      .expect(403);

    expect(presignResponse.body).toMatchObject({
      success: false,
      data: null,
      error: {
        code: 'FORBIDDEN',
      },
    });
    expect(storage.createPresignedPostUpload).not.toHaveBeenCalled();

    const confirmResponse = await request(httpServer())
      .post('/api/v1/uploads/item-photos/confirm')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        purpose: 'KYC_DOCUMENT',
        itemId: '3a19bb5c-49c3-40f6-ab00-79a421dd59b2',
        key: 'kyc/document.jpg',
      })
      .expect(400);

    expect(confirmResponse.body).toMatchObject({
      success: false,
      data: null,
      error: {
        code: 'VALIDATION_ERROR',
      },
    });
    const confirmBody = asRecord(confirmResponse.body as unknown);
    const confirmError = asRecord(confirmBody.error);
    expect(confirmError.message).toEqual(
      expect.stringContaining('property purpose should not exist'),
    );
  });

  it('replaces only the current user avatar through quarantine confirm', async () => {
    const user = await prisma.user.create({
      data: {
        phone: '+79990000457',
        role: UserRole.USER,
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );
    const authorization = `Bearer ${accessToken}`;
    const presignResponse = await request(httpServer())
      .post('/api/v1/uploads/presigned-url')
      .set('Authorization', authorization)
      .send({
        purpose: 'AVATAR',
        fileName: 'avatar.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      })
      .expect(201);
    const presignData = asRecord(asRecord(presignResponse.body).data);
    const intentId = String(presignData.intentId);
    storage.getObjectBuffer.mockResolvedValueOnce(
      await sharp({
        create: {
          width: 2,
          height: 2,
          channels: 3,
          background: '#0f766e',
        },
      })
        .jpeg()
        .toBuffer(),
    );

    const confirmResponse = await request(httpServer())
      .post('/api/v1/uploads/avatars/confirm')
      .set('Authorization', authorization)
      .send({ intentId })
      .expect(201);
    const confirmData = asRecord(asRecord(confirmResponse.body).data);

    expect(confirmData.avatarUrl).toBe(
      `https://cdn.test/public-bucket/avatars/${user.id}/${intentId}.webp`,
    );
    await expect(
      prisma.user.findUniqueOrThrow({ where: { id: user.id } }),
    ).resolves.toMatchObject({ avatarUrl: confirmData.avatarUrl });
    await request(httpServer())
      .patch('/api/v1/users/me')
      .set('Authorization', authorization)
      .send({ avatarUrl: 'https://attacker.example/avatar.jpg' })
      .expect(400);
  });

  it('binds a backend-generated key to an idempotent upload intent', async () => {
    const owner = await prisma.user.create({
      data: {
        phone: '+79990000457',
        role: UserRole.USER,
      },
    });
    const category = await prisma.category.create({
      data: {
        name: 'Фото-тест',
        slug: 'upload-photo-test',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
        safetyNotice: 'Проверьте исправность вещи перед передачей.',
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Тестовая вещь',
        description: 'Вещь для проверки безопасной загрузки фотографии',
        condition: ItemCondition.GOOD,
        completeness: 'Вещь и комплект поставки',
        handoverTerms: 'Личная передача по договорённости',
        pricePerDay: 500,
        publicArea: 'Центральный округ',
        address: 'Москва, Тверская улица, 1',
        latitude: 55.7558,
        longitude: 37.6173,
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: owner.id,
        phone: owner.phone,
        role: owner.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );

    const presignResponse = await request(httpServer())
      .post('/api/v1/uploads/presigned-url')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        purpose: 'ITEM_PHOTO',
        itemId: item.id,
        fileName: '../../client-key.png',
        contentType: 'image/png',
        sizeBytes: 1024,
      })
      .expect(201);
    const presignData = asRecord(
      asRecord(presignResponse.body as unknown).data,
    );
    const intentId = String(presignData.intentId);
    const key = String(presignData.key);

    expect(presignData).toMatchObject({
      method: 'POST',
      expiresInSeconds: 900,
      fields: {
        bucket: 'private-bucket',
        key,
        'Content-Type': 'image/png',
        Policy: 'signed-policy',
      },
      constraints: {
        contentType: 'image/png',
        sizeBytes: 1024,
      },
    });
    expect(storage.createPresignedPostUpload).toHaveBeenCalledWith(
      'private-bucket',
      key,
      'image/png',
      1024,
      900,
    );
    expect(key).toMatch(
      new RegExp(`^quarantine/item-photos/${item.id}/[0-9a-f-]+\\.png$`),
    );
    await expect(
      prisma.uploadIntent.findUniqueOrThrow({ where: { id: intentId } }),
    ).resolves.toMatchObject({
      actorId: owner.id,
      purpose: 'ITEM_PHOTO',
      entityId: item.id,
      bucket: 'private-bucket',
      objectKey: key,
      contentType: 'image/png',
      sizeBytes: 1024,
      confirmedAt: null,
    });

    const downloadResponse = await request(httpServer())
      .get(`/api/v1/uploads/${intentId}/download-url`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    const downloadBody = asRecord(downloadResponse.body as unknown);
    expect(downloadBody).toMatchObject({
      success: true,
      data: {
        expiresInSeconds: 60,
      },
      error: null,
    });
    const downloadData = asRecord(downloadBody.data);
    expect(downloadData.downloadUrl).toBe(
      `https://download.test/private-bucket/${key}?signed=true`,
    );
    expect(storage.createPresignedDownloadUrl).toHaveBeenCalledWith(
      'private-bucket',
      key,
      60,
    );

    const [firstConfirm, concurrentConfirm] = await Promise.all([
      request(httpServer())
        .post('/api/v1/uploads/item-photos/confirm')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ intentId })
        .expect(201),
      request(httpServer())
        .post('/api/v1/uploads/item-photos/confirm')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ intentId })
        .expect(201),
    ]);
    expect(concurrentConfirm.body).toEqual(firstConfirm.body);
    expect(
      asRecord(asRecord(firstConfirm.body as unknown).data).originalUrl,
    ).toBeNull();
    const replayConfirm = await request(httpServer())
      .post('/api/v1/uploads/item-photos/confirm')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ intentId })
      .expect(201);

    expect(replayConfirm.body).toEqual(firstConfirm.body);

    const consumedIntent = await prisma.uploadIntent.findUniqueOrThrow({
      where: { id: intentId },
    });
    expect(consumedIntent.confirmedAt).toBeInstanceOf(Date);
    await expect(
      prisma.itemPhoto.count({ where: { itemId: item.id } }),
    ).resolves.toBe(1);
  });

  it('presigns booking evidence only for a booking participant', async () => {
    const [owner, borrower, outsider] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990000461', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000462', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000463', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Evidence download e2e',
        slug: 'evidence-download-e2e',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Вещь с актом',
        description: 'Проверка приватного evidence download',
        condition: ItemCondition.GOOD,
        completeness: 'Полный комплект',
        handoverTerms: 'Личная передача',
        pricePerDay: 500,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
    });
    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: borrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-20T00:00:00.000Z'),
        endDate: new Date('2026-08-21T00:00:00.000Z'),
        totalAmount: 1000,
        status: BookingStatus.CONFIRMED,
      },
    });
    const act = await prisma.bookingAct.create({
      data: {
        bookingId: booking.id,
        authorId: borrower.id,
        stage: BookingActStage.HANDOVER,
      },
    });
    const objectKey = `booking-evidence/${booking.id}/handover.webp`;
    const intent = await prisma.uploadIntent.create({
      data: {
        actorId: borrower.id,
        purpose: 'BOOKING_EVIDENCE',
        entityId: booking.id,
        bucket: 'private-bucket',
        objectKey,
        contentType: 'image/webp',
        sizeBytes: 1024,
        expiresAt: new Date('2026-08-20T00:00:00.000Z'),
        confirmedAt: new Date('2026-07-30T00:00:00.000Z'),
      },
    });
    const evidence = await prisma.bookingEvidence.create({
      data: {
        actId: act.id,
        uploadIntentId: intent.id,
        storageKey: objectKey,
        sha256: 'a'.repeat(64),
      },
    });
    const [borrowerToken, outsiderToken] = await Promise.all([
      jwt.signAsync(
        {
          sub: borrower.id,
          phone: borrower.phone,
          role: borrower.role,
          tokenType: 'access',
          sessionVersion: 0,
        },
        { secret: 'e2e-access-secret', expiresIn: '15m' },
      ),
      jwt.signAsync(
        {
          sub: outsider.id,
          phone: outsider.phone,
          role: outsider.role,
          tokenType: 'access',
          sessionVersion: 0,
        },
        { secret: 'e2e-access-secret', expiresIn: '15m' },
      ),
    ]);
    const endpoint = `/api/v1/bookings/${booking.id}/evidence/${evidence.id}/download-url`;

    await request(httpServer())
      .get(endpoint)
      .set('Authorization', `Bearer ${outsiderToken}`)
      .expect(404);
    expect(storage.createPresignedDownloadUrl).not.toHaveBeenCalled();

    const response = await request(httpServer())
      .get(endpoint)
      .set('Authorization', `Bearer ${borrowerToken}`)
      .expect(200);
    expect(response.body).toMatchObject({
      success: true,
      data: {
        downloadUrl: `https://download.test/private-bucket/${objectKey}?signed=true`,
        expiresInSeconds: 60,
      },
      error: null,
    });
    expect(JSON.stringify(response.body)).not.toContain('objectKey');
    expect(storage.createPresignedDownloadUrl).toHaveBeenCalledWith(
      'private-bucket',
      objectKey,
      60,
    );
  });

  afterAll(async () => {
    await app?.close();
  });
});
