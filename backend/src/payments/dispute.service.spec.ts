import { ConflictException, NotFoundException } from '@nestjs/common';
import {
  BookingStatus,
  DepositStatus,
  DisputeStatus,
  FinancialDisputeReason,
} from '@prisma/client';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import { DisputeService } from './dispute.service';

const deadline = new Date('2026-09-05T12:00:00.000Z');
const beforeDeadline = new Date(deadline.getTime() - 1);

function booking(overrides: Record<string, unknown> = {}) {
  return {
    id: 'booking-1',
    borrowerId: 'borrower-1',
    lenderId: 'lender-1',
    status: BookingStatus.RETURNED,
    payment: { id: 'payment-1', status: 'SUCCEEDED' },
    deposit: {
      id: 'deposit-1',
      status: DepositStatus.HELD,
      disputeWindowEndsAt: deadline,
    },
    financialDispute: null,
    ...overrides,
  };
}

function createService(currentBooking = booking()) {
  const dispute = {
    id: 'dispute-1',
    bookingId: 'booking-1',
    openedById: 'borrower-1',
    reason: FinancialDisputeReason.ITEM_DAMAGED,
    description: 'Повреждение корпуса',
    status: DisputeStatus.OPEN,
    openedAt: beforeDeadline,
    resolvedAt: null,
    evidence: [],
  };
  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    booking: {
      findUnique: jest.fn().mockResolvedValue(currentBooking),
      findFirst: jest.fn(),
    },
    bookingDeposit: { update: jest.fn().mockResolvedValue({}) },
    financialDispute: {
      create: jest
        .fn<Promise<typeof dispute>, [unknown]>()
        .mockResolvedValue(dispute),
      findFirst: jest.fn(),
    },
    uploadIntent: {
      updateMany: jest
        .fn<Promise<{ count: number }>, [unknown]>()
        .mockResolvedValue({ count: 1 }),
    },
    disputeEvidence: {
      create: jest.fn().mockResolvedValue({
        id: 'evidence-1',
        sha256: 'safe-hash',
        createdAt: beforeDeadline,
        storageKey: 'must-not-leak',
      }),
    },
  };
  const prisma = {
    $transaction: jest.fn((callback: (client: typeof tx) => unknown) =>
      callback(tx),
    ),
    booking: { findFirst: jest.fn() },
  };
  const upload = {
    verifyDisputeEvidenceIntent: jest.fn().mockResolvedValue({
      intentId: '11111111-1111-4111-8111-111111111111',
      bucket: 'private-bucket',
      objectKey:
        'quarantine/dispute-evidence/dispute-1/borrower-1/evidence.jpg',
      sha256: 'safe-hash',
    }),
    getDisputeEvidenceDownloadUrl: jest.fn(),
  };
  return {
    service: new DisputeService(
      prisma as unknown as PrismaService,
      upload as unknown as UploadService,
    ),
    prisma,
    tx,
    upload,
    dispute,
  };
}

describe('DisputeService', () => {
  it.each([
    FinancialDisputeReason.ITEM_DAMAGED,
    FinancialDisputeReason.ITEM_LOST,
    FinancialDisputeReason.OTHER,
  ])('opens one participant dispute for allowed reason %s', async (reason) => {
    const { service, tx } = createService();

    await expect(
      service.openDispute(
        'borrower-1',
        'booking-1',
        { reason, description: 'Повреждение корпуса' },
        beforeDeadline,
      ),
    ).resolves.toMatchObject({ id: 'dispute-1', status: DisputeStatus.OPEN });

    expect(tx.$executeRaw).toHaveBeenCalledTimes(1);
    expect(tx.financialDispute.create).toHaveBeenCalledTimes(1);
    const createCall = tx.financialDispute.create.mock.calls[0][0] as {
      data: { bookingId: string; openedById: string; reason: string };
      include: unknown;
    };
    expect(createCall.data).toMatchObject({
      bookingId: 'booking-1',
      openedById: 'borrower-1',
      reason,
    });
    expect(createCall.include).toEqual({
      evidence: { orderBy: { createdAt: 'asc' } },
    });
    expect(tx.bookingDeposit.update).toHaveBeenCalledWith({
      where: { id: 'deposit-1' },
      data: { status: DepositStatus.DISPUTED },
    });
    expect(tx.booking.findUnique).toHaveBeenCalledTimes(1);
  });

  it('returns non-disclosing not found for an outsider', async () => {
    const { service, tx } = createService();

    await expect(
      service.openDispute(
        'outsider-1',
        'booking-1',
        { reason: FinancialDisputeReason.ITEM_LOST },
        beforeDeadline,
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(tx.financialDispute.create).not.toHaveBeenCalled();
  });

  it.each([
    ['second dispute', { financialDispute: { id: 'existing' } }],
    ['wrong booking state', { status: BookingStatus.ACTIVE }],
    [
      'wrong deposit state',
      {
        deposit: {
          id: 'deposit-1',
          status: DepositStatus.RESOLVING,
          disputeWindowEndsAt: deadline,
        },
      },
    ],
  ])(
    'rejects %s without changing financial state',
    async (_name, overrides) => {
      const { service, tx } = createService(booking(overrides));

      await expect(
        service.openDispute(
          'lender-1',
          'booking-1',
          { reason: FinancialDisputeReason.OTHER },
          beforeDeadline,
        ),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(tx.financialDispute.create).not.toHaveBeenCalled();
      expect(tx.bookingDeposit.update).not.toHaveBeenCalled();
    },
  );

  it('closes the dispute window exactly at the immutable deadline', async () => {
    const { service, tx } = createService();

    await expect(
      service.openDispute(
        'borrower-1',
        'booking-1',
        { reason: FinancialDisputeReason.ITEM_DAMAGED },
        deadline,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.financialDispute.create).not.toHaveBeenCalled();
  });

  it('validates only the exact supported dispute reasons', async () => {
    const dto = plainToInstance(CreateDisputeDto, { reason: 'PAYMENT_DELAY' });
    const errors = await validate(dto);

    expect(errors.some((error) => error.property === 'reason')).toBe(true);
  });

  it('consumes a bound upload intent and creates evidence atomically', async () => {
    const { service, tx, upload } = createService();
    tx.financialDispute.findFirst.mockResolvedValue({ id: 'dispute-1' });

    const response = await service.addEvidence(
      'borrower-1',
      'booking-1',
      'dispute-1',
      { intentId: '11111111-1111-4111-8111-111111111111' },
      beforeDeadline,
    );

    expect(upload.verifyDisputeEvidenceIntent).toHaveBeenCalledWith(
      'borrower-1',
      'dispute-1',
      '11111111-1111-4111-8111-111111111111',
    );
    expect(tx.uploadIntent.updateMany).toHaveBeenCalledTimes(1);
    const consumeCall = tx.uploadIntent.updateMany.mock.calls[0][0] as {
      where: Record<string, unknown>;
      data: Record<string, unknown>;
    };
    expect(consumeCall).toMatchObject({
      where: {
        id: '11111111-1111-4111-8111-111111111111',
        actorId: 'borrower-1',
        entityId: 'dispute-1',
        confirmedAt: null,
      },
      data: { confirmedAt: beforeDeadline },
    });
    expect(response).toEqual({
      id: 'evidence-1',
      sha256: 'safe-hash',
      createdAt: beforeDeadline,
    });
    expect(response).not.toHaveProperty('storageKey');
  });

  it('rejects reuse of an already consumed evidence intent', async () => {
    const { service, tx } = createService();
    tx.financialDispute.findFirst.mockResolvedValue({ id: 'dispute-1' });
    tx.uploadIntent.updateMany.mockResolvedValue({ count: 0 });

    await expect(
      service.addEvidence(
        'borrower-1',
        'booking-1',
        'dispute-1',
        { intentId: '11111111-1111-4111-8111-111111111111' },
        beforeDeadline,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.disputeEvidence.create).not.toHaveBeenCalled();
  });

  it('hides dispute reads from outsiders', async () => {
    const { service, prisma } = createService();
    prisma.booking.findFirst.mockResolvedValue(null);

    await expect(
      service.getDispute('outsider-1', 'booking-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
