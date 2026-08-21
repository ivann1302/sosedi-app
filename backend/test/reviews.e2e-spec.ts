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

describe('Verified reviews (e2e)', () => {
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

  it('publishes both verified reviews double-blind without booking data', async () => {
    const [lender, borrower, outsider] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990009501', name: 'Анна', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009502', name: 'Иван', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009503', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Review tests',
        slug: 'review-tests',
        listingPolicy: CategoryListingPolicy.ALLOWED,
        isAllowedForListings: true,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: lender.id,
        categoryId: category.id,
        title: 'Вещь для подтверждённого отзыва',
        description: 'Описание вещи для double-blind review e2e',
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
    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: borrower.id,
        lenderId: lender.id,
        startDate: new Date('2026-08-01T00:00:00.000Z'),
        endDate: new Date('2026-08-02T00:00:00.000Z'),
        totalAmount: 1000,
        status: BookingStatus.COMPLETED,
      },
    });
    await prisma.bookingTransitionHistory.create({
      data: {
        bookingId: booking.id,
        actorType: 'SYSTEM',
        command: 'COMPLETE',
        oldStatus: BookingStatus.RETURNED,
        newStatus: BookingStatus.COMPLETED,
        requestId: '11111111-1111-4111-8111-111111111161',
      },
    });
    const borrowerAuthorization = await bearerToken(borrower);
    const lenderAuthorization = await bearerToken(lender);
    const borrowerPayload = {
      clientReviewId: '11111111-1111-4111-8111-111111111162',
      rating: 5,
      text: 'Всё прошло отлично, вещь исправна.',
    };

    await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/reviews`)
      .set('Authorization', await bearerToken(outsider))
      .send(borrowerPayload)
      .expect(404);
    const first = await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/reviews`)
      .set('Authorization', borrowerAuthorization)
      .send(borrowerPayload)
      .expect(201);
    expect(record(record(first.body).data)).toMatchObject({
      author: 'SELF',
      rating: 5,
      published: false,
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/reviews`)
      .set('Authorization', borrowerAuthorization)
      .send(borrowerPayload)
      .expect(201)
      .expect(({ body }) => {
        expect(record(record(body).data).id).toBe(
          record(record(first.body).data).id,
        );
      });
    await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/reviews`)
      .set('Authorization', borrowerAuthorization)
      .send({
        ...borrowerPayload,
        clientReviewId: '11111111-1111-4111-8111-111111111163',
      })
      .expect(409);

    await request(httpServer())
      .get(`/api/v1/users/${lender.id}/reviews`)
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          data: { summary: { average: null, count: 0 }, items: [] },
        });
      });
    await request(httpServer())
      .get(`/api/v1/bookings/${booking.id}/reviews`)
      .set('Authorization', borrowerAuthorization)
      .expect(200)
      .expect(({ body }) => {
        const reviews = record(body).data;
        expect(reviews).toEqual([
          expect.objectContaining({ author: 'SELF', published: false }),
        ]);
      });

    await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/reviews`)
      .set('Authorization', lenderAuthorization)
      .send({
        clientReviewId: '11111111-1111-4111-8111-111111111164',
        rating: 4,
        text: 'Арендатор вернул вещь вовремя.',
      })
      .expect(201)
      .expect(({ body }) => {
        expect(body).toMatchObject({ data: { published: true } });
      });

    const publicResponse = await request(httpServer())
      .get(`/api/v1/users/${lender.id}/reviews`)
      .expect(200);
    const publicData = record(record(publicResponse.body).data);
    expect(publicData.summary).toEqual({ average: 5, count: 1 });
    expect(publicData.items).toEqual([
      expect.objectContaining({
        authorRole: 'BORROWER',
        rating: 5,
        verifiedRental: true,
      }),
    ]);
    const serialized = JSON.stringify(publicData);
    expect(serialized).not.toContain(booking.id);
    expect(serialized).not.toContain(borrower.id);
    expect(serialized).not.toContain(lender.id);

    await request(httpServer())
      .get(`/api/v1/bookings/${booking.id}/reviews`)
      .set('Authorization', borrowerAuthorization)
      .expect(200)
      .expect(({ body }) => {
        const reviews = record(body).data as unknown[];
        expect(reviews).toHaveLength(2);
        expect(reviews).toEqual(
          expect.arrayContaining([
            expect.objectContaining({ author: 'SELF', published: true }),
            expect.objectContaining({
              author: 'COUNTERPARTY',
              published: true,
            }),
          ]),
        );
      });
  });

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

function record(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object');
  }
  return value as Record<string, unknown>;
}
