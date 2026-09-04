import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingActStage,
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  ItemCondition,
  ItemStatus,
  Prisma,
  UserRole,
  type User,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { configureApp } from '../src/app.setup';
import { DepositDeadlineService } from '../src/payments/deposit-deadline.service';
import { DepositOperationProcessor } from '../src/payments/deposit-operation.processor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetTestState } from './support/test-state';

const FAKE_ENV = {
  PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
  FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '10000000',
  FAKE_SAFE_DEAL_POLICY_VERSION: 'e2e-fake-deposit-v1',
  FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS: '86400',
} as const;

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object');
  }
  return value as Record<string, unknown>;
}

describe('Fake Safe Deal deposit snapshot (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;
  let deadlines: DepositDeadlineService;
  let operations: DepositOperationProcessor;
  const previousEnv = new Map<string, string | undefined>();

  beforeAll(async () => {
    for (const [name, value] of Object.entries(FAKE_ENV)) {
      previousEnv.set(name, process.env[name]);
      process.env[name] = value;
    }

    const { AppModule } =
      jest.requireActual<typeof import('../src/app.module')>(
        '../src/app.module',
      );
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
    jwt = app.get(JwtService);
    prisma = app.get(PrismaService);
    deadlines = app.get(DepositDeadlineService);
    operations = app.get(DepositOperationProcessor);
    await prisma.depositOperation.deleteMany();
    await prisma.bookingDeposit.deleteMany();
    await resetTestState(app);
  });

  it('requires authentication after the fake-mode gate passes', async () => {
    await request(httpServer())
      .post(
        '/api/v1/dev/fake-safe-deal/bookings/11111111-1111-4111-8111-111111111111/checkout',
      )
      .set('Idempotency-Key', 'unauthenticated-checkout')
      .send({ outcome: 'SUCCESS' })
      .expect(401);
  });

  it('gates exact Item deposits and snapshots one pending Booking deposit', async () => {
    const [lender, borrower, category] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990000901', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000902', role: UserRole.USER },
      }),
      prisma.category.create({
        data: {
          name: 'Fake Safe Deal e2e',
          slug: 'fake-safe-deal-e2e',
          isAllowedForListings: true,
          listingPolicy: 'ALLOWED',
        },
      }),
    ]);
    const [lenderAuthorization, borrowerAuthorization] = await Promise.all([
      authorization(lender),
      authorization(borrower),
    ]);
    const baseItem = {
      categoryId: category.id,
      title: 'Проектор с залогом',
      description: 'Исправный проектор для проверки безопасной сделки',
      condition: ItemCondition.GOOD,
      completeness: 'Проектор, кабель и чехол',
      handoverTerms: 'Личная передача после проверки',
      pricePerDay: 100,
      publicArea: 'Центральный округ',
      address: 'Калининград, приватный адрес',
      latitude: 54.71,
      longitude: 20.51,
      ownershipConfirmed: true,
      conditionConfirmed: true,
      completenessConfirmed: true,
      safetyAndMarketplaceRulesAccepted: true,
      listingRulesVersion: '2026-07-28',
    };

    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({ ...baseItem, depositAmountMinor: 3_000_000_001 })
      .expect(400);
    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({ ...baseItem, depositAmount: 1 })
      .expect(400);
    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({ ...baseItem, depositAmount: 0, depositAmountMinor: 5_000 })
      .expect(400);

    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({
        ...baseItem,
        title: 'Залог выше policy maximum',
        depositAmountMinor: 3_000_000_000,
      })
      .expect(400);

    const maximumItemResponse = await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({
        ...baseItem,
        title: 'Максимальная стоимость бронирования',
        pricePerDay: 1_000_000,
        depositAmountMinor: 10_000_000,
      })
      .expect(201);
    const maximumItemId = String(
      asRecord(asRecord(maximumItemResponse.body).data).id,
    );
    await prisma.item.update({
      where: { id: maximumItemId },
      data: { status: ItemStatus.APPROVED },
    });
    const maximumBookingResponse = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send({
        itemId: maximumItemId,
        startDate: '2026-09-10',
        endDate: '2026-10-09',
        offerVersion: 'e2e-approved-offer-1',
        cancellationPolicyVersion: 'e2e-approved-cancellation-1',
        offerAccepted: true,
        rentalRulesAccepted: true,
      })
      .expect(201);
    const maximumBookingId = String(
      asRecord(asRecord(maximumBookingResponse.body).data).id,
    );
    expect(asRecord(asRecord(maximumBookingResponse.body).data)).toMatchObject({
      totalAmount: 30_100_000,
    });
    await expect(
      prisma.booking.findUniqueOrThrow({
        where: { id: maximumBookingId },
        include: { deposit: true },
      }),
    ).resolves.toMatchObject({
      totalAmount: new Prisma.Decimal(30_100_000),
      deposit: {
        amount: new Prisma.Decimal(100_000),
        status: DepositStatus.PENDING,
      },
      termsSnapshot: {
        moneyMinor: {
          rentalSubtotal: 3_000_000_000,
          deposit: 10_000_000,
          platformFee: 30_000_000,
          ownerPayout: 2_970_000_000,
          total: 3_010_000_000,
        },
      },
    });
    await request(httpServer())
      .post(`/api/v1/bookings/${maximumBookingId}/confirm`)
      .set('Authorization', lenderAuthorization)
      .expect(200);
    await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${maximumBookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'maximum-checkout-success')
      .send({ outcome: 'SUCCESS' })
      .expect(200);
    await expect(
      prisma.payment.findUniqueOrThrow({
        where: { bookingId: maximumBookingId },
      }),
    ).resolves.toMatchObject({
      amount: new Prisma.Decimal(30_100_000),
      status: 'SUCCEEDED',
      checkoutUrl: null,
      rawPayload: null,
    });

    const itemResponse = await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({ ...baseItem, depositAmountMinor: 5_000 })
      .expect(201);
    const itemId = String(asRecord(asRecord(itemResponse.body).data).id);
    await prisma.item.update({
      where: { id: itemId },
      data: { status: ItemStatus.APPROVED },
    });

    const bookingResponse = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send({
        itemId,
        startDate: '2026-09-10',
        endDate: '2026-09-10',
        offerVersion: 'e2e-approved-offer-1',
        cancellationPolicyVersion: 'e2e-approved-cancellation-1',
        offerAccepted: true,
        rentalRulesAccepted: true,
      })
      .expect(201);
    const bookingId = String(asRecord(asRecord(bookingResponse.body).data).id);
    expect(asRecord(asRecord(bookingResponse.body).data)).toMatchObject({
      totalAmount: 150,
    });

    const stored = await prisma.booking.findUniqueOrThrow({
      where: { id: bookingId },
      include: { deposit: true },
    });
    expect(stored.totalAmount.toString()).toBe('150');
    expect(stored.deposit).toMatchObject({
      policyVersion: 'e2e-fake-deposit-v1',
      disputeWindowSeconds: 86_400,
      status: DepositStatus.PENDING,
    });
    expect(stored.deposit?.amount.toString()).toBe('50');
    expect(asRecord(stored.termsSnapshot)).toMatchObject({
      paymentScenario: 'FAKE_SAFE_DEAL',
      moneyMinor: {
        pricePerDay: 10_000,
        rentalSubtotal: 10_000,
        deposit: 5_000,
        platformFee: 100,
        ownerPayout: 9_900,
        total: 15_000,
      },
      depositTerms: {
        policyVersion: 'e2e-fake-deposit-v1',
        disputeWindowSeconds: 86_400,
      },
    });

    const participantResponse = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(asRecord(asRecord(participantResponse.body).data)).toMatchObject({
      terms: {
        paymentScenario: 'FAKE_SAFE_DEAL',
        moneyMinor: {
          rentalSubtotal: 10_000,
          deposit: 5_000,
          platformFee: 100,
          ownerPayout: 9_900,
          total: 15_000,
        },
      },
      payment: null,
      deposit: {
        amountMinor: 5_000,
        status: DepositStatus.PENDING,
        refundedMinor: 0,
        releasedToLenderMinor: 0,
        policyVersion: 'e2e-fake-deposit-v1',
        disputeWindowEndsAt: null,
      },
      handover: null,
      counterpartyContact: null,
    });

    await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'pending-checkout')
      .send({ outcome: 'SUCCESS' })
      .expect(409);
    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/confirm`)
      .set('Authorization', lenderAuthorization)
      .expect(200);
    await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', lenderAuthorization)
      .set('Idempotency-Key', 'lender-checkout')
      .send({ outcome: 'SUCCESS' })
      .expect(404);
    await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .send({ outcome: 'SUCCESS' })
      .expect(400);

    const declined = await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'checkout-declined')
      .send({ outcome: 'DECLINE' })
      .expect(200);
    expect(asRecord(asRecord(declined.body).data)).toEqual({
      outcome: 'DECLINED',
      errorCode: 'FAKE_DECLINED',
    });
    const timedOut = await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'checkout-timeout')
      .send({ outcome: 'TIMEOUT' })
      .expect(200);
    expect(asRecord(asRecord(timedOut.body).data)).toEqual({
      outcome: 'TIMEOUT',
    });
    await expect(prisma.payment.count({ where: { bookingId } })).resolves.toBe(
      0,
    );
    await expect(
      prisma.depositOperation.count({ where: { deposit: { bookingId } } }),
    ).resolves.toBe(0);
    await expect(
      prisma.bookingDeposit.findUniqueOrThrow({ where: { bookingId } }),
    ).resolves.toMatchObject({ status: DepositStatus.PENDING });

    const succeeded = await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'checkout-success')
      .send({ outcome: 'SUCCESS' })
      .expect(200);
    const repeated = await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'checkout-success')
      .send({ outcome: 'SUCCESS' })
      .expect(200);
    expect(asRecord(asRecord(repeated.body).data)).toEqual(
      asRecord(asRecord(succeeded.body).data),
    );
    await request(httpServer())
      .post(`/api/v1/dev/fake-safe-deal/bookings/${bookingId}/checkout`)
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'checkout-success')
      .send({ outcome: 'DECLINE' })
      .expect(409);

    const withPayment = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(asRecord(asRecord(withPayment.body).data)).toMatchObject({
      status: 'CONFIRMED',
      payment: { amountMinor: 15_000, status: 'SUCCEEDED' },
      deposit: { amountMinor: 5_000, status: DepositStatus.HELD },
    });
    await expect(prisma.payment.count({ where: { bookingId } })).resolves.toBe(
      1,
    );
    await expect(
      prisma.depositOperation.count({ where: { deposit: { bookingId } } }),
    ).resolves.toBe(1);
    await expect(
      prisma.booking.findUniqueOrThrow({ where: { id: bookingId } }),
    ).resolves.toMatchObject({ status: 'CONFIRMED' });

    await request(httpServer())
      .post(`/api/v1/bookings/${bookingId}/cancel`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    await expect(
      prisma.bookingDeposit.findUniqueOrThrow({ where: { bookingId } }),
    ).resolves.toMatchObject({ status: DepositStatus.RESOLVING });
    await expect(
      prisma.depositOperation.findMany({
        where: { deposit: { bookingId } },
        orderBy: { createdAt: 'asc' },
      }),
    ).resolves.toMatchObject([
      { kind: 'HOLD', status: 'SUCCEEDED', amount: new Prisma.Decimal(50) },
      { kind: 'REFUND', status: 'PENDING', amount: new Prisma.Decimal(50) },
    ]);

    const pendingCancellation = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send({
        itemId,
        startDate: '2026-11-01',
        endDate: '2026-11-01',
        offerVersion: 'e2e-approved-offer-1',
        cancellationPolicyVersion: 'e2e-approved-cancellation-1',
        offerAccepted: true,
        rentalRulesAccepted: true,
      })
      .expect(201);
    const pendingCancellationId = String(
      asRecord(asRecord(pendingCancellation.body).data).id,
    );
    await request(httpServer())
      .post(`/api/v1/bookings/${pendingCancellationId}/confirm`)
      .set('Authorization', lenderAuthorization)
      .expect(200);
    await request(httpServer())
      .post(`/api/v1/bookings/${pendingCancellationId}/cancel`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    await expect(
      prisma.bookingDeposit.findUniqueOrThrow({
        where: { bookingId: pendingCancellationId },
      }),
    ).resolves.toMatchObject({ status: DepositStatus.CANCELLED });
    await expect(
      prisma.depositOperation.count({
        where: { deposit: { bookingId: pendingCancellationId } },
      }),
    ).resolves.toBe(0);

    const noDepositItemResponse = await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({
        ...baseItem,
        title: 'Проектор без залога',
        depositAmountMinor: 0,
      })
      .expect(201);
    const noDepositItemId = String(
      asRecord(asRecord(noDepositItemResponse.body).data).id,
    );
    await prisma.item.update({
      where: { id: noDepositItemId },
      data: { status: ItemStatus.APPROVED },
    });
    const noDepositBookingResponse = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send({
        itemId: noDepositItemId,
        startDate: '2026-11-02',
        endDate: '2026-11-02',
        offerVersion: 'e2e-approved-offer-1',
        cancellationPolicyVersion: 'e2e-approved-cancellation-1',
        offerAccepted: true,
        rentalRulesAccepted: true,
      })
      .expect(201);
    const noDepositBookingId = String(
      asRecord(asRecord(noDepositBookingResponse.body).data).id,
    );
    await request(httpServer())
      .post(`/api/v1/bookings/${noDepositBookingId}/confirm`)
      .set('Authorization', lenderAuthorization)
      .expect(200);
    await request(httpServer())
      .post(
        `/api/v1/dev/fake-safe-deal/bookings/${noDepositBookingId}/checkout`,
      )
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'no-deposit-checkout')
      .send({ outcome: 'SUCCESS' })
      .expect(200);
    await expect(
      prisma.payment.count({ where: { bookingId: noDepositBookingId } }),
    ).resolves.toBe(1);
    await expect(
      prisma.bookingDeposit.count({
        where: { bookingId: noDepositBookingId },
      }),
    ).resolves.toBe(0);
    const noDepositHandover = await prisma.bookingAct.create({
      data: {
        bookingId: noDepositBookingId,
        authorId: lender.id,
        stage: BookingActStage.HANDOVER,
        readinessIsWorking: true,
        readinessIsComplete: true,
        readinessVisibleDefects: 'Нет дефектов',
        readinessDeclaredAt: new Date(),
      },
    });
    await request(httpServer())
      .post(
        `/api/v1/bookings/${noDepositBookingId}/acts/${noDepositHandover.id}/confirm`,
      )
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    const noDepositReturn = await prisma.bookingAct.create({
      data: {
        bookingId: noDepositBookingId,
        authorId: borrower.id,
        stage: BookingActStage.RETURN,
      },
    });
    await request(httpServer())
      .post(
        `/api/v1/bookings/${noDepositBookingId}/acts/${noDepositReturn.id}/confirm`,
      )
      .set('Authorization', lenderAuthorization)
      .expect(200);
    await expect(
      prisma.booking.findUniqueOrThrow({
        where: { id: noDepositBookingId },
      }),
    ).resolves.toMatchObject({ status: BookingStatus.COMPLETED });
    await expect(
      prisma.bookingTransitionHistory.count({
        where: {
          bookingId: noDepositBookingId,
          command: 'COMPLETE_AFTER_RETURN',
        },
      }),
    ).resolves.toBe(1);
    await expect(
      prisma.notificationOutboxEvent.count({
        where: {
          bookingId: noDepositBookingId,
          eventType: 'BOOKING_COMPLETED',
        },
      }),
    ).resolves.toBe(1);

    const settlementBookingResponse = await request(httpServer())
      .post('/api/v1/bookings')
      .set('Authorization', borrowerAuthorization)
      .send({
        itemId,
        startDate: '2026-11-03',
        endDate: '2026-11-03',
        offerVersion: 'e2e-approved-offer-1',
        cancellationPolicyVersion: 'e2e-approved-cancellation-1',
        offerAccepted: true,
        rentalRulesAccepted: true,
      })
      .expect(201);
    const settlementBookingId = String(
      asRecord(asRecord(settlementBookingResponse.body).data).id,
    );
    await request(httpServer())
      .post(`/api/v1/bookings/${settlementBookingId}/confirm`)
      .set('Authorization', lenderAuthorization)
      .expect(200);

    const handoverAct = await prisma.bookingAct.create({
      data: {
        bookingId: settlementBookingId,
        authorId: lender.id,
        stage: BookingActStage.HANDOVER,
        readinessIsWorking: true,
        readinessIsComplete: true,
        readinessVisibleDefects: 'Нет дефектов',
        readinessDeclaredAt: new Date(),
      },
    });
    await request(httpServer())
      .post(
        `/api/v1/bookings/${settlementBookingId}/acts/${handoverAct.id}/confirm`,
      )
      .set('Authorization', borrowerAuthorization)
      .expect(409);
    await request(httpServer())
      .post(
        `/api/v1/dev/fake-safe-deal/bookings/${settlementBookingId}/checkout`,
      )
      .set('Authorization', borrowerAuthorization)
      .set('Idempotency-Key', 'settlement-checkout')
      .send({ outcome: 'SUCCESS' })
      .expect(200);
    await request(httpServer())
      .post(
        `/api/v1/bookings/${settlementBookingId}/acts/${handoverAct.id}/confirm`,
      )
      .set('Authorization', borrowerAuthorization)
      .expect(200);

    const returnAct = await prisma.bookingAct.create({
      data: {
        bookingId: settlementBookingId,
        authorId: borrower.id,
        stage: BookingActStage.RETURN,
      },
    });
    const confirmedReturn = await request(httpServer())
      .post(
        `/api/v1/bookings/${settlementBookingId}/acts/${returnAct.id}/confirm`,
      )
      .set('Authorization', lenderAuthorization)
      .expect(200);
    const returnConfirmedAt = new Date(
      String(asRecord(asRecord(confirmedReturn.body).data).confirmedAt),
    );
    const expectedDeadline = new Date(
      returnConfirmedAt.getTime() + 86_400 * 1000,
    );
    await expect(
      prisma.bookingDeposit.findUniqueOrThrow({
        where: { bookingId: settlementBookingId },
      }),
    ).resolves.toMatchObject({
      status: DepositStatus.HELD,
      disputeWindowEndsAt: expectedDeadline,
    });

    await expect(deadlines.processDue(expectedDeadline)).resolves.toBe(1);
    await expect(deadlines.processDue(expectedDeadline)).resolves.toBe(0);
    await expect(
      operations.processPending(expectedDeadline),
    ).resolves.toBeGreaterThanOrEqual(1);
    await expect(operations.processPending(expectedDeadline)).resolves.toBe(0);

    await expect(
      prisma.booking.findUniqueOrThrow({
        where: { id: settlementBookingId },
        include: { deposit: true },
      }),
    ).resolves.toMatchObject({
      status: BookingStatus.COMPLETED,
      deposit: {
        status: DepositStatus.RESOLVED,
        amount: new Prisma.Decimal(50),
        refundedAmount: new Prisma.Decimal(50),
        releasedToLenderAmount: new Prisma.Decimal(0),
      },
      termsSnapshot: { moneyMinor: { ownerPayout: 9_900 } },
    });
    await expect(
      prisma.depositOperation.findUniqueOrThrow({
        where: {
          idempotencyKey: `deposit:${
            (
              await prisma.bookingDeposit.findUniqueOrThrow({
                where: { bookingId: settlementBookingId },
                select: { id: true },
              })
            ).id
          }:auto-refund`,
        },
      }),
    ).resolves.toMatchObject({
      kind: DepositOperationKind.REFUND,
      status: DepositOperationStatus.SUCCEEDED,
      amount: new Prisma.Decimal(50),
      attempts: 1,
    });
    await expect(
      prisma.bookingTransitionHistory.count({
        where: {
          bookingId: settlementBookingId,
          command: 'COMPLETE_AFTER_DEPOSIT_SETTLED',
        },
      }),
    ).resolves.toBe(1);
    await expect(
      prisma.notificationOutboxEvent.count({
        where: {
          bookingId: settlementBookingId,
          eventType: 'BOOKING_COMPLETED',
        },
      }),
    ).resolves.toBe(1);
  });

  afterAll(async () => {
    try {
      if (app) {
        try {
          await prisma.depositOperation.deleteMany();
          await prisma.bookingDeposit.deleteMany();
          await resetTestState(app);
        } finally {
          await app.close();
        }
      }
    } finally {
      for (const [name, value] of previousEnv) {
        if (value === undefined) {
          delete process.env[name];
        } else {
          process.env[name] = value;
        }
      }
    }
  });

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
});
