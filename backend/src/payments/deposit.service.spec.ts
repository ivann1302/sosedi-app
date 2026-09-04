import { ConflictException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  PaymentStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  assertDepositSettledForCompletionOrPayout,
  DepositService,
} from './deposit.service';
import { FakeSafeDealProvider } from './fake-safe-deal.provider';
import { PaymentPolicyService } from './payment-policy.service';

const fakeConfig = {
  NODE_ENV: 'test',
  PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
  FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '10000000',
  FAKE_SAFE_DEAL_POLICY_VERSION: 'fake-deposit-v1',
  FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS: '86400',
};

function policy(values: Record<string, string> = fakeConfig) {
  const service = new PaymentPolicyService(new ConfigService(values));
  service.onModuleInit();
  return service;
}

function confirmedBooking(withDeposit = true) {
  return {
    id: 'booking-1',
    borrowerId: 'borrower-1',
    lenderId: 'lender-1',
    startDate: new Date('2026-09-10T00:00:00.000Z'),
    endDate: new Date('2026-09-10T00:00:00.000Z'),
    totalAmount: new Prisma.Decimal(150),
    status: BookingStatus.CONFIRMED,
    termsSnapshot: {
      itemTitle: 'Проектор',
      lenderId: 'lender-1',
      lenderDisplayName: 'Лена',
      pricePerDay: 100,
      days: 1,
      rentalSubtotal: 100,
      depositAmount: withDeposit ? 50 : null,
      platformFee: 1,
      ownerPayout: 99,
      total: withDeposit ? 150 : 100,
      currency: 'RUB',
      paymentScenario: 'FAKE_SAFE_DEAL',
      moneyMinor: {
        pricePerDay: 10_000,
        rentalSubtotal: 10_000,
        deposit: withDeposit ? 5_000 : 0,
        platformFee: 100,
        ownerPayout: 9_900,
        total: withDeposit ? 15_000 : 10_000,
      },
      depositTerms: withDeposit
        ? { policyVersion: 'fake-deposit-v1', disputeWindowSeconds: 86_400 }
        : null,
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
        acceptedAt: '2026-09-04T00:00:00.000Z',
        method: 'BOOKING_SUBMIT_CHECKBOX',
        offerVersion: 'offer-v1',
        cancellationPolicyVersion: 'rules-v1',
      },
    },
    payment: null,
    deposit: withDeposit
      ? {
          id: 'deposit-1',
          amount: new Prisma.Decimal(50),
          currency: 'RUB',
          status: DepositStatus.PENDING,
        }
      : null,
  };
}

function createService(booking = confirmedBooking()) {
  const createPayment = jest.fn((args: { data: Record<string, unknown> }) => {
    void args;
    return Promise.resolve({ id: 'payment-1' });
  });
  const updateDeposit = jest.fn(
    (args: { where: { id: string }; data: { status: DepositStatus } }) => {
      void args;
      return Promise.resolve({ id: 'deposit-1' });
    },
  );
  const createOperation = jest.fn((args: { data: Record<string, unknown> }) => {
    void args;
    return Promise.resolve({ id: 'operation-1' });
  });
  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    booking: { findUnique: jest.fn().mockResolvedValue(booking) },
    payment: { create: createPayment },
    bookingDeposit: { update: updateDeposit },
    depositOperation: { create: createOperation },
  };
  const prisma = {
    $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
      callback(tx),
    ),
  };
  return {
    service: new DepositService(
      prisma as unknown as PrismaService,
      policy(),
      new FakeSafeDealProvider(),
    ),
    createPayment,
    updateDeposit,
    createOperation,
    transaction: prisma.$transaction,
  };
}

describe('DepositService fake checkout', () => {
  it.each(['DECLINE', 'TIMEOUT'] as const)(
    'does not persist successful money state for %s',
    async (outcome) => {
      const { service, createPayment, updateDeposit, createOperation } =
        createService();

      await expect(
        service.checkout('borrower-1', 'booking-1', outcome, `key-${outcome}`),
      ).resolves.toMatchObject({
        outcome: outcome === 'DECLINE' ? 'DECLINED' : 'TIMEOUT',
      });
      expect(createPayment).not.toHaveBeenCalled();
      expect(updateDeposit).not.toHaveBeenCalled();
      expect(createOperation).not.toHaveBeenCalled();
    },
  );

  it('atomically records one successful payment and deposit hold', async () => {
    const { service, createPayment, updateDeposit, createOperation } =
      createService();

    const result = await service.checkout(
      'borrower-1',
      'booking-1',
      'SUCCESS',
      'checkout-key-1',
    );
    expect(result.outcome).toBe('SUCCEEDED');
    if (result.outcome !== 'SUCCEEDED') {
      throw new Error('Expected successful fake checkout');
    }
    expect(createPayment.mock.calls[0]?.[0].data).toEqual({
      bookingId: 'booking-1',
      userId: 'borrower-1',
      amount: new Prisma.Decimal(150),
      status: PaymentStatus.SUCCEEDED,
      yookassaPaymentId: result.providerOperationId,
    });
    const paymentData = createPayment.mock.calls[0]?.[0].data;
    expect(paymentData).not.toHaveProperty('checkoutUrl');
    expect(paymentData).not.toHaveProperty('rawPayload');
    expect(updateDeposit).toHaveBeenCalledWith({
      where: { id: 'deposit-1' },
      data: { status: DepositStatus.HELD },
    });
    expect(createOperation.mock.calls[0]?.[0].data).toMatchObject({
      depositId: 'deposit-1',
      kind: DepositOperationKind.HOLD,
      amount: new Prisma.Decimal(50),
      status: DepositOperationStatus.SUCCEEDED,
      idempotencyKey: 'deposit:deposit-1:hold',
      attempts: 1,
    });
  });

  it('creates no deposit state for a no-deposit checkout', async () => {
    const booking = confirmedBooking(false);
    booking.totalAmount = new Prisma.Decimal(100);
    const { service, updateDeposit, createOperation } = createService(booking);

    await expect(
      service.checkout('borrower-1', 'booking-1', 'SUCCESS', 'checkout-key-1'),
    ).resolves.toMatchObject({ outcome: 'SUCCEEDED' });
    expect(updateDeposit).not.toHaveBeenCalled();
    expect(createOperation).not.toHaveBeenCalled();
  });

  it('rejects a non-borrower and a booking outside CONFIRMED', async () => {
    const outsider = createService();
    await expect(
      outsider.service.checkout('lender-1', 'booking-1', 'SUCCESS', 'key-1'),
    ).rejects.toBeInstanceOf(NotFoundException);

    const pending = confirmedBooking();
    pending.status = BookingStatus.PENDING;
    await expect(
      createService(pending).service.checkout(
        'borrower-1',
        'booking-1',
        'SUCCESS',
        'key-2',
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('checks fake policy before opening a transaction', async () => {
    const transaction = jest.fn();
    const service = new DepositService(
      { $transaction: transaction } as unknown as PrismaService,
      policy({}),
      new FakeSafeDealProvider(),
    );

    await expect(
      service.checkout('borrower-1', 'booking-1', 'SUCCESS', 'key-1'),
    ).rejects.toThrow('FAKE_SAFE_DEAL_REQUIRED');
    expect(transaction).not.toHaveBeenCalled();
  });
});

describe('DepositService local completion command', () => {
  const now = new Date('2026-09-04T12:00:00.000Z');

  function completionService(status: DepositStatus, refunded = 50) {
    const booking = {
      id: 'booking-1',
      status: BookingStatus.RETURNED,
      financialDispute: null,
      deposit: {
        id: 'deposit-1',
        amount: new Prisma.Decimal(50),
        refundedAmount: new Prisma.Decimal(refunded),
        releasedToLenderAmount: new Prisma.Decimal(0),
        status,
        disputeWindowEndsAt: new Date('2026-09-04T11:59:59.000Z'),
      },
    };
    const updateBooking = jest.fn().mockImplementation(() => {
      booking.status = BookingStatus.COMPLETED;
      return Promise.resolve({ count: 1 });
    });
    const history: Array<Record<string, unknown>> = [];
    const outbox: Array<Record<string, unknown>> = [];
    const tx = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      booking: {
        findUnique: jest.fn().mockResolvedValue(booking),
        updateMany: updateBooking,
      },
      bookingTransitionHistory: {
        create: jest
          .fn()
          .mockImplementation(({ data }: { data: Record<string, unknown> }) => {
            history.push(data);
            return Promise.resolve(data);
          }),
      },
      notificationOutboxEvent: {
        create: jest
          .fn()
          .mockImplementation(({ data }: { data: Record<string, unknown> }) => {
            outbox.push(data);
            return Promise.resolve(data);
          }),
      },
    };
    const prisma = {
      $transaction: jest.fn(
        (callback: (client: typeof tx) => Promise<unknown>) => callback(tx),
      ),
    };
    return {
      service: new DepositService(
        prisma as unknown as PrismaService,
        policy(),
        new FakeSafeDealProvider(),
      ),
      booking,
      history,
      outbox,
    };
  }

  it('requires exact settled sums in the exported completion/payout guard', () => {
    expect(() =>
      assertDepositSettledForCompletionOrPayout({
        status: DepositStatus.RESOLVED,
        amount: new Prisma.Decimal(50),
        refundedAmount: new Prisma.Decimal(40),
        releasedToLenderAmount: new Prisma.Decimal(0),
      }),
    ).toThrow(ConflictException);
    expect(() =>
      assertDepositSettledForCompletionOrPayout({
        status: DepositStatus.RESOLVED,
        amount: new Prisma.Decimal(50),
        refundedAmount: new Prisma.Decimal(40),
        releasedToLenderAmount: new Prisma.Decimal(10),
      }),
    ).not.toThrow();
  });

  it('completes only a returned booking with fully resolved deposit', async () => {
    const settled = completionService(DepositStatus.RESOLVED);

    await expect(
      settled.service.completeAfterDepositSettled('booking-1', now),
    ).resolves.toBe(1);
    expect(settled.booking.status).toBe(BookingStatus.COMPLETED);
    expect(settled.history).toEqual([
      expect.objectContaining({
        bookingId: 'booking-1',
        actorId: null,
        actorType: 'SYSTEM',
        command: 'COMPLETE_AFTER_DEPOSIT_SETTLED',
        oldStatus: BookingStatus.RETURNED,
        newStatus: BookingStatus.COMPLETED,
      }),
    ]);
    expect(settled.outbox).toEqual([
      expect.objectContaining({
        bookingId: 'booking-1',
        eventType: 'BOOKING_COMPLETED',
      }),
    ]);

    const unresolved = completionService(DepositStatus.RESOLVING, 0);
    await expect(
      unresolved.service.completeAfterDepositSettled('booking-1', now),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(unresolved.history).toHaveLength(0);
  });
});
