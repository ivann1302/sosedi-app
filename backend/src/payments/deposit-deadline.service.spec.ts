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
  let bookingStatus = BookingStatus.RETURNED;
  const operations: Array<Record<string, unknown>> = [];
  const history: Array<Record<string, unknown>> = [];
  const outbox: Array<Record<string, unknown>> = [];
  const deposit = {
    id: 'deposit-1',
    bookingId: 'booking-1',
    amount: new Prisma.Decimal(50),
    currency: 'RUB',
    status: depositStatus,
    disputeWindowEndsAt: dueAt,
    booking: {
      status: bookingStatus,
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
    booking: {
      findUnique: jest.fn().mockImplementation(() =>
        Promise.resolve({
          id: 'booking-1',
          status: bookingStatus,
          deposit: { ...deposit, status: depositStatus },
          financialDispute: disputeStatus ? { status: disputeStatus } : null,
        }),
      ),
      updateMany: jest.fn().mockImplementation(() => {
        bookingStatus = BookingStatus.COMPLETED;
        return Promise.resolve({ count: 1 });
      }),
    },
    bookingTransitionHistory: {
      create: jest.fn(({ data }: { data: Record<string, unknown> }) => {
        history.push(data);
        return Promise.resolve(data);
      }),
    },
    notificationOutboxEvent: {
      create: jest.fn(({ data }: { data: Record<string, unknown> }) => {
        outbox.push(data);
        return Promise.resolve(data);
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
    bookingStatus: () => bookingStatus,
    history,
    outbox,
  };
}

describe('DepositDeadlineService', () => {
  it('completes the returned booking when the undisputed window closes before refund succeeds', async () => {
    const { service, operations, status, bookingStatus, history, outbox } =
      createService();

    await expect(service.processDue(dueAt)).resolves.toBe(1);
    await expect(service.processDue(dueAt)).resolves.toBe(0);

    expect(status()).toBe(DepositStatus.RESOLVING);
    expect(bookingStatus()).toBe(BookingStatus.COMPLETED);
    expect(operations).toEqual([
      expect.objectContaining({
        depositId: 'deposit-1',
        kind: DepositOperationKind.REFUND,
        amount: new Prisma.Decimal(50),
        status: DepositOperationStatus.PENDING,
        idempotencyKey: 'deposit:deposit-1:auto-refund',
      }),
    ]);
    expect(history).toEqual([
      expect.objectContaining({
        bookingId: 'booking-1',
        command: 'COMPLETE_AFTER_DISPUTE_WINDOW',
        oldStatus: BookingStatus.RETURNED,
        newStatus: BookingStatus.COMPLETED,
      }),
    ]);
    expect(outbox).toEqual([
      expect.objectContaining({
        bookingId: 'booking-1',
        eventType: 'BOOKING_COMPLETED',
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
