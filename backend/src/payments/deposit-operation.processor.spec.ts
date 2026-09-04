import { ConfigService } from '@nestjs/config';
import {
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DepositOperationProcessor } from './deposit-operation.processor';
import {
  FakeSafeDealProvider,
  type ProviderOperationResult,
} from './fake-safe-deal.provider';
import { PaymentPolicyService } from './payment-policy.service';

const now = new Date('2026-09-04T12:00:00.000Z');

type OperationUpdateData = {
  status?: DepositOperationStatus;
  attempts?: { increment: number };
  processingUntil?: Date | null;
  nextAttemptAt?: Date;
  providerOperationId?: string;
  providerErrorCode?: string | null;
  completedAt?: Date;
};

type OperationUpdateArgs = {
  where: {
    status: DepositOperationStatus;
    processingUntil?: Date;
  };
  data: OperationUpdateData;
};

type DepositUpdateData = {
  status?: DepositStatus;
  refundedAmount?: { increment: Prisma.Decimal };
  releasedToLenderAmount?: { increment: Prisma.Decimal };
};

function fakePolicy(): PaymentPolicyService {
  const service = new PaymentPolicyService(
    new ConfigService({
      NODE_ENV: 'test',
      PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
      FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '10000000',
      FAKE_SAFE_DEAL_POLICY_VERSION: 'test-policy',
      FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS: '86400',
    }),
  );
  service.onModuleInit();
  return service;
}

function createProcessor(
  result: ProviderOperationResult | Promise<ProviderOperationResult>,
) {
  const operation = {
    id: 'operation-1',
    depositId: 'deposit-1',
    kind: DepositOperationKind.REFUND,
    amount: new Prisma.Decimal(50),
    status: DepositOperationStatus.PENDING,
    idempotencyKey: 'deposit:deposit-1:auto-refund',
    providerOperationId: null as string | null,
    providerErrorCode: null as string | null,
    attempts: 0,
    nextAttemptAt: now,
    processingUntil: null as Date | null,
    completedAt: null as Date | null,
  };
  const deposit = {
    id: 'deposit-1',
    bookingId: 'booking-1',
    amount: new Prisma.Decimal(50),
    currency: 'RUB',
    status: DepositStatus.RESOLVING,
    disputeWindowEndsAt: new Date('2026-09-04T11:59:59.000Z'),
    refundedAmount: new Prisma.Decimal(0),
    releasedToLenderAmount: new Prisma.Decimal(0),
  };
  const booking: { id: string; status: BookingStatus } = {
    id: 'booking-1',
    status: BookingStatus.RETURNED,
  };
  const audit: Array<Record<string, unknown>> = [];
  const history: Array<Record<string, unknown>> = [];
  const outbox: Array<Record<string, unknown>> = [];
  let inTransaction = false;
  let failCompletion = false;

  const provider = {
    executeDepositOperation: jest.fn().mockImplementation(() => {
      if (inTransaction) {
        throw new Error('provider called inside transaction');
      }
      return Promise.resolve(result);
    }),
  };
  function operationRecord() {
    return { ...operation, deposit: { ...deposit } };
  }

  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    depositOperation: {
      findUnique: jest
        .fn()
        .mockImplementation(() => Promise.resolve(operationRecord())),
      findFirst: jest.fn().mockResolvedValue(null),
      updateMany: jest
        .fn()
        .mockImplementation(({ where, data }: OperationUpdateArgs) => {
          if (
            where.status !== DepositOperationStatus.PENDING ||
            operation.status !== DepositOperationStatus.PENDING
          ) {
            return Promise.resolve({ count: 0 });
          }
          if (data.attempts) {
            if (
              operation.nextAttemptAt > now ||
              (operation.processingUntil && operation.processingUntil > now)
            ) {
              return Promise.resolve({ count: 0 });
            }
            operation.processingUntil = data.processingUntil ?? null;
            operation.attempts += 1;
            return Promise.resolve({ count: 1 });
          }
          if (
            where.processingUntil &&
            operation.processingUntil?.getTime() !==
              new Date(where.processingUntil).getTime()
          ) {
            return Promise.resolve({ count: 0 });
          }
          if (data.status) {
            operation.status = data.status;
          }
          if ('processingUntil' in data) {
            operation.processingUntil = data.processingUntil ?? null;
          }
          if (data.nextAttemptAt) {
            operation.nextAttemptAt = data.nextAttemptAt;
          }
          if (data.providerOperationId) {
            operation.providerOperationId = data.providerOperationId;
          }
          if ('providerErrorCode' in data) {
            operation.providerErrorCode = data.providerErrorCode ?? null;
          }
          if (data.completedAt) {
            operation.completedAt = data.completedAt;
          }
          return Promise.resolve({ count: 1 });
        }),
    },
    bookingDeposit: {
      update: jest
        .fn()
        .mockImplementation(({ data }: { data: DepositUpdateData }) => {
          if (data.refundedAmount?.increment) {
            deposit.refundedAmount = deposit.refundedAmount.add(
              data.refundedAmount.increment,
            );
          }
          if (data.releasedToLenderAmount?.increment) {
            deposit.releasedToLenderAmount = deposit.releasedToLenderAmount.add(
              data.releasedToLenderAmount.increment,
            );
          }
          if (data.status) {
            deposit.status = data.status;
          }
          return Promise.resolve({ ...deposit });
        }),
    },
    booking: {
      findUnique: jest.fn().mockImplementation(() =>
        Promise.resolve({
          ...booking,
          deposit: { ...deposit },
          financialDispute: null,
        }),
      ),
      updateMany: jest.fn().mockImplementation(() => {
        booking.status = BookingStatus.COMPLETED;
        return Promise.resolve({ count: 1 });
      }),
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
          if (failCompletion) {
            throw new Error('outbox unavailable');
          }
          outbox.push(data);
          return Promise.resolve(data);
        }),
    },
    adminAuditLog: {
      create: jest
        .fn()
        .mockImplementation(({ data }: { data: Record<string, unknown> }) => {
          audit.push(data);
          return Promise.resolve(data);
        }),
    },
  };
  const prisma = {
    depositOperation: {
      findMany: jest
        .fn()
        .mockImplementation(() =>
          Promise.resolve(
            operation.status === DepositOperationStatus.PENDING &&
              operation.nextAttemptAt <= now &&
              (!operation.processingUntil || operation.processingUntil <= now)
              ? [{ id: operation.id }]
              : [],
          ),
        ),
    },
    $transaction: jest.fn(
      async (callback: (client: typeof tx) => Promise<unknown>) => {
        const operationBefore = { ...operation };
        const depositBefore = { ...deposit };
        const bookingStatusBefore = booking.status;
        const auditLength = audit.length;
        const historyLength = history.length;
        const outboxLength = outbox.length;
        inTransaction = true;
        try {
          return await callback(tx);
        } catch (error) {
          Object.assign(operation, operationBefore);
          Object.assign(deposit, depositBefore);
          booking.status = bookingStatusBefore;
          audit.splice(auditLength);
          history.splice(historyLength);
          outbox.splice(outboxLength);
          throw error;
        } finally {
          inTransaction = false;
        }
      },
    ),
  };
  return {
    processor: new DepositOperationProcessor(
      prisma as unknown as PrismaService,
      fakePolicy(),
      provider as unknown as FakeSafeDealProvider,
    ),
    operation,
    deposit,
    audit,
    booking,
    history,
    outbox,
    provider: provider.executeDepositOperation,
    failCompletion: () => {
      failCompletion = true;
    },
  };
}

describe('DepositOperationProcessor', () => {
  it('keeps timeouts pending and schedules bounded backoff', async () => {
    const { processor, operation } = createProcessor({ outcome: 'TIMEOUT' });

    await expect(processor.processPending(now)).resolves.toBe(1);
    expect(operation).toMatchObject({
      status: DepositOperationStatus.PENDING,
      attempts: 1,
      processingUntil: null,
      nextAttemptAt: new Date('2026-09-04T12:00:30.000Z'),
    });
  });

  it('caps timeout backoff after repeated attempts', async () => {
    const { processor, operation } = createProcessor({ outcome: 'TIMEOUT' });
    operation.attempts = 99;

    await processor.processPending(now);
    expect(operation.nextAttemptAt).toEqual(
      new Date('2026-09-04T13:00:00.000Z'),
    );
  });

  it('records a definitive decline without provider details or personal data', async () => {
    const { processor, operation, audit } = createProcessor({
      outcome: 'DECLINED',
      errorCode: 'FAKE_DECLINED',
    });

    await expect(processor.processPending(now)).resolves.toBe(1);
    expect(operation).toMatchObject({
      status: DepositOperationStatus.FAILED,
      providerErrorCode: 'FAKE_DECLINED',
      processingUntil: null,
      completedAt: now,
    });
    expect(audit).toEqual([
      {
        adminId: null,
        action: 'DEPOSIT_OPERATION_PROVIDER_DECLINED',
        entityType: 'DepositOperation',
        entityId: 'operation-1',
        reason: 'FAKE_DECLINED',
        metadata: { kind: DepositOperationKind.REFUND, attempts: 1 },
      },
    ]);
  });

  it('applies success once, resolves the exact sum, and invokes local completion', async () => {
    const {
      processor,
      operation,
      deposit,
      provider,
      booking,
      history,
      outbox,
    } = createProcessor({
      outcome: 'SUCCEEDED',
      providerOperationId: 'fake_deposit_refund-1',
    });

    await expect(processor.processPending(now)).resolves.toBe(1);
    await expect(processor.processPending(now)).resolves.toBe(0);

    expect(provider).toHaveBeenCalledTimes(1);
    expect(operation).toMatchObject({
      status: DepositOperationStatus.SUCCEEDED,
      providerOperationId: 'fake_deposit_refund-1',
      attempts: 1,
      processingUntil: null,
      completedAt: now,
    });
    expect(deposit).toMatchObject({
      status: DepositStatus.RESOLVED,
      refundedAmount: new Prisma.Decimal(50),
      releasedToLenderAmount: new Prisma.Decimal(0),
    });
    expect(booking.status).toBe(BookingStatus.COMPLETED);
    expect(history).toHaveLength(1);
    expect(outbox).toHaveLength(1);
  });

  it('lets only one worker hold the active lease while the provider is pending', async () => {
    let resolveProvider!: (result: ProviderOperationResult) => void;
    const pendingProvider = new Promise<ProviderOperationResult>((resolve) => {
      resolveProvider = resolve;
    });
    const { processor, provider } = createProcessor(pendingProvider);

    const first = processor.processPending(now);
    await new Promise<void>((resolve) => setImmediate(resolve));
    await expect(processor.processPending(now)).resolves.toBe(0);
    expect(provider).toHaveBeenCalledTimes(1);

    resolveProvider({
      outcome: 'SUCCEEDED',
      providerOperationId: 'fake_deposit_refund-1',
    });
    await expect(first).resolves.toBe(1);
  });

  it('does not apply success after another worker replaces its lease', async () => {
    const { processor, operation, deposit, provider, booking } =
      createProcessor({
        outcome: 'SUCCEEDED',
        providerOperationId: 'fake_deposit_refund-1',
      });
    provider.mockImplementationOnce(() => {
      operation.processingUntil = new Date('2026-09-04T12:02:00.000Z');
      return Promise.resolve({
        outcome: 'SUCCEEDED',
        providerOperationId: 'fake_deposit_refund-1',
      });
    });

    await expect(processor.processPending(now)).resolves.toBe(1);
    expect(operation.status).toBe(DepositOperationStatus.PENDING);
    expect(deposit.refundedAmount).toEqual(new Prisma.Decimal(0));
    expect(booking.status).toBe(BookingStatus.RETURNED);
  });

  it('does not commit resolved money state when completion persistence fails', async () => {
    const { processor, operation, deposit, failCompletion, booking, history } =
      createProcessor({
        outcome: 'SUCCEEDED',
        providerOperationId: 'fake_deposit_refund-1',
      });
    failCompletion();

    await expect(processor.processPending(now)).rejects.toThrow(
      'outbox unavailable',
    );
    expect(operation.status).toBe(DepositOperationStatus.PENDING);
    expect(deposit.status).toBe(DepositStatus.RESOLVING);
    expect(deposit.refundedAmount).toEqual(new Prisma.Decimal(0));
    expect(booking.status).toBe(BookingStatus.RETURNED);
    expect(history).toHaveLength(0);
  });
});
