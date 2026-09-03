import { type INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingStatus,
  BookingActStage,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  PushPlatform,
  PushTokenProvider,
  UserRole,
  type User,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import {
  BOOKING_PENDING_TIMEOUT_REASON,
  BookingExpiryService,
} from '../src/booking/booking-expiry.service';
import { BOOKING_PENDING_TTL_MS } from '../src/booking/booking.service';
import { BookingOutboxProcessor } from '../src/booking/booking-outbox.processor';
import { PrismaService } from '../src/prisma/prisma.service';
import { UploadService } from '../src/upload/upload.service';
import { resetTestState } from './support/test-state';

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object');
  }
  return value as Record<string, unknown>;
}

function acceptedBookingPayload(
  itemId: string,
  startDate: string,
  endDate: string,
) {
  return {
    itemId,
    startDate,
    endDate,
    offerVersion: 'e2e-approved-offer-1',
    cancellationPolicyVersion: 'e2e-approved-cancellation-1',
    offerAccepted: true,
    rentalRulesAccepted: true,
  };
}

describe('Booking availability (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;
  let config: ConfigService;
  let expiry: BookingExpiryService;
  let outbox: BookingOutboxProcessor;
  const evidenceUpload = {
    verifyBookingEvidenceIntent: jest.fn(
      (_actorId: string, _bookingId: string, intentId: string) =>
        Promise.resolve({
          intentId,
          bucket: 'private-test',
          objectKey: `quarantine/booking-evidence/${intentId}.jpg`,
          sha256: 'a'.repeat(64),
        }),
    ),
    getBookingEvidenceDownloadUrl: jest.fn(() =>
      Promise.resolve({
        downloadUrl: 'https://private.test/evidence?signed=true',
        expiresInSeconds: 60,
      }),
    ),
  };

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    return app.getHttpServer();
  }

  async function authorization(user: User): Promise<string> {
    const token = await jwt.signAsync(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        tokenType: 'access',
        sessionVersion: user.sessionVersion,
      },
      { secret: 'e2e-access-secret', expiresIn: '15m' },
    );
    return `Bearer ${token}`;
  }

  async function createFixture() {
    const [owner, firstBorrower, secondBorrower] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990000201', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000202', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000203', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Booking e2e',
        slug: 'booking-e2e',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Складной стол',
        description: 'Одна физическая единица для проверки календаря',
        condition: ItemCondition.GOOD,
        completeness: 'Стол и чехол',
        handoverTerms: 'Личная передача',
        pricePerDay: 600,
        status: ItemStatus.APPROVED,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
    });
    return { owner, firstBorrower, secondBorrower, item };
  }

  beforeAll(async () => {
    jest.useFakeTimers({
      doNotFake: [
        'hrtime',
        'nextTick',
        'performance',
        'queueMicrotask',
        'setImmediate',
        'setInterval',
        'setTimeout',
      ],
    });
    jest.setSystemTime(new Date('2026-07-29T12:00:00.000Z'));
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(UploadService)
      .useValue(evidenceUpload)
      .compile();
    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
    jwt = app.get(JwtService);
    prisma = app.get(PrismaService);
    config = app.get(ConfigService);
    expiry = app.get(BookingExpiryService);
    outbox = app.get(BookingOutboxProcessor);
  });

  beforeEach(async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    await resetTestState(app);
  });

  it('rejects direct booking API access while approved terms are unavailable', async () => {
    const { firstBorrower, item } = await createFixture();
    const borrowerAuthorization = await authorization(firstBorrower);
    const offerVersion = config.get<string>('MARKETPLACE_OFFER_VERSION');
    const cancellationVersion = config.get<string>(
      'MARKETPLACE_CANCELLATION_POLICY_VERSION',
    );
    config.set('MARKETPLACE_OFFER_VERSION', '');
    config.set('MARKETPLACE_CANCELLATION_POLICY_VERSION', '');

    try {
      await request(httpServer())
        .post('/api/v1/bookings')
        .set('Authorization', borrowerAuthorization)
        .send({
          itemId: item.id,
          startDate: '2026-08-01',
          endDate: '2026-08-01',
        })
        .expect(503)
        .expect(({ body }) => {
          expect(body).toMatchObject({
            success: false,
            data: null,
            error: {
              code: 'BOOKING_LEGAL_GATE_CLOSED',
              message: 'Бронирование временно недоступно',
            },
          });
        });
      await expect(prisma.booking.count()).resolves.toBe(0);
    } finally {
      config.set('MARKETPLACE_OFFER_VERSION', offerVersion);
      config.set(
        'MARKETPLACE_CANCELLATION_POLICY_VERSION',
        cancellationVersion,
      );
    }
  });

  it('requires explicit acceptance of the currently configured terms', async () => {
    const { firstBorrower, item } = await createFixture();

    await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', await authorization(firstBorrower))
      .send({
        itemId: item.id,
        startDate: '2026-08-01',
        endDate: '2026-08-01',
      })
      .expect(409)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          success: false,
          data: null,
          error: {
            code: 'BOOKING_TERMS_ACCEPTANCE_REQUIRED',
            message: 'Подтвердите актуальные условия аренды',
          },
        });
      });
    await expect(prisma.booking.count()).resolves.toBe(0);
  });

  it('lets only the owner block a free period and preserves a confirmed booking', async () => {
    const { owner, firstBorrower, item } = await createFixture();
    const ownerAuthorization = await authorization(owner);
    const borrowerAuthorization = await authorization(firstBorrower);

    await request(httpServer())
      .post(`/api/v1/items/${item.id}/unavailable-periods`)
      .set('Authorization', borrowerAuthorization)
      .send({ startDate: '2026-08-01', endDate: '2026-08-02' })
      .expect(404);

    const periodResponse = await request(httpServer())
      .post(`/api/v1/items/${item.id}/unavailable-periods`)
      .set('Authorization', ownerAuthorization)
      .send({ startDate: '2026-08-01', endDate: '2026-08-02' })
      .expect(201);
    const period = asRecord(asRecord(periodResponse.body as unknown).data);
    const periodId = String(period.id);

    await request(httpServer())
      .get(`/api/v1/items/${item.id}/unavailable-periods`)
      .set('Authorization', borrowerAuthorization)
      .expect(404);
    const ownerPeriods = await request(httpServer())
      .get(`/api/v1/items/${item.id}/unavailable-periods`)
      .set('Authorization', ownerAuthorization)
      .expect(200);
    expect(asRecord(ownerPeriods.body as unknown).data).toEqual([period]);

    await request(httpServer())
      .delete(`/api/v1/items/${item.id}/unavailable-periods/${periodId}`)
      .set('Authorization', borrowerAuthorization)
      .expect(404);
    await expect(
      prisma.itemUnavailablePeriod.count({ where: { id: periodId } }),
    ).resolves.toBe(1);

    const unavailable = await request(httpServer())
      .get(`/api/v1/items/${item.id}/availability`)
      .query({ startDate: '2026-08-01', endDate: '2026-08-02' })
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(unavailable.body).toMatchObject({
      success: true,
      data: { available: false },
    });

    const available = await request(httpServer())
      .get(`/api/v1/items/${item.id}/availability`)
      .query({ startDate: '2026-08-03', endDate: '2026-08-04' })
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(available.body).toMatchObject({
      success: true,
      data: { available: true },
    });

    await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(item.id, '2026-08-02', '2026-08-03'))
      .expect(409);

    const confirmed = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: firstBorrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-05T00:00:00.000Z'),
        endDate: new Date('2026-08-06T00:00:00.000Z'),
        totalAmount: 1200,
        status: BookingStatus.CONFIRMED,
      },
    });
    await request(httpServer())
      .post(`/api/v1/items/${item.id}/unavailable-periods`)
      .set('Authorization', ownerAuthorization)
      .send({ startDate: '2026-08-06', endDate: '2026-08-07' })
      .expect(409);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: confirmed.id } }),
    ).resolves.toMatchObject({ status: BookingStatus.CONFIRMED });

    await request(httpServer())
      .delete(`/api/v1/items/${item.id}/unavailable-periods/${periodId}`)
      .set('Authorization', ownerAuthorization)
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({ success: true, data: null, error: null });
      });
    await expect(
      prisma.itemUnavailablePeriod.count({ where: { id: periodId } }),
    ).resolves.toBe(0);
  });

  it('creates two concurrent overlapping requests without reserving dates', async () => {
    const { firstBorrower, secondBorrower, item } = await createFixture();
    const [firstAuthorization, secondAuthorization] = await Promise.all([
      authorization(firstBorrower),
      authorization(secondBorrower),
    ]);
    const requestedAt = Date.now();
    const payload = acceptedBookingPayload(item.id, '2026-08-10', '2026-08-11');

    const responses = await Promise.all([
      request(httpServer())
        .post('/api/v1/bookings')
        .set('Authorization', firstAuthorization)
        .send(payload),
      request(httpServer())
        .post('/api/v1/bookings')
        .set('Authorization', secondAuthorization)
        .send(payload),
    ]);

    expect(responses.map((response) => response.status).sort()).toEqual([
      201, 201,
    ]);
    for (const response of responses) {
      const data = asRecord(asRecord(response.body).data);
      const expiresAt = new Date(String(data.expiresAt)).getTime();
      expect(expiresAt).toBeGreaterThanOrEqual(
        requestedAt + BOOKING_PENDING_TTL_MS,
      );
      expect(expiresAt).toBeLessThanOrEqual(
        Date.now() + BOOKING_PENDING_TTL_MS,
      );
    }
    await expect(
      prisma.booking.count({ where: { itemId: item.id } }),
    ).resolves.toBe(2);
    await expect(
      prisma.notificationOutboxEvent.count({
        where: { booking: { itemId: item.id } },
      }),
    ).resolves.toBe(2);
  });

  it('lets the owner close dates while pending and rejects later confirmation', async () => {
    const { owner, firstBorrower, item } = await createFixture();
    const [ownerAuthorization, borrowerAuthorization] = await Promise.all([
      authorization(owner),
      authorization(firstBorrower),
    ]);
    const created = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(item.id, '2026-08-20', '2026-08-21'))
      .expect(201);
    const bookingId = String(asRecord(asRecord(created.body).data).id);

    await request(httpServer())
      .post(`/api/v1/items/${item.id}/unavailable-periods`)
      .set('Authorization', ownerAuthorization)
      .send({ startDate: '2026-08-20', endDate: '2026-08-21' })
      .expect(201);
    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/confirm`)
      .set('Authorization', ownerAuthorization)
      .expect(409)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          success: false,
          data: null,
          error: { code: 'CALENDAR_CONFLICT' },
        });
      });
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: bookingId } }),
    ).resolves.toMatchObject({ status: BookingStatus.PENDING });
  });

  it('keeps booking chat participant-only, idempotent and cursor-paginated', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const [ownerAuthorization, borrowerAuthorization, outsiderAuthorization] =
      await Promise.all([
        authorization(owner),
        authorization(firstBorrower),
        authorization(secondBorrower),
      ]);
    const created = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(item.id, '2026-08-22', '2026-08-23'))
      .expect(201);
    const bookingId = String(asRecord(asRecord(created.body).data).id);
    const firstPayload = {
      clientMessageId: '11111111-1111-4111-8111-111111111141',
      body: '  Можно забрать после 18:00?  ',
    };

    const first = await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', borrowerAuthorization)
      .send(firstPayload)
      .expect(201);
    const repeated = await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', borrowerAuthorization)
      .send(firstPayload)
      .expect(201);
    expect(asRecord(repeated.body).data).toEqual(asRecord(first.body).data);
    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', borrowerAuthorization)
      .send({ ...firstPayload, body: 'Другой текст с тем же UUID' })
      .expect(409)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          error: { code: 'IDEMPOTENCY_KEY_REUSED' },
        });
      });

    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', ownerAuthorization)
      .send({
        clientMessageId: '11111111-1111-4111-8111-111111111142',
        body: 'Да, подойдёт.',
      })
      .expect(201);

    await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', outsiderAuthorization)
      .expect(404);
    const firstPage = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}/messages?limit=2`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const firstPageData = asRecord(asRecord(firstPage.body).data);
    const firstPageItems = firstPageData.items as Record<string, unknown>[];
    expect(firstPageItems).toHaveLength(2);
    const cursor = String(firstPageData.nextCursor);
    expect(cursor).not.toBe('null');

    const secondPage = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}/messages?limit=2&cursor=${cursor}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const secondPageData = asRecord(asRecord(secondPage.body).data);
    const secondPageItems = secondPageData.items as Record<string, unknown>[];
    expect(secondPageItems).toHaveLength(1);
    expect(secondPageData.nextCursor).toBeNull();
    expect(
      [...firstPageItems, ...secondPageItems].map((message) => message.body),
    ).toEqual(
      expect.arrayContaining([
        'Заявка отправлена. Владелец ответит в течение 12 часов.',
        'Можно забрать после 18:00?',
        'Да, подойдёт.',
      ]),
    );
    expect([...firstPageItems, ...secondPageItems]).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          author: 'SYSTEM',
          body: 'Заявка отправлена. Владелец ответит в течение 12 часов.',
        }),
      ]),
    );
    expect(
      JSON.stringify([...firstPageItems, ...secondPageItems]),
    ).not.toContain(owner.id);
    await expect(
      prisma.bookingMessage.count({ where: { bookingId } }),
    ).resolves.toBe(3);
    await expect(
      prisma.notificationOutboxEvent.count({
        where: { bookingId, eventType: 'BOOKING_MESSAGE_CREATED' },
      }),
    ).resolves.toBe(2);
    await expect(outbox.processPending()).resolves.toBeGreaterThan(0);
    await expect(
      prisma.inboxEvent.count({
        where: {
          recipientId: firstBorrower.id,
          bookingId,
          eventType: 'BOOKING_MESSAGE_CREATED',
          readAt: null,
        },
      }),
    ).resolves.toBe(1);
    await request(httpServer())
      .patch(`/api/v1/bookings/${bookingId}/messages/read`)
      .set('Authorization', borrowerAuthorization)
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          success: true,
          data: { updatedCount: 1 },
          error: null,
        });
      });
    await request(httpServer())
      .patch(`/api/v1/bookings/${bookingId}/messages/read`)
      .set('Authorization', borrowerAuthorization)
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({ data: { updatedCount: 0 } });
      });
    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', borrowerAuthorization)
      .send({
        clientMessageId: '11111111-1111-4111-8111-111111111145',
        body: 'Фото в MVP не поддерживается',
        attachmentUrl: 'https://example.test/file.jpg',
      })
      .expect(400);

    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages/block-counterparty`)
      .set('Authorization', borrowerAuthorization)
      .expect(201);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: bookingId } }),
    ).resolves.toMatchObject({
      status: BookingStatus.CANCELLED,
      cancellationReason: 'PARTICIPANT_BLOCKED',
      expiresAt: null,
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', ownerAuthorization)
      .send({
        clientMessageId: '11111111-1111-4111-8111-111111111143',
        body: 'Это сообщение не должно сохраниться',
      })
      .expect(409)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          error: { code: 'BOOKING_CHAT_READ_ONLY' },
        });
      });

    await prisma.booking.update({
      where: { id: bookingId },
      data: { status: BookingStatus.CANCELLED, expiresAt: null },
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/messages`)
      .set('Authorization', borrowerAuthorization)
      .send({
        clientMessageId: '11111111-1111-4111-8111-111111111144',
        body: 'После отмены писать нельзя',
      })
      .expect(409)
      .expect(({ body }) => {
        expect(body).toMatchObject({
          error: { code: 'BOOKING_CHAT_READ_ONLY' },
        });
      });
  });

  it('enforces provisional money ranges at the database boundary', async () => {
    const { owner, firstBorrower, item } = await createFixture();

    await expect(
      prisma.item.update({
        where: { id: item.id },
        data: { pricePerDay: -1 },
      }),
    ).rejects.toThrow();
    const itemWithStoredDeposit = await prisma.item.update({
      where: { id: item.id },
      data: { depositAmount: 1 },
    });
    expect(itemWithStoredDeposit.depositAmount?.toString()).toBe('1');
    await expect(
      prisma.item.update({
        where: { id: item.id },
        data: { depositAmount: 30_000_001 },
      }),
    ).rejects.toThrow();
    await expect(
      prisma.booking.create({
        data: {
          itemId: item.id,
          borrowerId: firstBorrower.id,
          lenderId: owner.id,
          startDate: new Date('2026-08-08T00:00:00.000Z'),
          endDate: new Date('2026-08-08T00:00:00.000Z'),
          totalAmount: 0,
        },
      }),
    ).rejects.toThrow();

    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: firstBorrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-08T00:00:00.000Z'),
        endDate: new Date('2026-08-08T00:00:00.000Z'),
        totalAmount: 600,
      },
    });
    await expect(
      prisma.payment.create({
        data: {
          bookingId: booking.id,
          userId: firstBorrower.id,
          amount: 0,
        },
      }),
    ).rejects.toThrow();
  });

  it('returns one booking for a retried client request ID', async () => {
    const { firstBorrower, item } = await createFixture();
    const borrowerAuthorization = await authorization(firstBorrower);
    const clientRequestId = '11111111-1111-4111-8111-111111111111';
    const payload = acceptedBookingPayload(item.id, '2026-08-12', '2026-08-13');

    const first = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .set('X-Request-Id', clientRequestId)
      .send(payload)
      .expect(201);
    const repeated = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .set('X-Request-Id', clientRequestId)
      .send(payload)
      .expect(201);

    expect(asRecord(asRecord(repeated.body as unknown).data).id).toBe(
      asRecord(asRecord(first.body as unknown).data).id,
    );
    await expect(
      prisma.booking.count({
        where: { borrowerId: firstBorrower.id, clientRequestId },
      }),
    ).resolves.toBe(1);

    await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .set('X-Request-Id', clientRequestId)
      .send({ ...payload, endDate: '2026-08-14' })
      .expect(409);
  });

  it('lets either participant cancel only pending and keeps retry idempotent', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const [ownerAuthorization, borrowerAuthorization, otherAuthorization] =
      await Promise.all([
        authorization(owner),
        authorization(firstBorrower),
        authorization(secondBorrower),
      ]);
    const created = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(item.id, '2026-08-14', '2026-08-15'))
      .expect(201);
    const bookingId = String(asRecord(asRecord(created.body).data).id);

    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/cancel`)
      .set('Authorization', otherAuthorization)
      .expect(404);
    for (const requestId of ['cancel-request-1', 'cancel-request-retry']) {
      await request(httpServer())
        .post(`/api/v1/bookings/${bookingId}/cancel`)
        .set('Authorization', borrowerAuthorization)
        .set('X-Request-Id', requestId)
        .expect(200)
        .expect(({ body }) => {
          expect(asRecord(body as unknown).data).toMatchObject({
            status: BookingStatus.CANCELLED,
            cancellationReason: 'BORROWER_CANCELLED',
          });
        });
    }
    await expect(
      prisma.bookingTransitionHistory.count({
        where: { bookingId, command: 'CANCEL' },
      }),
    ).resolves.toBe(1);
    await expect(
      prisma.notificationOutboxEvent.count({
        where: { bookingId, eventType: 'BOOKING_CANCELLED' },
      }),
    ).resolves.toBe(1);

    const lenderCancelled = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: firstBorrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-16T00:00:00.000Z'),
        endDate: new Date('2026-08-16T00:00:00.000Z'),
        totalAmount: 600,
        status: BookingStatus.PENDING,
        expiresAt: new Date(Date.now() + 60_000),
      },
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${lenderCancelled.id}/cancel`)
      .set('Authorization', ownerAuthorization)
      .expect(200)
      .expect(({ body }) => {
        expect(asRecord(body as unknown).data).toMatchObject({
          status: BookingStatus.CANCELLED,
          cancellationReason: 'LENDER_DECLINED',
        });
      });

    const confirmed = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: firstBorrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-17T00:00:00.000Z'),
        endDate: new Date('2026-08-17T00:00:00.000Z'),
        totalAmount: 600,
        status: BookingStatus.CONFIRMED,
      },
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${confirmed.id}/cancel`)
      .set('Authorization', borrowerAuthorization)
      .expect(409);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: confirmed.id } }),
    ).resolves.toMatchObject({ status: BookingStatus.CONFIRMED });
  });

  it('confirms one competing request and explicitly cancels the other', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const ownerAuthorization = await authorization(owner);
    const bookings = await Promise.all(
      [firstBorrower, secondBorrower].map((borrower) =>
        prisma.booking.create({
          data: {
            itemId: item.id,
            borrowerId: borrower.id,
            lenderId: owner.id,
            startDate: new Date('2026-08-12T00:00:00.000Z'),
            endDate: new Date('2026-08-13T00:00:00.000Z'),
            totalAmount: 1200,
            status: BookingStatus.PENDING,
            expiresAt: new Date('2026-08-01T00:00:00.000Z'),
          },
        }),
      ),
    );

    const responses = await Promise.all(
      bookings.map((booking) =>
        request(httpServer())
          .post(`/api/v1/bookings/${booking.id}/confirm`)
          .set('Authorization', ownerAuthorization),
      ),
    );
    expect(responses.map((response) => response.status).sort()).toEqual([
      200, 409,
    ]);

    const persisted = await prisma.booking.findMany({
      where: { id: { in: bookings.map((booking) => booking.id) } },
      orderBy: { status: 'asc' },
    });
    expect(
      persisted.filter((booking) => booking.status === BookingStatus.CONFIRMED),
    ).toHaveLength(1);
    expect(
      persisted.filter(
        (booking) =>
          booking.status === BookingStatus.CANCELLED &&
          booking.cancellationReason === 'COMPETING_REQUEST_CONFIRMED',
      ),
    ).toHaveLength(1);
  });

  it('idempotently releases an expired pending booking with its reason', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: firstBorrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-15T00:00:00.000Z'),
        endDate: new Date('2026-08-16T00:00:00.000Z'),
        totalAmount: 1200,
        status: BookingStatus.PENDING,
        expiresAt: new Date('2026-07-29T00:00:00.000Z'),
      },
    });
    const now = new Date('2026-07-29T01:00:00.000Z');

    await expect(expiry.expirePending(now)).resolves.toBe(1);
    await expect(expiry.expirePending(now)).resolves.toBe(0);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: booking.id } }),
    ).resolves.toMatchObject({
      status: BookingStatus.CANCELLED,
      cancellationReason: BOOKING_PENDING_TIMEOUT_REASON,
    });
    await expect(
      prisma.bookingTransitionHistory.count({
        where: { bookingId: booking.id, command: 'EXPIRE' },
      }),
    ).resolves.toBe(1);
    await expect(
      prisma.notificationOutboxEvent.count({
        where: {
          bookingId: booking.id,
          eventType: 'BOOKING_PENDING_TIMEOUT',
        },
      }),
    ).resolves.toBe(1);

    await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', await authorization(secondBorrower))
      .send(acceptedBookingPayload(item.id, '2026-08-15', '2026-08-16'))
      .expect(201);
  });

  it('delivers one authorized inbox event and marks it read idempotently', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const borrowerToken = await prisma.devicePushToken.create({
      data: {
        userId: firstBorrower.id,
        installationId: '77777777-7777-4777-8777-777777777777',
        provider: PushTokenProvider.FCM,
        platform: PushPlatform.ANDROID,
        token: 'booking-inbox-test-token',
      },
    });
    const [ownerAuthorization, borrowerAuthorization, otherAuthorization] =
      await Promise.all([
        authorization(owner),
        authorization(firstBorrower),
        authorization(secondBorrower),
      ]);
    const created = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(item.id, '2026-08-20', '2026-08-21'))
      .expect(201);
    const bookingId = String(asRecord(asRecord(created.body).data).id);
    const event = await prisma.notificationOutboxEvent.findFirstOrThrow({
      where: { bookingId },
    });

    await expect(outbox.processPending()).resolves.toBe(1);
    await expect(outbox.processPending()).resolves.toBe(0);
    await expect(
      prisma.inboxEvent.count({ where: { eventId: event.id } }),
    ).resolves.toBe(2);
    await expect(
      prisma.pushDelivery.count({
        where: { eventId: event.id, tokenId: borrowerToken.id },
      }),
    ).resolves.toBe(1);

    for (const actorAuthorization of [
      ownerAuthorization,
      borrowerAuthorization,
    ]) {
      const list = await request(httpServer())
        .get('/api/v1/inbox')
        .set('Authorization', actorAuthorization)
        .expect(200);
      expect(asRecord(list.body).data).toMatchObject([
        {
          eventId: event.id,
          bookingId,
          eventType: 'BOOKING_CREATED',
          readAt: null,
        },
      ]);
    }
    await request(httpServer())
      .get(`/api/v1/inbox/${event.id}`)
      .set('Authorization', otherAuthorization)
      .expect(404);

    const details = await request(httpServer())
      .get(`/api/v1/inbox/${event.id}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const detailsData = asRecord(asRecord(details.body).data);
    const bookingDetails = asRecord(detailsData.booking);
    expect(detailsData).toMatchObject({
      eventId: event.id,
      booking: {
        id: bookingId,
        itemId: item.id,
        totalAmount: 1200,
        status: BookingStatus.PENDING,
      },
    });
    expect(bookingDetails).not.toHaveProperty('borrowerId');
    expect(bookingDetails).not.toHaveProperty('lenderId');
    expect(bookingDetails).not.toHaveProperty('address');

    const firstRead = await request(httpServer())
      .patch(`/api/v1/inbox/${event.id}/read`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const secondRead = await request(httpServer())
      .patch(`/api/v1/inbox/${event.id}/read`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const firstReadData = asRecord(asRecord(firstRead.body).data);
    const secondReadData = asRecord(asRecord(secondRead.body).data);
    expect(firstReadData.readAt).toBeTruthy();
    expect(secondReadData.readAt).toBe(firstReadData.readAt);
  });

  it('recovers the durable outbox after a worker crash without duplicate side effects', async () => {
    const { owner, firstBorrower, item } = await createFixture();
    const borrowerAuthorization = await authorization(firstBorrower);
    const borrowerToken = await prisma.devicePushToken.create({
      data: {
        userId: firstBorrower.id,
        installationId: '88888888-8888-4888-8888-888888888888',
        provider: PushTokenProvider.FCM,
        platform: PushPlatform.ANDROID,
        token: 'outbox-crash-test-token',
      },
    });
    const created = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(item.id, '2026-08-22', '2026-08-23'))
      .expect(201);
    const bookingId = String(asRecord(asRecord(created.body).data).id);
    const event = await prisma.notificationOutboxEvent.findFirstOrThrow({
      where: { bookingId },
    });

    await prisma.$executeRawUnsafe(`
      CREATE FUNCTION test_fail_outbox_processed_update()
      RETURNS trigger AS $$
      BEGIN
        IF NEW."processedAt" IS NOT NULL AND OLD."processedAt" IS NULL THEN
          RAISE EXCEPTION 'simulated worker crash';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);
    await prisma.$executeRawUnsafe(`
      CREATE TRIGGER test_fail_outbox_processed_update
      BEFORE UPDATE OF "processedAt" ON "notification_outbox_events"
      FOR EACH ROW EXECUTE FUNCTION test_fail_outbox_processed_update()
    `);

    try {
      await expect(outbox.processPending()).rejects.toThrow(
        'simulated worker crash',
      );
      await expect(
        prisma.notificationOutboxEvent.findUniqueOrThrow({
          where: { id: event.id },
        }),
      ).resolves.toMatchObject({ processedAt: null });
      await expect(
        prisma.inboxEvent.count({ where: { eventId: event.id } }),
      ).resolves.toBe(0);
      await expect(
        prisma.pushDelivery.count({ where: { eventId: event.id } }),
      ).resolves.toBe(0);
      await expect(
        prisma.payment.count({ where: { bookingId } }),
      ).resolves.toBe(0);
    } finally {
      await prisma.$executeRawUnsafe(`
        DROP TRIGGER IF EXISTS test_fail_outbox_processed_update
        ON "notification_outbox_events"
      `);
      await prisma.$executeRawUnsafe(
        'DROP FUNCTION IF EXISTS test_fail_outbox_processed_update()',
      );
    }

    await expect(outbox.processPending()).resolves.toBe(1);
    await expect(outbox.processPending()).resolves.toBe(0);
    await expect(
      prisma.inboxEvent.count({ where: { eventId: event.id } }),
    ).resolves.toBe(2);
    await expect(
      prisma.pushDelivery.count({
        where: { eventId: event.id, tokenId: borrowerToken.id },
      }),
    ).resolves.toBe(1);
    await expect(
      prisma.notificationOutboxEvent.count({ where: { bookingId } }),
    ).resolves.toBe(1);
    await expect(prisma.payment.count({ where: { bookingId } })).resolves.toBe(
      0,
    );
    await expect(
      prisma.booking.count({ where: { id: bookingId, lenderId: owner.id } }),
    ).resolves.toBe(1);
  });

  it('keeps terms immutable and reveals handover only in allowed participant states', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const [ownerAuthorization, borrowerAuthorization, otherAuthorization] =
      await Promise.all([
        authorization(owner),
        authorization(firstBorrower),
        authorization(secondBorrower),
      ]);
    const created = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send(acceptedBookingPayload(item.id, '2026-08-22', '2026-08-23'))
      .expect(201);
    const bookingId = String(asRecord(asRecord(created.body).data).id);
    const storedBooking = await prisma.booking.findUniqueOrThrow({
      where: { id: bookingId },
      select: { termsSnapshot: true },
    });
    const storedAcceptance = asRecord(
      asRecord(storedBooking.termsSnapshot).acceptance,
    );
    expect(storedAcceptance).toMatchObject({
      actorId: firstBorrower.id,
      method: 'BOOKING_SUBMIT_CHECKBOX',
      offerVersion: 'e2e-approved-offer-1',
      cancellationPolicyVersion: 'e2e-approved-cancellation-1',
    });
    expect(typeof storedAcceptance.acceptedAt).toBe('string');

    await prisma.item.update({
      where: { id: item.id },
      data: {
        title: 'Изменённое название',
        pricePerDay: 999,
        address: 'Москва, новый приватный адрес',
      },
    });

    const pending = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const pendingData = asRecord(asRecord(pending.body).data);
    expect(pendingData).toMatchObject({
      actorRole: 'BORROWER',
      status: BookingStatus.PENDING,
      terms: {
        itemTitle: 'Складной стол',
        pricePerDay: 600,
        days: 2,
        rentalSubtotal: 1200,
        total: 1200,
        currency: 'RUB',
        paymentScenario: 'PAY_ON_HANDOVER',
        platformFee: 0,
        ownerPayout: 1200,
        offerVersion: 'e2e-approved-offer-1',
        cancellationPolicyVersion: 'e2e-approved-cancellation-1',
      },
      handover: null,
      counterpartyContact: null,
    });
    await expect(prisma.payment.count({ where: { bookingId } })).resolves.toBe(
      0,
    );
    expect(JSON.stringify(pendingData)).not.toContain('приватный адрес');

    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/confirm`)
      .set('Authorization', ownerAuthorization)
      .expect(200);
    const confirmed = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(asRecord(confirmed.body).data).toMatchObject({
      status: BookingStatus.CONFIRMED,
      handover: {
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
      counterpartyContact: owner.phone,
    });
    await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}`)
      .set('Authorization', otherAuthorization)
      .expect(404);

    const ownList = await request(httpServer())
      .get('/api/v1/bookings')
      .set('Authorization', ownerAuthorization)
      .expect(200);
    expect(asRecord(ownList.body).data).toMatchObject([
      { id: bookingId, actorRole: 'LENDER' },
    ]);

    await prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: BookingStatus.CANCELLED,
        cancellationReason: 'TEST_CANCELLATION',
      },
    });
    const cancelled = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(asRecord(cancelled.body).data).toMatchObject({
      status: BookingStatus.CANCELLED,
      handover: null,
      counterpartyContact: null,
    });
  });

  it('stores private handover and return evidence with second-party confirmation', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const [ownerAuthorization, borrowerAuthorization, otherAuthorization] =
      await Promise.all([
        authorization(owner),
        authorization(firstBorrower),
        authorization(secondBorrower),
      ]);
    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: firstBorrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-25T00:00:00.000Z'),
        endDate: new Date('2026-08-26T00:00:00.000Z'),
        totalAmount: 1200,
        status: BookingStatus.CONFIRMED,
      },
    });
    const handoverIntent = await prisma.uploadIntent.create({
      data: {
        actorId: owner.id,
        purpose: 'BOOKING_EVIDENCE',
        entityId: booking.id,
        bucket: 'private-test',
        objectKey: `quarantine/booking-evidence/${booking.id}/handover.jpg`,
        contentType: 'image/jpeg',
        sizeBytes: 100,
        expiresAt: new Date('2026-08-01T00:00:00.000Z'),
      },
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/acts`)
      .set('Authorization', ownerAuthorization)
      .send({
        stage: BookingActStage.HANDOVER,
        intentId: handoverIntent.id,
      })
      .expect(400);
    const createdHandover = await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/acts`)
      .set('Authorization', ownerAuthorization)
      .send({
        stage: BookingActStage.HANDOVER,
        intentId: handoverIntent.id,
        readiness: {
          isWorking: true,
          isComplete: true,
          visibleDefects: 'Потёртость на ручке',
        },
      })
      .expect(201);
    const handoverAct = asRecord(asRecord(createdHandover.body).data);
    const replayedHandover = await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/acts`)
      .set('Authorization', ownerAuthorization)
      .send({
        stage: BookingActStage.HANDOVER,
        intentId: handoverIntent.id,
        readiness: {
          isWorking: true,
          isComplete: true,
          visibleDefects: 'Потёртость на ручке',
        },
      })
      .expect(201);
    expect(asRecord(asRecord(replayedHandover.body).data).id).toBe(
      handoverAct.id,
    );

    await request(httpServer())
      .post(
        `/api/v1/bookings/${booking.id}/acts/${String(handoverAct.id)}/confirm`,
      )
      .set('Authorization', ownerAuthorization)
      .expect(409);
    await expect(
      prisma.bookingTransitionHistory.count({
        where: { bookingId: booking.id },
      }),
    ).resolves.toBe(0);
    await request(httpServer())
      .post(
        `/api/v1/bookings/${booking.id}/acts/${String(handoverAct.id)}/confirm`,
      )
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: booking.id } }),
    ).resolves.toMatchObject({ status: BookingStatus.ACTIVE });

    const returnIntent = await prisma.uploadIntent.create({
      data: {
        actorId: firstBorrower.id,
        purpose: 'BOOKING_EVIDENCE',
        entityId: booking.id,
        bucket: 'private-test',
        objectKey: `quarantine/booking-evidence/${booking.id}/return.jpg`,
        contentType: 'image/jpeg',
        sizeBytes: 100,
        expiresAt: new Date('2026-08-01T00:00:00.000Z'),
      },
    });
    const createdReturn = await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/acts`)
      .set('Authorization', borrowerAuthorization)
      .send({
        stage: BookingActStage.RETURN,
        intentId: returnIntent.id,
      })
      .expect(201);
    const returnAct = asRecord(asRecord(createdReturn.body).data);
    await request(httpServer())
      .post(
        `/api/v1/bookings/${booking.id}/acts/${String(returnAct.id)}/confirm`,
      )
      .set('Authorization', ownerAuthorization)
      .expect(200);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: booking.id } }),
    ).resolves.toMatchObject({ status: BookingStatus.RETURNED });
    await request(httpServer())
      .get(`/api/v1/bookings/${booking.id}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200)
      .expect(({ body }) => {
        expect(asRecord(asRecord(body as unknown).data)).toMatchObject({
          status: BookingStatus.RETURNED,
          handover: null,
          counterpartyContact: null,
        });
      });
    const history = await prisma.bookingTransitionHistory.findMany({
      where: { bookingId: booking.id },
      orderBy: { createdAt: 'asc' },
    });
    expect(history).toMatchObject([
      {
        actorId: firstBorrower.id,
        command: 'CONFIRM_HANDOVER',
        oldStatus: BookingStatus.CONFIRMED,
        newStatus: BookingStatus.ACTIVE,
        reason: null,
      },
      {
        actorId: owner.id,
        command: 'CONFIRM_RETURN',
        oldStatus: BookingStatus.ACTIVE,
        newStatus: BookingStatus.RETURNED,
        reason: null,
      },
    ]);
    expect(history.every((transition) => transition.requestId.length > 0)).toBe(
      true,
    );
    await expect(
      prisma.bookingTransitionHistory.update({
        where: { id: history[0].id },
        data: { reason: 'tampered' },
      }),
    ).rejects.toThrow();

    const acts = await request(httpServer())
      .get(`/api/v1/bookings/${booking.id}/acts`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const actsData = asRecord(acts.body).data;
    expect(actsData).toMatchObject([
      {
        stage: BookingActStage.HANDOVER,
        confirmedById: firstBorrower.id,
        readiness: {
          isWorking: true,
          isComplete: true,
          visibleDefects: 'Потёртость на ручке',
          declaration: 'LENDER_SELF_DECLARATION',
        },
        evidence: [{ sha256: 'a'.repeat(64) }],
      },
      {
        stage: BookingActStage.RETURN,
        confirmedById: owner.id,
        readiness: null,
        evidence: [{ sha256: 'a'.repeat(64) }],
      },
    ]);
    await expect(
      prisma.bookingAct.update({
        where: { id: String(handoverAct.id) },
        data: { readinessVisibleDefects: 'Изменено задним числом' },
      }),
    ).rejects.toThrow();
    await request(httpServer())
      .get(`/api/v1/bookings/${booking.id}/acts`)
      .set('Authorization', otherAuthorization)
      .expect(404);
  });

  it('rejects MVP extension explicitly without changing booking or history', async () => {
    const { owner, firstBorrower, secondBorrower, item } =
      await createFixture();
    const [borrowerAuthorization, otherAuthorization] = await Promise.all([
      authorization(firstBorrower),
      authorization(secondBorrower),
    ]);
    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: firstBorrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-27T00:00:00.000Z'),
        endDate: new Date('2026-08-28T00:00:00.000Z'),
        totalAmount: 1200,
        status: BookingStatus.CONFIRMED,
      },
    });

    const rejected = await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/extend`)
      .set('Authorization', borrowerAuthorization)
      .send({ endDate: '2026-08-29' })
      .expect(409);
    expect(rejected.body).toMatchObject({
      error: { code: 'BOOKING_EXTENSION_NOT_SUPPORTED' },
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${booking.id}/extend`)
      .set('Authorization', otherAuthorization)
      .send({ endDate: '2026-08-29' })
      .expect(404);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: booking.id } }),
    ).resolves.toMatchObject({
      endDate: new Date('2026-08-28T00:00:00.000Z'),
      status: BookingStatus.CONFIRMED,
    });
    await expect(
      prisma.bookingTransitionHistory.count({
        where: { bookingId: booking.id },
      }),
    ).resolves.toBe(0);
  });

  afterAll(async () => {
    await app?.close();
    jest.useRealTimers();
  });
});
