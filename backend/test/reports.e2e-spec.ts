import { type INestApplication } from '@nestjs/common';
import { createHash, randomUUID } from 'node:crypto';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingMessageAuthorRole,
  BookingStatus,
  AdminCapability,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  ReviewAuthorRole,
  UserRole,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { ADMIN_SESSION_COOKIE } from './../src/admin/admin-session.service';
import { BookingOutboxProcessor } from './../src/booking/booking-outbox.processor';
import { PrismaService } from './../src/prisma/prisma.service';
import { RedisService } from './../src/redis/redis.service';
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';

describe('Reports (e2e)', () => {
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

  it('serializes duplicate reports, rate-limits mass reports and never mutates the item', async () => {
    const [owner, reporter, concurrentReporter] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990009001', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009002', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009003', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Report tests',
        slug: 'report-tests',
        listingPolicy: CategoryListingPolicy.ALLOWED,
        isAllowedForListings: true,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Объявление для жалобы',
        description: 'Описание объявления для проверки очереди жалоб',
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

    const authorization = await bearerToken(reporter);
    const concurrentAuthorization = await bearerToken(concurrentReporter);
    const duplicatePayload = {
      targetType: 'ITEM',
      targetId: item.id,
      reason: 'SUSPECTED_FRAUD',
      description: 'Подробное описание подозрительного поведения объявления.',
    };
    const duplicateResponses = await Promise.all([
      request(httpServer())
        .post('/api/v1/reports')
        .set('Authorization', concurrentAuthorization)
        .send(duplicatePayload),
      request(httpServer())
        .post('/api/v1/reports')
        .set('Authorization', concurrentAuthorization)
        .send(duplicatePayload),
    ]);
    expect(
      duplicateResponses.map((response) => response.status).sort(),
    ).toEqual([201, 409]);

    const reasons = [
      'PROHIBITED_CATEGORY',
      'MISLEADING_LISTING',
      'UNSAFE_ITEM',
      'SUSPECTED_FRAUD',
      'OTHER',
    ];
    for (const reason of reasons) {
      await request(httpServer())
        .post('/api/v1/reports')
        .set('Authorization', authorization)
        .send({
          targetType: 'ITEM',
          targetId: item.id,
          reason,
          description:
            'Подробное описание проблемы с объявлением, достаточное для ручной проверки.',
        })
        .expect(201);
    }
    await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', authorization)
      .send({
        targetType: 'ITEM',
        targetId: item.id,
        reason: 'UNSAFE_ITEM',
        description: 'Повторная массовая жалоба после исчерпания лимита.',
      })
      .expect(429);

    await expect(
      prisma.item.findUniqueOrThrow({ where: { id: item.id } }),
    ).resolves.toMatchObject({ status: ItemStatus.APPROVED });
  });

  it('accepts only a counterparty-authored message from the same booking', async () => {
    const [owner, borrower, outsider] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990009011', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009012', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009013', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Message report tests',
        slug: 'message-report-tests',
        listingPolicy: CategoryListingPolicy.ALLOWED,
        isAllowedForListings: true,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Вещь для проверки жалобы на сообщение',
        description: 'Описание вещи для participant-only проверки жалобы',
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
        lenderId: owner.id,
        startDate: new Date('2026-08-20T00:00:00.000Z'),
        endDate: new Date('2026-08-21T00:00:00.000Z'),
        totalAmount: 1000,
        status: BookingStatus.CONFIRMED,
      },
    });
    const [counterpartyMessage, ownMessage, systemMessage] = await Promise.all([
      prisma.bookingMessage.create({
        data: {
          bookingId: booking.id,
          authorId: owner.id,
          authorRole: BookingMessageAuthorRole.LENDER,
          body: 'Недопустимое сообщение второй стороне',
        },
      }),
      prisma.bookingMessage.create({
        data: {
          bookingId: booking.id,
          authorId: borrower.id,
          authorRole: BookingMessageAuthorRole.BORROWER,
          body: 'Собственное сообщение заявителя',
        },
      }),
      prisma.bookingMessage.create({
        data: {
          bookingId: booking.id,
          authorRole: BookingMessageAuthorRole.SYSTEM,
          body: 'Системное сообщение',
        },
      }),
    ]);
    const borrowerAuthorization = await bearerToken(borrower);
    const payload = {
      targetType: 'MESSAGE',
      targetId: counterpartyMessage.id,
      reason: 'HARASSMENT',
      description: 'Сообщение содержит преследование или угрозы.',
    };

    await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', borrowerAuthorization)
      .send(payload)
      .expect(201)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          data: { targetType: 'MESSAGE', targetId: counterpartyMessage.id },
        });
      });
    for (const targetId of [ownMessage.id, systemMessage.id]) {
      await request(httpServer())
        .post('/api/v1/reports')
        .set('Authorization', borrowerAuthorization)
        .send({ ...payload, targetId })
        .expect(404);
    }
    await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', await bearerToken(outsider))
      .send(payload)
      .expect(404);
  });

  it('moderates a published review with audited context and neutral notification', async () => {
    const [admin, owner, borrower, reporter] = await Promise.all([
      prisma.user.create({
        data: {
          phone: '+79990009021',
          role: UserRole.ADMIN,
          adminCapabilities: [AdminCapability.MODERATION],
        },
      }),
      prisma.user.create({
        data: { phone: '+79990009022', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009023', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009024', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Review report tests',
        slug: 'review-report-tests',
        listingPolicy: CategoryListingPolicy.ALLOWED,
        isAllowedForListings: true,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Вещь из завершённой аренды',
        description: 'Описание вещи для проверки модерации отзыва',
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
        lenderId: owner.id,
        startDate: new Date('2026-08-01T00:00:00.000Z'),
        endDate: new Date('2026-08-02T00:00:00.000Z'),
        totalAmount: 1000,
        status: BookingStatus.COMPLETED,
      },
    });
    const review = await prisma.review.create({
      data: {
        bookingId: booking.id,
        authorId: borrower.id,
        targetId: owner.id,
        authorRole: ReviewAuthorRole.BORROWER,
        clientReviewId: randomUUID(),
        rating: 1,
        text: 'Текст содержит персональные данные и должен быть проверен.',
        publishAt: new Date('2026-08-08T00:00:00.000Z'),
      },
    });
    const unpublishedReview = await prisma.review.create({
      data: {
        bookingId: booking.id,
        authorId: owner.id,
        targetId: borrower.id,
        authorRole: ReviewAuthorRole.LENDER,
        clientReviewId: randomUUID(),
        rating: 5,
        text: 'Этот отзыв ещё находится в double-blind периоде.',
        publishAt: new Date('2099-08-23T00:00:00.000Z'),
      },
    });
    const payload = {
      targetType: 'REVIEW',
      targetId: review.id,
      reason: 'PRIVACY_VIOLATION',
      description: 'В опубликованном отзыве раскрыты персональные данные.',
    };
    await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', await bearerToken(borrower))
      .send(payload)
      .expect(404);
    await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', await bearerToken(reporter))
      .send({ ...payload, targetId: unpublishedReview.id })
      .expect(404);
    const reportResponse = await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', await bearerToken(reporter))
      .send(payload)
      .expect(201);
    const reportId = (reportResponse.body as { data: { id: string } }).data.id;
    const adminSession = await adminSessionFor(admin);

    await request(httpServer())
      .get(`/api/v1/admin/reports/${reportId}/review-context`)
      .set('Cookie', adminSession.cookie)
      .set('X-Request-Id', 'reported-review-context-request')
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          data: {
            id: review.id,
            rating: 1,
            text: review.text,
            authorRole: ReviewAuthorRole.BORROWER,
          },
        });
      });
    await request(httpServer())
      .patch(`/api/v1/admin/reports/${reportId}/decision`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'review-hide-request')
      .send({
        decision: 'HIDE_REVIEW',
        reason: 'Подтверждено раскрытие персональных данных в отзыве.',
      })
      .expect(200);

    await expect(
      prisma.review.findUniqueOrThrow({ where: { id: review.id } }),
    ).resolves.toMatchObject({
      hiddenById: admin.id,
      hiddenReason: 'Подтверждено раскрытие персональных данных в отзыве.',
    });
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: booking.id } }),
    ).resolves.toMatchObject({ status: BookingStatus.COMPLETED });
    await request(httpServer())
      .get(`/api/v1/users/${owner.id}/reviews`)
      .set('Authorization', await bearerToken(reporter))
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          data: { summary: { average: null, count: 0 }, items: [] },
        });
      });
    await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', await bearerToken(reporter))
      .send({ ...payload, reason: 'HARASSMENT' })
      .expect(404);
    await expect(
      prisma.adminAuditLog.findMany({
        where: { entityId: { in: [review.id, reportId] } },
        orderBy: { createdAt: 'asc' },
      }),
    ).resolves.toEqual([
      expect.objectContaining({
        action: 'REPORTED_REVIEW_ACCESSED',
        requestId: 'reported-review-context-request',
        metadata: { reportId },
      }),
      expect.objectContaining({
        action: 'REPORT_DECIDED',
        requestId: 'review-hide-request',
        after: { status: 'ACTIONED', decision: 'HIDE_REVIEW' },
      }),
    ]);
    await app?.get(BookingOutboxProcessor).processPending();
    const inbox = await request(httpServer())
      .get('/api/v1/inbox')
      .set('Authorization', await bearerToken(borrower))
      .expect(200);
    expect(inbox.body).toMatchObject({
      data: [
        expect.objectContaining({
          bookingId: booking.id,
          eventType: 'REVIEW_HIDDEN_BY_REPORT_REVIEW',
        }),
      ],
    });
    expect(JSON.stringify(inbox.body)).not.toContain(reporter.id);
  });

  async function adminSessionFor(user: {
    id: string;
  }): Promise<{ cookie: string; csrfToken: string }> {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const sessionId = randomUUID();
    const csrfToken = randomUUID();
    await app
      .get(RedisService)
      .getClient()
      .set(
        `auth:admin-session:${sessionId}`,
        JSON.stringify({
          userId: user.id,
          sessionVersion: 0,
          csrfTokenHash: createHash('sha256').update(csrfToken).digest('hex'),
        }),
        'EX',
        300,
      );
    return {
      cookie: `${ADMIN_SESSION_COOKIE}=${sessionId}`,
      csrfToken,
    };
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
