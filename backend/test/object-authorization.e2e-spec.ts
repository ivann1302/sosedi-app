import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingStatus,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  PaymentStatus,
  SupportTicketType,
  UserRole,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { PrismaService } from './../src/prisma/prisma.service';
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';

describe('Object authorization (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;

  const storage = {
    createPresignedPutUrl: jest.fn(() =>
      Promise.resolve('https://upload.test/presigned'),
    ),
    getPublicBucket: jest.fn(() => 'public-bucket'),
    getPrivateBucket: jest.fn(() => 'private-bucket'),
    getPublicUrl: jest.fn(
      (bucket: string, key: string) => `https://cdn.test/${bucket}/${key}`,
    ),
    getObjectBuffer: jest.fn(),
    putObject: jest.fn(),
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

  it('denies an unrelated actor access to another user resources', async () => {
    const [owner, renter, unrelatedOwner] = await Promise.all([
      prisma.user.create({
        data: {
          phone: '+79990001001',
          name: 'Владелец',
          role: UserRole.USER,
        },
      }),
      prisma.user.create({
        data: {
          phone: '+79990001002',
          name: 'Арендатор',
          role: UserRole.USER,
        },
      }),
      prisma.user.create({
        data: {
          phone: '+79990001003',
          name: 'Посторонний',
          role: UserRole.USER,
        },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Игровые приставки',
        slug: 'object-auth-drills',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Приставка владельца',
        description: 'Исправная вещь в полной комплектации',
        condition: ItemCondition.GOOD,
        completeness: 'Приставка, аккумулятор, зарядное устройство и кейс',
        handoverTerms: 'Личная передача по договорённости',
        pricePerDay: 700,
        status: ItemStatus.APPROVED,
        publicArea: 'Северный округ',
        address: 'Москва, закрытый адрес, 1',
        latitude: 55.85,
        longitude: 37.6,
        photos: {
          create: {
            originalUrl: 'https://private.test/owner-original.jpg',
            thumbnailUrl: 'https://cdn.test/owner-thumbnail.jpg',
            previewUrl: 'https://cdn.test/owner-preview.jpg',
            isCover: true,
          },
        },
      },
      include: {
        photos: true,
      },
    });
    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: renter.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-01T00:00:00.000Z'),
        endDate: new Date('2026-08-03T00:00:00.000Z'),
        totalAmount: 2100,
        status: BookingStatus.CONFIRMED,
      },
    });
    const payment = await prisma.payment.create({
      data: {
        bookingId: booking.id,
        userId: renter.id,
        amount: 2100,
        status: PaymentStatus.PENDING,
      },
    });
    const dispute = await prisma.supportTicket.create({
      data: {
        userId: renter.id,
        bookingId: booking.id,
        type: SupportTicketType.DISPUTE,
        subject: 'Спор по бронированию',
        message: 'Приватные материалы спора',
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: unrelatedOwner.id,
        phone: unrelatedOwner.phone,
        role: unrelatedOwner.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );
    const authorization = `Bearer ${accessToken}`;

    await request(httpServer())
      .get(`/api/v1/users/${owner.id}`)
      .set('Authorization', authorization)
      .expect(404);
    await request(httpServer())
      .get(`/api/v1/admin/users/${owner.id}`)
      .set('Authorization', authorization)
      .expect(401);
    await request(httpServer())
      .patch('/api/v1/users/me')
      .set('Authorization', authorization)
      .send({
        id: owner.id,
        role: UserRole.ADMIN,
        name: 'Подмена профиля',
      })
      .expect(400);

    await request(httpServer())
      .patch(`/api/v1/items/${item.id}`)
      .set('Authorization', authorization)
      .send({ title: 'Подменённое объявление' })
      .expect(404);
    await request(httpServer())
      .patch(`/api/v1/items/${item.id}/hide`)
      .set('Authorization', authorization)
      .expect(404);
    await request(httpServer())
      .post('/api/v1/uploads/presigned-url')
      .set('Authorization', authorization)
      .send({
        purpose: 'ITEM_PHOTO',
        itemId: item.id,
        fileName: 'foreign.jpg',
        contentType: 'image/jpeg',
        sizeBytes: 1024,
      })
      .expect(404);
    const ownerUploadIntent = await prisma.uploadIntent.create({
      data: {
        actorId: owner.id,
        purpose: 'ITEM_PHOTO',
        entityId: item.id,
        bucket: 'public-bucket',
        objectKey: `items/${item.id}/original/foreign.jpg`,
        contentType: 'image/jpeg',
        sizeBytes: 1024,
        expiresAt: new Date(Date.now() + 15 * 60 * 1000),
      },
    });
    await request(httpServer())
      .post('/api/v1/uploads/item-photos/confirm')
      .set('Authorization', authorization)
      .send({
        intentId: ownerUploadIntent.id,
      })
      .expect(404);

    const unavailablePrivateResources = [
      `/api/v1/uploads/${ownerUploadIntent.id}/download-url`,
      `/api/v1/bookings/${booking.id}`,
      `/api/v1/payments/${payment.id}`,
      `/api/v1/disputes/${dispute.id}`,
      `/api/v1/private-files/${item.photos[0].id}`,
      `/api/v1/inbox/events/df653ea8-c188-49a2-92b5-a0f070c2eaeb`,
    ];
    for (const path of unavailablePrivateResources) {
      await request(httpServer())
        .get(path)
        .set('Authorization', authorization)
        .expect(404);
    }

    const [unchangedOwner, unchangedActor, unchangedItem, photoCount] =
      await Promise.all([
        prisma.user.findUniqueOrThrow({ where: { id: owner.id } }),
        prisma.user.findUniqueOrThrow({ where: { id: unrelatedOwner.id } }),
        prisma.item.findUniqueOrThrow({ where: { id: item.id } }),
        prisma.itemPhoto.count({ where: { itemId: item.id } }),
      ]);

    expect(unchangedOwner.name).toBe('Владелец');
    expect(unchangedOwner.role).toBe(UserRole.USER);
    expect(unchangedActor.name).toBe('Посторонний');
    expect(unchangedActor.role).toBe(UserRole.USER);
    expect(unchangedItem.title).toBe('Приставка владельца');
    expect(unchangedItem.status).toBe(ItemStatus.APPROVED);
    expect(photoCount).toBe(1);
    expect(storage.createPresignedPutUrl).not.toHaveBeenCalled();
  });

  afterAll(async () => {
    await app?.close();
  });
});
