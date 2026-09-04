import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  DepositStatus,
  ItemCondition,
  ItemStatus,
  UserRole,
  type User,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { configureApp } from '../src/app.setup';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetTestState } from './support/test-state';

const FAKE_ENV = {
  PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
  FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '3000000000',
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
    await prisma.depositOperation.deleteMany();
    await prisma.bookingDeposit.deleteMany();
    await resetTestState(app);
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

    const maximumItemResponse = await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', lenderAuthorization)
      .send({
        ...baseItem,
        title: 'Максимальный залог',
        depositAmountMinor: 3_000_000_000,
      })
      .expect(201);
    expect(asRecord(asRecord(maximumItemResponse.body).data)).toMatchObject({
      depositAmount: 30_000_000,
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

    await prisma.payment.create({
      data: {
        bookingId,
        userId: borrower.id,
        amount: 150,
      },
    });
    const withPayment = await request(httpServer())
      .get(`/api/v1/bookings/${bookingId}`)
      .set('Authorization', borrowerAuthorization)
      .expect(200);
    expect(asRecord(asRecord(withPayment.body).data)).toMatchObject({
      payment: { amountMinor: 15_000, status: 'PENDING' },
    });
  });

  afterAll(async () => {
    if (app) {
      await prisma.depositOperation.deleteMany();
      await prisma.bookingDeposit.deleteMany();
      await resetTestState(app);
      await app.close();
    }
    for (const [name, value] of previousEnv) {
      if (value === undefined) {
        delete process.env[name];
      } else {
        process.env[name] = value;
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
