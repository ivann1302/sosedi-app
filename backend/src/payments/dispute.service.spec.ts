import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminCapability,
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  DisputeStatus,
  FinancialDisputeReason,
  Prisma,
} from '@prisma/client';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import type { AdminAuditContext } from '../admin/admin-audit-context';
import { UploadService } from '../upload/upload.service';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import { ResolveDisputeDto } from './dto/resolve-dispute.dto';
import { DisputeService } from './dispute.service';
import { PaymentPolicyService } from './payment-policy.service';

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
      { requireFakeSafeDeal: jest.fn() } as unknown as PaymentPolicyService,
    ),
    prisma,
    tx,
    upload,
    dispute,
  };
}

describe('DisputeService', () => {
  it('maps the admin queue to safe deposit and failed-operation fields', async () => {
    const prisma = {
      financialDispute: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'dispute-1',
            bookingId: 'booking-1',
            reason: FinancialDisputeReason.ITEM_DAMAGED,
            description: 'Повреждение корпуса',
            status: DisputeStatus.UNDER_REVIEW,
            refundToBorrowerAmount: new Prisma.Decimal('40.25'),
            releaseToLenderAmount: new Prisma.Decimal('59.75'),
            openedAt: beforeDeadline,
            resolvedAt: null,
            evidence: [
              {
                id: 'evidence-1',
                sha256: 'safe-hash',
                createdAt: beforeDeadline,
                storageKey: 'must-not-leak',
              },
            ],
            booking: {
              deposit: {
                amount: new Prisma.Decimal('100.00'),
                status: DepositStatus.RESOLVING,
                disputeWindowEndsAt: deadline,
                operations: [
                  {
                    id: 'operation-1',
                    kind: DepositOperationKind.REFUND,
                    amount: new Prisma.Decimal('40.25'),
                    status: DepositOperationStatus.FAILED,
                    providerErrorCode: 'DECLINED',
                    providerOperationId: 'must-not-leak',
                    attempts: 2,
                    retryOfId: null,
                    createdAt: beforeDeadline,
                    completedAt: beforeDeadline,
                    retries: [{ id: 'operation-2' }],
                  },
                ],
              },
            },
          },
        ]),
      },
      adminAuditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const service = new DisputeService(
      prisma as unknown as PrismaService,
      {} as UploadService,
      {} as PaymentPolicyService,
    );

    const response = await service.listForAdmin(
      'admin-1',
      AdminCapability.DISPUTE,
      {
        requestId: 'admin-queue-map-request',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
      },
    );

    expect(response).toEqual([
      {
        id: 'dispute-1',
        bookingId: 'booking-1',
        reason: FinancialDisputeReason.ITEM_DAMAGED,
        description: 'Повреждение корпуса',
        status: DisputeStatus.UNDER_REVIEW,
        refundToBorrowerMinor: 4_025,
        releaseToLenderMinor: 5_975,
        depositAmountMinor: 10_000,
        depositStatus: DepositStatus.RESOLVING,
        disputeWindowEndsAt: deadline,
        openedAt: beforeDeadline,
        resolvedAt: null,
        evidence: [
          { id: 'evidence-1', sha256: 'safe-hash', createdAt: beforeDeadline },
        ],
        failedOperations: [
          {
            id: 'operation-1',
            kind: DepositOperationKind.REFUND,
            amountMinor: 4_025,
            status: DepositOperationStatus.FAILED,
            errorCode: 'DECLINED',
            attempts: 2,
            retryOfId: null,
            retryId: 'operation-2',
            createdAt: beforeDeadline,
            completedAt: beforeDeadline,
          },
        ],
      },
    ]);
    expect(JSON.stringify(response)).not.toContain('storageKey');
    expect(JSON.stringify(response)).not.toContain('providerOperationId');
    expect(prisma.financialDispute.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ orderBy: { openedAt: 'asc' } }),
    );
  });

  it.each([AdminCapability.SUPPORT, AdminCapability.DISPUTE])(
    'audits an admin queue read with the actual %s capability and safe count only',
    async (capability) => {
      const prisma = {
        financialDispute: { findMany: jest.fn().mockResolvedValue([]) },
        adminAuditLog: { create: jest.fn().mockResolvedValue({}) },
      };
      const service = new DisputeService(
        prisma as unknown as PrismaService,
        {} as UploadService,
        {} as PaymentPolicyService,
      );
      await service.listForAdmin('admin-1', capability, {
        requestId: 'admin-queue-request',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
      });

      expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
        data: {
          adminId: 'admin-1',
          action: 'FINANCIAL_DISPUTE_QUEUE_ACCESSED',
          entityType: 'FinancialDispute',
          capability,
          requestId: 'admin-queue-request',
          ipAddress: '127.0.0.1',
          deviceId: 'device-hash',
          metadata: { count: 0 },
        },
      });
    },
  );

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

  it.each([
    [2_000, false],
    [2_001, true],
  ])(
    'validates the plan-authoritative description boundary at %i characters',
    async (length, rejected) => {
      const dto = plainToInstance(CreateDisputeDto, {
        reason: FinancialDisputeReason.OTHER,
        description: 'x'.repeat(length),
      });

      const errors = await validate(dto);

      expect(errors.some((error) => error.property === 'description')).toBe(
        rejected,
      );
    },
  );

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

describe('DisputeService financial resolution', () => {
  const now = new Date('2026-09-06T12:00:00.000Z');
  const context: AdminAuditContext = {
    requestId: 'resolve-request-1',
    ipAddress: '127.0.0.1',
    deviceId: 'device-hash',
  };

  function resolutionService() {
    const operations: Array<Record<string, unknown>> = [];
    const audit: Array<Record<string, unknown>> = [];
    const history: Array<Record<string, unknown>> = [];
    const outbox: Array<Record<string, unknown>> = [];
    const state = {
      status: DisputeStatus.OPEN,
      resolvedById: null as string | null,
      decisionReason: null as string | null,
      refundToBorrowerAmount: new Prisma.Decimal(0),
      releaseToLenderAmount: new Prisma.Decimal(0),
      resolvedAt: null as Date | null,
      depositStatus: DepositStatus.DISPUTED,
      bookingStatus: BookingStatus.RETURNED,
    };
    const disputeRecord = () => ({
      id: 'dispute-1',
      bookingId: 'booking-1',
      openedById: 'borrower-1',
      reason: FinancialDisputeReason.ITEM_DAMAGED,
      description: 'Повреждение',
      status: state.status,
      resolvedById: state.resolvedById,
      decisionReason: state.decisionReason,
      refundToBorrowerAmount: state.refundToBorrowerAmount,
      releaseToLenderAmount: state.releaseToLenderAmount,
      openedAt: beforeDeadline,
      resolvedAt: state.resolvedAt,
      evidence: [],
      booking: {
        status: state.bookingStatus,
        deposit: {
          id: 'deposit-1',
          amount: new Prisma.Decimal(100),
          status: state.depositStatus,
          disputeWindowEndsAt: deadline,
        },
      },
    });
    const tx = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      financialDispute: {
        findUnique: jest.fn().mockImplementation(() => disputeRecord()),
        update: jest
          .fn()
          .mockImplementation(({ data }: { data: Record<string, unknown> }) => {
            state.status = data.status as DisputeStatus;
            state.resolvedById = data.resolvedById as string;
            state.decisionReason = data.decisionReason as string;
            state.refundToBorrowerAmount =
              data.refundToBorrowerAmount as Prisma.Decimal;
            state.releaseToLenderAmount =
              data.releaseToLenderAmount as Prisma.Decimal;
            state.resolvedAt = data.resolvedAt as Date;
            return Promise.resolve(disputeRecord());
          }),
      },
      bookingDeposit: {
        update: jest.fn().mockImplementation(() => {
          state.depositStatus = DepositStatus.RESOLVING;
          return Promise.resolve({});
        }),
      },
      depositOperation: {
        findUnique: jest.fn(
          ({ where }: { where: { idempotencyKey: string } }) =>
            Promise.resolve(
              operations.find(
                (operation) =>
                  operation.idempotencyKey === where.idempotencyKey,
              ) ?? null,
            ),
        ),
        create: jest.fn(({ data }: { data: Record<string, unknown> }) => {
          const operation = {
            id: `operation-${operations.length + 1}`,
            ...data,
          };
          operations.push(operation);
          return Promise.resolve(operation);
        }),
      },
      adminAuditLog: {
        create: jest.fn(({ data }: { data: Record<string, unknown> }) => {
          audit.push(data);
          return Promise.resolve(data);
        }),
      },
      booking: {
        findUnique: jest.fn().mockImplementation(() =>
          Promise.resolve({
            id: 'booking-1',
            status: state.bookingStatus,
            deposit: {
              id: 'deposit-1',
              amount: new Prisma.Decimal(100),
              refundedAmount: new Prisma.Decimal(0),
              releasedToLenderAmount: new Prisma.Decimal(0),
              status: state.depositStatus,
              disputeWindowEndsAt: deadline,
            },
            financialDispute: { status: state.status },
          }),
        ),
        updateMany: jest.fn().mockImplementation(() => {
          state.bookingStatus = BookingStatus.COMPLETED;
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
      financialDispute: {
        findUnique: jest.fn().mockResolvedValue({ bookingId: 'booking-1' }),
        findMany: jest.fn(),
      },
      $transaction: jest.fn(
        (callback: (client: typeof tx) => Promise<unknown>) => callback(tx),
      ),
    };
    const upload = {};
    return {
      service: new DisputeService(
        prisma as unknown as PrismaService,
        upload as UploadService,
        { requireFakeSafeDeal: jest.fn() } as unknown as PaymentPolicyService,
      ),
      operations,
      audit,
      history,
      outbox,
      state,
      tx,
    };
  }

  it.each([
    [10_000, 0, [DepositOperationKind.REFUND]],
    [
      4_000,
      6_000,
      [DepositOperationKind.REFUND, DepositOperationKind.RELEASE_TO_LENDER],
    ],
    [0, 10_000, [DepositOperationKind.RELEASE_TO_LENDER]],
  ] as const)(
    'persists an exact %i/%i resolution with only positive legs',
    async (refundToBorrowerMinor, releaseToLenderMinor, expectedKinds) => {
      const { service, operations, audit, history, outbox, state } =
        resolutionService();

      await service.resolveDispute(
        'admin-1',
        'dispute-1',
        {
          refundToBorrowerMinor,
          releaseToLenderMinor,
          reason: 'Проверенное решение по спору',
        },
        'resolution-key-1',
        context,
        now,
      );

      expect(state).toMatchObject({
        status: DisputeStatus.RESOLVED,
        resolvedById: 'admin-1',
        decisionReason: 'Проверенное решение по спору',
        resolvedAt: now,
        depositStatus: DepositStatus.RESOLVING,
        bookingStatus: BookingStatus.COMPLETED,
      });
      expect(operations.map((operation) => operation.kind)).toEqual(
        expectedKinds,
      );
      expect(operations).toHaveLength(expectedKinds.length);
      expectedKinds.forEach((kind, index) => {
        expect(operations[index]).toMatchObject({
          id: `operation-${index + 1}`,
          depositId: 'deposit-1',
          kind,
          status: DepositOperationStatus.PENDING,
        });
      });
      expect(audit).toEqual([
        expect.objectContaining({
          adminId: 'admin-1',
          action: 'FINANCIAL_DISPUTE_RESOLVED',
          entityType: 'FinancialDispute',
          entityId: 'dispute-1',
          capability: AdminCapability.FINANCE,
          reason: 'Проверенное решение по спору',
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          metadata: {
            depositId: 'deposit-1',
            refundToBorrowerMinor,
            releaseToLenderMinor,
            requiredCapabilities: [
              AdminCapability.DISPUTE,
              AdminCapability.FINANCE,
            ],
          },
        }),
      ]);
      expect(JSON.stringify(audit)).not.toContain('phone');
      expect(JSON.stringify(audit)).not.toContain('address');
      expect(JSON.stringify(audit)).not.toContain('provider');
      expect(history).toEqual([
        expect.objectContaining({
          bookingId: 'booking-1',
          command: 'COMPLETE_AFTER_DISPUTE_DECISION',
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
    },
  );

  it.each([
    [-1, 10_001],
    [10_001, 0],
    [9_999, 0],
    [Number.MAX_SAFE_INTEGER + 1, 0],
  ])('rejects invalid resolution amounts %p/%p', async (refund, release) => {
    const { service, operations, audit } = resolutionService();

    await expect(
      service.resolveDispute(
        'admin-1',
        'dispute-1',
        {
          refundToBorrowerMinor: refund,
          releaseToLenderMinor: release,
          reason: 'Проверенное решение по спору',
        },
        'resolution-key-1',
        context,
        now,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(operations).toHaveLength(0);
    expect(audit).toHaveLength(0);
  });

  it('returns the original result for the same key and rejects a conflicting key', async () => {
    const { service, operations, audit } = resolutionService();
    const dto = {
      refundToBorrowerMinor: 4_000,
      releaseToLenderMinor: 6_000,
      reason: 'Проверенное решение по спору',
    };

    await service.resolveDispute(
      'admin-1',
      'dispute-1',
      dto,
      'resolution-key-1',
      context,
      now,
    );
    await expect(
      service.resolveDispute(
        'admin-1',
        'dispute-1',
        dto,
        'resolution-key-1',
        context,
        now,
      ),
    ).resolves.toMatchObject({ status: DisputeStatus.RESOLVED });
    await expect(
      service.resolveDispute(
        'admin-1',
        'dispute-1',
        dto,
        'different-key',
        context,
        now,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(operations).toHaveLength(2);
    expect(audit).toHaveLength(1);
  });

  it('keeps the same resolution key idempotent after settlement completes', async () => {
    const { service, state, operations, audit } = resolutionService();
    const dto = {
      refundToBorrowerMinor: 10_000,
      releaseToLenderMinor: 0,
      reason: 'Проверенное решение по спору',
    };
    await service.resolveDispute(
      'admin-1',
      'dispute-1',
      dto,
      'resolution-key-1',
      context,
      now,
    );
    state.status = DisputeStatus.RESOLVED;

    await expect(
      service.resolveDispute(
        'admin-1',
        'dispute-1',
        dto,
        'resolution-key-1',
        context,
        now,
      ),
    ).resolves.toMatchObject({ status: DisputeStatus.RESOLVED });
    expect(operations).toHaveLength(1);
    expect(audit).toHaveLength(1);
  });

  it('requires an idempotency key before opening a transaction', async () => {
    const { service, tx } = resolutionService();

    await expect(
      service.resolveDispute(
        'admin-1',
        'dispute-1',
        {
          refundToBorrowerMinor: 10_000,
          releaseToLenderMinor: 0,
          reason: 'Проверенное решение по спору',
        },
        ' ',
        context,
        now,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(tx.$executeRaw).not.toHaveBeenCalled();
  });

  it('validates safe integer legs and a 10–1000 character reason', async () => {
    const invalid = plainToInstance(ResolveDisputeDto, {
      refundToBorrowerMinor: Number.MAX_SAFE_INTEGER + 1,
      releaseToLenderMinor: 0,
      reason: 'коротко',
    });

    const errors = await validate(invalid);
    expect(errors.map((error) => error.property).sort()).toEqual([
      'reason',
      'refundToBorrowerMinor',
    ]);
  });
});
