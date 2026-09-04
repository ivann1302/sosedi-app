import {
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  DisputeStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DepositDeadlineService } from './deposit-deadline.service';

const dueAt = new Date('2026-09-04T12:00:00.000Z');

function createService(disputeStatus: DisputeStatus | null = null) {
  let depositStatus = DepositStatus.HELD;
  const operations: Array<Record<string, unknown>> = [];
  const deposit = {
    id: 'deposit-1',
    bookingId: 'booking-1',
    amount: new Prisma.Decimal(50),
    currency: 'RUB',
    status: depositStatus,
    disputeWindowEndsAt: dueAt,
    booking: {
      status: BookingStatus.RETURNED,
      financialDispute: disputeStatus ? { status: disputeStatus } : null,
    },
  };
  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    bookingDeposit: {
      findUnique: jest
        .fn()
        .mockImplementation(() =>
          Promise.resolve({ ...deposit, status: depositStatus }),
        ),
      update: jest
        .fn()
        .mockImplementation(({ data }: { data: { status: DepositStatus } }) => {
          depositStatus = data.status;
          return Promise.resolve({ ...deposit, status: depositStatus });
        }),
    },
    depositOperation: {
      findUnique: jest
        .fn()
        .mockImplementation(
          ({ where }: { where: { idempotencyKey: string } }) =>
            Promise.resolve(
              operations.find(
                (operation) =>
                  operation.idempotencyKey === where.idempotencyKey,
              ) ?? null,
            ),
        ),
      create: jest
        .fn()
        .mockImplementation(({ data }: { data: Record<string, unknown> }) => {
          operations.push({ id: 'operation-1', ...data });
          return Promise.resolve(operations[0]);
        }),
    },
  };
  const prisma = {
    bookingDeposit: {
      findMany: jest
        .fn()
        .mockImplementation(() =>
          Promise.resolve(
            depositStatus === DepositStatus.HELD
              ? [{ id: 'deposit-1', bookingId: 'booking-1' }]
              : [],
          ),
        ),
    },
    $transaction: jest.fn((callback: (client: typeof tx) => Promise<number>) =>
      callback(tx),
    ),
  };
  return {
    service: new DepositDeadlineService(prisma as unknown as PrismaService),
    operations,
    status: () => depositStatus,
  };
}

describe('DepositDeadlineService', () => {
  it('schedules one full automatic refund and becomes idempotent', async () => {
    const { service, operations, status } = createService();

    await expect(service.processDue(dueAt)).resolves.toBe(1);
    await expect(service.processDue(dueAt)).resolves.toBe(0);

    expect(status()).toBe(DepositStatus.RESOLVING);
    expect(operations).toEqual([
      expect.objectContaining({
        depositId: 'deposit-1',
        kind: DepositOperationKind.REFUND,
        amount: new Prisma.Decimal(50),
        status: DepositOperationStatus.PENDING,
        idempotencyKey: 'deposit:deposit-1:auto-refund',
      }),
    ]);
  });

  it('does not schedule an automatic refund when a dispute exists', async () => {
    const { service, operations, status } = createService(DisputeStatus.OPEN);

    await expect(service.processDue(dueAt)).resolves.toBe(0);
    expect(status()).toBe(DepositStatus.HELD);
    expect(operations).toHaveLength(0);
  });
});
