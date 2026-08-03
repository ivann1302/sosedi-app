import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingStatus,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  UserRole,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { PrismaService } from './../src/prisma/prisma.service';
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';

function acceptedBookingPayload(itemId: string) {
  return {
    itemId,
    startDate: '2026-08-10',
    endDate: '2026-08-11',
    offerVersion: 'e2e-approved-offer-1',
    cancellationPolicyVersion: 'e2e-approved-cancellation-1',
    offerAccepted: true,
    rentalRulesAccepted: true,
  };
}

describe('User blocks (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;

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
      .useValue({})
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
    await resetTestState(app);
  });

  it('blocks new bookings in both directions without hiding an existing booking', async () => {
    const [owner, borrower] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990009101', name: 'Владелец', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009102', name: 'Арендатор', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Block tests',
        slug: 'block-tests',
        listingPolicy: CategoryListingPolicy.ALLOWED,
        isAllowedForListings: true,
      },
    });
    const [existingItem, newItem] = await Promise.all([
      createItem(owner.id, category.id, 'Существующая аренда'),
      createItem(owner.id, category.id, 'Новая аренда'),
    ]);
    const existingBooking = await prisma.booking.create({
      data: {
        itemId: existingItem.id,
        borrowerId: borrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-01T00:00:00.000Z'),
        endDate: new Date('2026-08-02T00:00:00.000Z'),
        totalAmount: 1000,
        status: BookingStatus.CONFIRMED,
      },
    });
    const ownerAuthorization = await bearerToken(owner);
    const borrowerAuthorization = await bearerToken(borrower);

    const firstBlock = await request(httpServer())
      .post(`/api/v1/users/blocks/${borrower.id}`)
      .set('Authorization', ownerAuthorization)
      .expect(201);
    const repeatBlock = await request(httpServer())
      .post(`/api/v1/users/blocks/${borrower.id}`)
      .set('Authorization', ownerAuthorization)
      .expect(201);
    expect(asRecord(asRecord(repeatBlock.body as unknown).data).id).toBe(
      asRecord(asRecord(firstBlock.body as unknown).data).id,
    );
    const ownerBlocksResponse = await request(httpServer())
      .get('/api/v1/users/blocks')
      .set('Authorization', ownerAuthorization)
      .expect(200);
    const ownerBlocks = asRecord(ownerBlocksResponse.body as unknown).data;
    expect(Array.isArray(ownerBlocks)).toBe(true);
    expect(ownerBlocks).toHaveLength(1);
    const borrowerBlocksResponse = await request(httpServer())
      .get('/api/v1/users/blocks')
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(asRecord(borrowerBlocksResponse.body as unknown).data).toEqual([]);

    await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(newItem.id))
      .expect(409);

    const bookingsResponse = await request(httpServer())
      .get('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const bookings = asRecord(bookingsResponse.body as unknown).data;
    expect(Array.isArray(bookings)).toBe(true);
    expect(
      (bookings as unknown[]).some(
        (booking) => asRecord(booking).id === existingBooking.id,
      ),
    ).toBe(true);

    await request(httpServer())
      .delete(`/api/v1/users/blocks/${borrower.id}`)
      .set('Authorization', ownerAuthorization)
      .expect(200);
    await request(httpServer())
      .post(`/api/v1/users/blocks/${owner.id}`)
      .set('Authorization', borrowerAuthorization)
      .expect(201);
    await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(newItem.id))
      .expect(409);
    await request(httpServer())
      .post(`/api/v1/users/blocks/${borrower.id}`)
      .set('Authorization', borrowerAuthorization)
      .expect(400);
  });

  function createItem(ownerId: string, categoryId: string, title: string) {
    return prisma.item.create({
      data: {
        ownerId,
        categoryId,
        title,
        description: 'Исправная вещь для проверки пользовательской блокировки',
        condition: ItemCondition.GOOD,
        completeness: 'Полный комплект',
        handoverTerms: 'Личная передача',
        pricePerDay: 500,
        status: ItemStatus.APPROVED,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
    });
  }

  async function bearerToken(user: {
    id: string;
    phone: string;
    role: UserRole;
  }): Promise<string> {
    return `Bearer ${await jwt.signAsync(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      { secret: 'e2e-access-secret', expiresIn: '15m' },
    )}`;
  }

  afterAll(async () => {
    await app?.close();
  });
});

function asRecord(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('Expected object');
  }
  return value as Record<string, unknown>;
}
