import {
  BadRequestException,
  ConflictException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  BookingStatus,
  DepositOperationKind,
  DepositStatus,
  ItemStatus,
  Prisma,
} from '@prisma/client';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { PaymentPolicyService } from '../payments/payment-policy.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  BOOKING_COMPETING_CANCELLATION_REASON,
  BOOKING_MAX_ACTIVE_PENDING,
  BOOKING_MAX_COMPETING_PENDING,
  BOOKING_PENDING_TTL_MS,
  BookingService,
} from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';

function acceptedRequest(
  overrides: Partial<CreateBookingDto> = {},
): CreateBookingDto {
  return {
    itemId: '11111111-1111-4111-8111-111111111111',
    startDate: '2026-08-01',
    endDate: '2026-08-03',
    offerVersion: '2026-08-01.1',
    cancellationPolicyVersion: '2026-08-01.1',
    offerAccepted: true,
    rentalRulesAccepted: true,
    ...overrides,
  };
}

function offlinePaymentPolicy(): PaymentPolicyService {
  const policy = new PaymentPolicyService(new ConfigService());
  policy.onModuleInit();
  return policy;
}

function fakePaymentPolicy(): PaymentPolicyService {
  const policy = new PaymentPolicyService(
    new ConfigService({
      NODE_ENV: 'test',
      PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
      FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '10000000',
      FAKE_SAFE_DEAL_POLICY_VERSION: 'fake-deposit-v1',
      FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS: '86400',
    }),
  );
  policy.onModuleInit();
  return policy;
}

function createService({
  ownerId = 'lender-1',
  hasConflict = false,
  hasCalendarConflict = false,
  hasInteractionBlock = false,
  activePendingCount = 0,
  competingPendingCount = 0,
  depositAmount = null,
  legalTermsVersion = '2026-08-01.1',
  paymentConfig = {},
}: {
  ownerId?: string;
  hasConflict?: boolean;
  hasCalendarConflict?: boolean;
  hasInteractionBlock?: boolean;
  activePendingCount?: number;
  competingPendingCount?: number;
  depositAmount?: Prisma.Decimal | null;
  legalTermsVersion?: string | null;
  paymentConfig?: Record<string, string>;
} = {}) {
  const create = jest.fn(
    ({
      data,
    }: {
      data: {
        itemId: string;
        borrowerId: string;
        lenderId: string;
        startDate: Date;
        endDate: Date;
        totalAmount: Prisma.Decimal;
        status: BookingStatus;
        expiresAt: Date;
        termsSnapshot: Prisma.InputJsonValue;
      };
    }) =>
      Promise.resolve({
        id: 'booking-1',
        ...data,
        disputeOpenedAt: null,
        cancellationReason: null,
        createdAt: new Date('2026-07-29T10:00:00.000Z'),
        updatedAt: new Date('2026-07-29T10:00:00.000Z'),
      }),
  );
  const tx = {
    $executeRaw: jest.fn(() => Promise.resolve(1)),
    item: {
      findFirst: jest.fn(() =>
        Promise.resolve({
          id: 'item-1',
          ownerId,
          title: 'Проектор',
          pricePerDay: new Prisma.Decimal(450),
          depositAmount,
          status: ItemStatus.APPROVED,
          publicArea: 'Центральный округ',
          address: 'Москва, приватный адрес',
          latitude: 55.75,
          longitude: 37.61,
          listingRulesVersion: '2026-07-28',
          updatedAt: new Date('2026-07-29T09:00:00.000Z'),
          owner: { name: 'Владелец' },
        }),
      ),
    },
    itemUnavailablePeriod: {
      findFirst: jest.fn(() =>
        Promise.resolve(
          hasCalendarConflict ? { id: 'unavailable-period-1' } : null,
        ),
      ),
    },
    userBlock: {
      findFirst: jest.fn(() =>
        Promise.resolve(
          hasInteractionBlock ? { id: 'interaction-block-1' } : null,
        ),
      ),
    },
    booking: {
      count: jest.fn(({ where }: { where: { itemId?: string } }) =>
        Promise.resolve(
          where.itemId ? competingPendingCount : activePendingCount,
        ),
      ),
      findUnique: jest.fn(() => Promise.resolve(null)),
      findFirst: jest.fn(() =>
        Promise.resolve(hasConflict ? { id: 'booking-existing' } : null),
      ),
      create,
    },
    bookingDeposit: {
      create: jest.fn(() => Promise.resolve({ id: 'deposit-1' })),
    },
    bookingMessage: {
      create: jest.fn(() => Promise.resolve({ id: 'message-1' })),
      createMany: jest.fn(() => Promise.resolve({ count: 1 })),
    },
    notificationOutboxEvent: {
      create: jest.fn(() => Promise.resolve({ id: 'event-1' })),
    },
    bookingTransitionHistory: {
      create: jest.fn(() => Promise.resolve({ id: 'transition-1' })),
    },
  };
  const prisma = {
    $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
      callback(tx),
    ),
  };
  const config = new ConfigService({
    ...(legalTermsVersion
      ? {
          MARKETPLACE_OFFER_VERSION: legalTermsVersion,
          MARKETPLACE_CANCELLATION_POLICY_VERSION: legalTermsVersion,
        }
      : {}),
    ...paymentConfig,
  });
  const paymentPolicy = new PaymentPolicyService(config);
  paymentPolicy.onModuleInit();

  return {
    service: new BookingService(
      prisma as unknown as PrismaService,
      config,
      paymentPolicy,
    ),
    create,
    createDeposit: tx.bookingDeposit.create,
    transaction: prisma.$transaction,
  };
}

describe('BookingService', () => {
  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(new Date('2026-07-29T12:00:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('takes lender and inclusive price total from backend', async () => {
    const { service, create, createDeposit } = createService();

    const result = await service.create('borrower-1', acceptedRequest());

    expect(result).toMatchObject({
      lenderId: 'lender-1',
      borrowerId: 'borrower-1',
      days: 3,
      totalAmount: 1350,
      status: BookingStatus.PENDING,
    });
    expect(create.mock.calls[0]?.[0].data).toMatchObject({
      lenderId: 'lender-1',
      totalAmount: new Prisma.Decimal(1350),
      status: BookingStatus.PENDING,
      termsSnapshot: {
        itemTitle: 'Проектор',
        pricePerDay: 450,
        days: 3,
        rentalSubtotal: 1350,
        platformFee: 0,
        ownerPayout: 1350,
        total: 1350,
        currency: 'RUB',
        paymentScenario: 'PAY_ON_HANDOVER',
        moneyMinor: {
          pricePerDay: 45_000,
          rentalSubtotal: 135_000,
          deposit: 0,
          platformFee: 0,
          ownerPayout: 135_000,
          total: 135_000,
        },
        depositTerms: null,
        offerVersion: '2026-08-01.1',
        cancellationPolicyVersion: '2026-08-01.1',
        acceptance: {
          actorId: 'borrower-1',
          method: 'BOOKING_SUBMIT_CHECKBOX',
          offerVersion: '2026-08-01.1',
          cancellationPolicyVersion: '2026-08-01.1',
        },
      },
    });
    expect(create.mock.calls[0]?.[0].data.expiresAt).toEqual(
      new Date('2026-07-30T00:00:00.000Z'),
    );
    expect(BOOKING_PENDING_TTL_MS).toBe(12 * 60 * 60 * 1000);
    const termsSnapshot = create.mock.calls[0]?.[0].data.termsSnapshot;
    expect(termsSnapshot).toHaveProperty('acceptance.acceptedAt');
    expect(createDeposit).not.toHaveBeenCalled();
  });

  it('snapshots exact fake Safe Deal amounts and creates one pending deposit', async () => {
    const { service, create, createDeposit } = createService({
      depositAmount: new Prisma.Decimal(50),
      paymentConfig: {
        PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
        FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '5000',
        FAKE_SAFE_DEAL_POLICY_VERSION: 'fake-deposit-v1',
        FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS: '86400',
        NODE_ENV: 'test',
      },
    });

    await expect(
      service.create('borrower-1', acceptedRequest()),
    ).resolves.toMatchObject({ totalAmount: 1400 });
    expect(create.mock.calls[0]?.[0].data).toMatchObject({
      totalAmount: new Prisma.Decimal(1400),
      termsSnapshot: {
        rentalSubtotal: 1350,
        depositAmount: 50,
        platformFee: 13.5,
        ownerPayout: 1336.5,
        total: 1400,
        paymentScenario: 'FAKE_SAFE_DEAL',
        moneyMinor: {
          pricePerDay: 45_000,
          rentalSubtotal: 135_000,
          deposit: 5_000,
          platformFee: 1_350,
          ownerPayout: 133_650,
          total: 140_000,
        },
        depositTerms: {
          policyVersion: 'fake-deposit-v1',
          disputeWindowSeconds: 86_400,
        },
      },
    });
    expect(createDeposit).toHaveBeenCalledWith({
      data: {
        bookingId: 'booking-1',
        amount: new Prisma.Decimal(50),
        policyVersion: 'fake-deposit-v1',
        disputeWindowSeconds: 86_400,
        status: 'PENDING',
      },
    });
  });

  it('rejects missing or stale explicit marketplace terms acceptance before DB', async () => {
    const { service, transaction } = createService();

    await expect(
      service.create('borrower-1', {
        itemId: '11111111-1111-4111-8111-111111111111',
        startDate: '2026-08-01',
        endDate: '2026-08-01',
      }),
    ).rejects.toMatchObject<ConflictException>({
      response: {
        code: 'BOOKING_TERMS_ACCEPTANCE_REQUIRED',
        message: 'Подтвердите актуальные условия аренды',
      },
    });
    await expect(
      service.create(
        'borrower-1',
        acceptedRequest({ offerVersion: 'old-offer-v1' }),
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(transaction).not.toHaveBeenCalled();
  });

  it.each([null, 'draft-2026-08-01'])(
    'keeps booking creation closed for unavailable terms version %s',
    async (legalTermsVersion) => {
      const { service, transaction } = createService({
        legalTermsVersion,
      });

      await expect(
        service.create('borrower-1', {
          itemId: '11111111-1111-4111-8111-111111111111',
          startDate: '2026-08-01',
          endDate: '2026-08-01',
        }),
      ).rejects.toMatchObject<ServiceUnavailableException>({
        response: {
          code: 'BOOKING_LEGAL_GATE_CLOSED',
          message: 'Бронирование временно недоступно',
        },
      });
      expect(transaction).not.toHaveBeenCalled();
    },
  );

  it('rejects self-booking', async () => {
    const { service } = createService({ ownerId: 'borrower-1' });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects a legacy non-zero deposit before creating a booking', async () => {
    const { service, create } = createService({
      depositAmount: new Prisma.Decimal(1000),
    });

    await expect(
      service.create('borrower-1', acceptedRequest()),
    ).rejects.toMatchObject<ConflictException>({
      response: {
        code: 'ITEM_DEPOSIT_NOT_SUPPORTED',
        message: 'Бронирование с залогом пока недоступно',
      },
    });
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects an overlapping active reservation under the item lock', async () => {
    const { service, create } = createService({ hasConflict: true });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects a new booking when either participant blocked the other', async () => {
    const { service, create } = createService({
      hasInteractionBlock: true,
    });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects an owner-blocked calendar period under the item lock', async () => {
    const { service, create } = createService({ hasCalendarConflict: true });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(create).not.toHaveBeenCalled();
  });

  it('limits active pending bookings per borrower', async () => {
    const { service, create } = createService({
      activePendingCount: BOOKING_MAX_ACTIVE_PENDING,
    });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(TooManyRequestsException);
    expect(create).not.toHaveBeenCalled();
  });

  it('limits live overlapping requests per item and period', async () => {
    const { service, create } = createService({
      competingPendingCount: BOOKING_MAX_COMPETING_PENDING,
    });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(TooManyRequestsException);
    expect(create).not.toHaveBeenCalled();
  });

  it('confirms one request and cancels overlapping pending competitors', async () => {
    const pending = {
      id: 'booking-1',
      itemId: 'item-1',
      borrowerId: 'borrower-1',
      lenderId: 'lender-1',
      startDate: new Date('2026-08-01T00:00:00.000Z'),
      endDate: new Date('2026-08-03T00:00:00.000Z'),
      totalAmount: new Prisma.Decimal(1350),
      status: BookingStatus.PENDING,
      expiresAt: new Date('2026-08-01T00:00:00.000Z'),
      cancellationReason: null,
      disputeOpenedAt: null,
      createdAt: new Date('2026-07-29T10:00:00.000Z'),
      updatedAt: new Date('2026-07-29T10:00:00.000Z'),
    };
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const cancelCompetingDeposits = jest.fn().mockResolvedValue({ count: 1 });
    const createMany = jest.fn().mockResolvedValue({ count: 2 });
    const createSystemMessages = jest.fn().mockResolvedValue({ count: 2 });
    const tx = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      itemUnavailablePeriod: {
        findFirst: jest.fn().mockResolvedValue(null),
      },
      booking: {
        findFirst: jest.fn(({ where }: { where: { status?: unknown } }) =>
          Promise.resolve(where.status ? null : pending),
        ),
        findMany: jest.fn().mockResolvedValue([{ id: 'booking-2' }]),
        update: jest.fn().mockResolvedValue({
          ...pending,
          status: BookingStatus.CONFIRMED,
          expiresAt: null,
        }),
        updateMany,
      },
      bookingDeposit: { updateMany: cancelCompetingDeposits },
      bookingMessage: { createMany: createSystemMessages },
      notificationOutboxEvent: { createMany },
      bookingTransitionHistory: {
        createMany: jest.fn().mockResolvedValue({ count: 2 }),
      },
    };
    const prisma = {
      $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
        callback(tx),
      ),
    };
    const service = new BookingService(
      prisma as unknown as PrismaService,
      new ConfigService(),
      offlinePaymentPolicy(),
    );

    await expect(
      service.confirm('lender-1', 'booking-1'),
    ).resolves.toMatchObject({
      status: BookingStatus.CONFIRMED,
      days: 3,
      totalAmount: 1350,
    });
    expect(updateMany).toHaveBeenCalledWith({
      where: {
        id: { in: ['booking-2'] },
        status: BookingStatus.PENDING,
      },
      data: {
        status: BookingStatus.CANCELLED,
        cancellationReason: BOOKING_COMPETING_CANCELLATION_REASON,
        expiresAt: null,
      },
    });
    expect(cancelCompetingDeposits).toHaveBeenCalledWith({
      where: {
        bookingId: { in: ['booking-2'] },
        status: 'PENDING',
      },
      data: { status: 'CANCELLED' },
    });
    expect(createMany).toHaveBeenCalledTimes(1);
    expect(createSystemMessages).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({ bookingId: 'booking-1' }),
        expect.objectContaining({ bookingId: 'booking-2' }),
      ],
    });
    expect(createMany).toHaveBeenCalledWith({
      data: [
        {
          bookingId: 'booking-1',
          eventType: 'BOOKING_CONFIRMED',
          deduplicationKey: 'booking:booking-1:BOOKING_CONFIRMED',
        },
        {
          bookingId: 'booking-2',
          eventType: 'BOOKING_COMPETING_CANCELLED',
          deduplicationKey: 'booking:booking-2:BOOKING_COMPETING_CANCELLED',
        },
      ],
      skipDuplicates: true,
    });
  });

  it.each([
    { booking: null, error: NotFoundException },
    {
      booking: {
        id: 'booking-1',
        itemId: 'item-1',
        status: BookingStatus.CONFIRMED,
        expiresAt: null,
      },
      error: ConflictException,
    },
  ])(
    'rejects an invalid confirmation actor or state',
    async ({ booking, error }) => {
      const tx = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        booking: { findFirst: jest.fn().mockResolvedValue(booking) },
      };
      const prisma = {
        $transaction: jest.fn(
          <T>(callback: (client: typeof tx) => Promise<T>) => callback(tx),
        ),
      };
      const service = new BookingService(
        prisma as unknown as PrismaService,
        new ConfigService(),
        offlinePaymentPolicy(),
      );

      await expect(
        service.confirm('lender-1', 'booking-1'),
      ).rejects.toBeInstanceOf(error);
    },
  );

  it.each([
    [DepositStatus.PENDING, DepositStatus.CANCELLED, false],
    [DepositStatus.HELD, DepositStatus.RESOLVING, true],
  ] as const)(
    'cancels a confirmed fake booking with %s deposit',
    async (depositStatus, expectedStatus, expectsRefund) => {
      const booking = {
        id: 'booking-1',
        itemId: 'item-1',
        borrowerId: 'borrower-1',
        lenderId: 'lender-1',
        startDate: new Date('2026-08-01T00:00:00.000Z'),
        endDate: new Date('2026-08-01T00:00:00.000Z'),
        totalAmount: new Prisma.Decimal(150),
        status: BookingStatus.CONFIRMED,
        expiresAt: null,
        cancellationReason: null,
        disputeOpenedAt: null,
        termsSnapshot: {
          itemTitle: 'Проектор',
          lenderId: 'lender-1',
          lenderDisplayName: null,
          pricePerDay: 100,
          days: 1,
          rentalSubtotal: 100,
          depositAmount: 50,
          platformFee: 1,
          ownerPayout: 99,
          total: 150,
          currency: 'RUB',
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
            policyVersion: 'fake-deposit-v1',
            disputeWindowSeconds: 86_400,
          },
          handover: {
            area: 'Центр',
            address: 'Приватный адрес',
            latitude: 54.7,
            longitude: 20.5,
          },
          listingVersion: 'listing-v1',
          offerVersion: 'offer-v1',
          cancellationPolicyVersion: 'rules-v1',
          acceptance: {
            actorId: 'borrower-1',
            acceptedAt: '2026-07-29T10:00:00.000Z',
            method: 'BOOKING_SUBMIT_CHECKBOX',
            offerVersion: 'offer-v1',
            cancellationPolicyVersion: 'rules-v1',
          },
        },
        deposit: {
          id: 'deposit-1',
          amount: new Prisma.Decimal(50),
          status: depositStatus,
        },
        createdAt: new Date('2026-07-29T10:00:00.000Z'),
        updatedAt: new Date('2026-07-29T10:00:00.000Z'),
      };
      const updateDeposit = jest.fn().mockResolvedValue({ id: 'deposit-1' });
      const createOperation = jest.fn(
        (args: { data: Record<string, unknown> }) => {
          void args;
          return Promise.resolve({ id: 'operation-1' });
        },
      );
      const tx = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        booking: {
          findFirst: jest.fn().mockResolvedValue(booking),
          update: jest.fn().mockResolvedValue({
            ...booking,
            status: BookingStatus.CANCELLED,
            cancellationReason: 'BORROWER_CANCELLED',
          }),
        },
        bookingDeposit: { update: updateDeposit },
        depositOperation: { create: createOperation },
        bookingMessage: { create: jest.fn().mockResolvedValue({}) },
        bookingTransitionHistory: { create: jest.fn().mockResolvedValue({}) },
        notificationOutboxEvent: { create: jest.fn().mockResolvedValue({}) },
      };
      const prisma = {
        $transaction: jest.fn(
          <T>(callback: (client: typeof tx) => Promise<T>) => callback(tx),
        ),
      };
      const service = new BookingService(
        prisma as unknown as PrismaService,
        new ConfigService(),
        fakePaymentPolicy(),
      );

      await expect(
        service.cancelPending('borrower-1', 'booking-1'),
      ).resolves.toMatchObject({ status: BookingStatus.CANCELLED });
      expect(updateDeposit).toHaveBeenCalledWith({
        where: { id: 'deposit-1' },
        data: { status: expectedStatus },
      });
      if (expectsRefund) {
        expect(createOperation.mock.calls[0]?.[0].data).toMatchObject({
          depositId: 'deposit-1',
          kind: DepositOperationKind.REFUND,
          amount: new Prisma.Decimal(50),
          idempotencyKey: 'deposit:deposit-1:pre-handover-refund',
        });
      } else {
        expect(createOperation).not.toHaveBeenCalled();
      }
    },
  );
});
