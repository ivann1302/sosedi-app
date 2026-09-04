import { ConflictException } from '@nestjs/common';
import {
  BookingActStage,
  BookingStatus,
  DepositStatus,
  PaymentStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { BookingActService } from './booking-act.service';

const confirmedAt = new Date('2026-09-04T12:00:00.000Z');

function fakeSnapshot(depositMinor: number, disputeWindowSeconds = 86_400) {
  return {
    itemTitle: 'Проектор',
    lenderId: 'lender-1',
    lenderDisplayName: 'Лена',
    pricePerDay: 100,
    days: 1,
    rentalSubtotal: 100,
    depositAmount: depositMinor / 100,
    platformFee: 1,
    ownerPayout: 99,
    total: 100 + depositMinor / 100,
    currency: 'RUB',
    paymentScenario: 'FAKE_SAFE_DEAL',
    moneyMinor: {
      pricePerDay: 10_000,
      rentalSubtotal: 10_000,
      deposit: depositMinor,
      platformFee: 100,
      ownerPayout: 9_900,
      total: 10_000 + depositMinor,
    },
    depositTerms:
      depositMinor > 0
        ? { policyVersion: 'snapshot-policy', disputeWindowSeconds }
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
  };
}

function act(stage: BookingActStage, depositMinor = 5_000) {
  const isHandover = stage === BookingActStage.HANDOVER;
  return {
    id: `act-${stage}`,
    bookingId: 'booking-1',
    authorId: isHandover ? 'lender-1' : 'borrower-1',
    stage,
    createdAt: new Date('2026-09-04T10:00:00.000Z'),
    confirmedById: null,
    confirmedAt: null,
    readinessIsWorking: isHandover ? true : null,
    readinessIsComplete: isHandover ? true : null,
    readinessVisibleDefects: isHandover ? 'Нет' : null,
    readinessDeclaredAt: isHandover
      ? new Date('2026-09-04T10:00:00.000Z')
      : null,
    evidence: [],
    booking: {
      status: isHandover ? BookingStatus.CONFIRMED : BookingStatus.ACTIVE,
      borrowerId: 'borrower-1',
      lenderId: 'lender-1',
      startDate: new Date('2026-09-10T00:00:00.000Z'),
      endDate: new Date('2026-09-10T00:00:00.000Z'),
      totalAmount: new Prisma.Decimal(100 + depositMinor / 100),
      termsSnapshot: fakeSnapshot(depositMinor),
      payment: { status: PaymentStatus.SUCCEEDED },
      deposit:
        depositMinor > 0
          ? { id: 'deposit-1', status: DepositStatus.HELD }
          : null,
    },
  };
}

function createService(record = act(BookingActStage.HANDOVER)) {
  const updateDeposit = jest.fn().mockResolvedValue({ id: 'deposit-1' });
  const updateBooking = jest
    .fn()
    .mockImplementation(({ data }: { data: { status: BookingStatus } }) => {
      record.booking.status = data.status;
      return Promise.resolve({ id: 'booking-1' });
    });
  const updateBookingMany = jest
    .fn()
    .mockImplementation(({ data }: { data: { status: BookingStatus } }) => {
      record.booking.status = data.status;
      return Promise.resolve({ count: 1 });
    });
  const history: Array<Record<string, unknown>> = [];
  const outbox: Array<Record<string, unknown>> = [];
  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    bookingAct: {
      findFirst: jest.fn().mockResolvedValue(record),
      update: jest
        .fn()
        .mockImplementation(({ data }) =>
          Promise.resolve({ ...record, ...data }),
        ),
    },
    booking: {
      update: updateBooking,
      updateMany: updateBookingMany,
      findUnique: jest.fn().mockImplementation(() =>
        Promise.resolve({
          id: 'booking-1',
          status: record.booking.status,
          deposit: record.booking.deposit,
          financialDispute: null,
        }),
      ),
    },
    bookingDeposit: { update: updateDeposit },
    bookingMessage: { create: jest.fn().mockResolvedValue({}) },
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
    $transaction: jest.fn((callback: (client: typeof tx) => Promise<unknown>) =>
      callback(tx),
    ),
  };
  return {
    service: new BookingActService(
      prisma as unknown as PrismaService,
      {} as UploadService,
    ),
    updateBooking,
    updateDeposit,
    history,
    outbox,
    record,
  };
}

describe('BookingActService fake settlement gates', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(confirmedAt);
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('blocks fake handover without succeeded payment or a held positive deposit', async () => {
    const withoutPayment = act(BookingActStage.HANDOVER);
    withoutPayment.booking.payment = null as never;
    await expect(
      createService(withoutPayment).service.confirm(
        'borrower-1',
        'booking-1',
        withoutPayment.id,
      ),
    ).rejects.toBeInstanceOf(ConflictException);

    const pendingDeposit = act(BookingActStage.HANDOVER);
    pendingDeposit.booking.deposit!.status = DepositStatus.PENDING;
    await expect(
      createService(pendingDeposit).service.confirm(
        'borrower-1',
        'booking-1',
        pendingDeposit.id,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('allows fake handover without a deposit only after successful payment', async () => {
    const noDeposit = act(BookingActStage.HANDOVER, 0);
    const { service, updateBooking } = createService(noDeposit);

    await expect(
      service.confirm('borrower-1', 'booking-1', noDeposit.id),
    ).resolves.toMatchObject({ confirmedAt });
    expect(updateBooking).toHaveBeenCalledWith({
      where: { id: 'booking-1' },
      data: { status: BookingStatus.ACTIVE },
    });
  });

  it('sets the return deadline from snapshotted dispute seconds', async () => {
    const returned = act(BookingActStage.RETURN);
    returned.booking.termsSnapshot = fakeSnapshot(5_000, 123);
    const { service, updateDeposit } = createService(returned);

    await service.confirm('lender-1', 'booking-1', returned.id);

    expect(updateDeposit).toHaveBeenCalledWith({
      where: { id: 'deposit-1' },
      data: {
        disputeWindowEndsAt: new Date('2026-09-04T12:02:03.000Z'),
      },
    });
  });

  it('completes a paid fake zero-deposit booking in the return transaction', async () => {
    const returned = act(BookingActStage.RETURN, 0);
    const { service, history, outbox, record } = createService(returned);

    await service.confirm('lender-1', 'booking-1', returned.id);

    expect(record.booking.status).toBe(BookingStatus.COMPLETED);
    expect(history.map((entry) => entry.command)).toEqual([
      'CONFIRM_RETURN',
      'COMPLETE_AFTER_RETURN',
    ]);
    expect(outbox.map((entry) => entry.eventType)).toEqual([
      'BOOKING_RETURN_CONFIRMED',
      'BOOKING_COMPLETED',
    ]);
  });
});
