import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminCapability,
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  DisputeStatus,
  Prisma,
} from '@prisma/client';
import type { AdminAuditContext } from '../admin/admin-audit-context';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { UploadPurpose } from '../upload/upload.types';
import { completeBookingAfterReturnInTransaction } from './deposit.service';
import {
  decimalToMinor,
  minorToDecimal,
  minorToSafeNumber,
} from './money-minor';
import { AdminDisputeResponseDto } from './dto/admin-dispute-response.dto';
import { AddDisputeEvidenceDto } from './dto/add-dispute-evidence.dto';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import { ResolveDisputeDto } from './dto/resolve-dispute.dto';
import { PaymentPolicyService } from './payment-policy.service';
import {
  DisputeEvidenceResponseDto,
  DisputeResponseDto,
} from './dto/dispute-response.dto';

const disputeInclude = {
  evidence: { orderBy: { createdAt: 'asc' as const } },
};

const adminDisputeSelect = {
  id: true,
  bookingId: true,
  reason: true,
  description: true,
  status: true,
  refundToBorrowerAmount: true,
  releaseToLenderAmount: true,
  openedAt: true,
  resolvedAt: true,
  evidence: {
    orderBy: { createdAt: 'asc' as const },
    select: { id: true, sha256: true, createdAt: true },
  },
  booking: {
    select: {
      deposit: {
        select: {
          amount: true,
          status: true,
          disputeWindowEndsAt: true,
          operations: {
            where: { status: DepositOperationStatus.FAILED },
            orderBy: { createdAt: 'asc' as const },
            select: {
              id: true,
              kind: true,
              amount: true,
              status: true,
              providerErrorCode: true,
              attempts: true,
              retryOfId: true,
              createdAt: true,
              completedAt: true,
              retries: {
                orderBy: { createdAt: 'asc' as const },
                select: { id: true },
                take: 1,
              },
            },
          },
        },
      },
    },
  },
} satisfies Prisma.FinancialDisputeSelect;

type DisputeWithEvidence = Prisma.FinancialDisputeGetPayload<{
  include: typeof disputeInclude;
}>;

type AdminDisputeWithQueue = Prisma.FinancialDisputeGetPayload<{
  select: typeof adminDisputeSelect;
}>;

@Injectable()
export class DisputeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly upload: UploadService,
    private readonly paymentPolicy: PaymentPolicyService,
  ) {}

  openDispute(
    actorId: string,
    bookingId: string,
    dto: CreateDisputeDto,
    now = new Date(),
  ): Promise<DisputeResponseDto> {
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: {
          deposit: true,
          financialDispute: { select: { id: true } },
        },
      });
      if (
        !booking ||
        (booking.borrowerId !== actorId && booking.lenderId !== actorId)
      ) {
        throw new NotFoundException('Бронирование не найдено');
      }
      if (
        booking.status !== BookingStatus.RETURNED ||
        !booking.deposit ||
        booking.deposit.status !== DepositStatus.HELD ||
        !booking.deposit.disputeWindowEndsAt ||
        booking.deposit.disputeWindowEndsAt <= now ||
        booking.financialDispute
      ) {
        throw new ConflictException('Спор нельзя открыть в текущем состоянии');
      }

      const dispute = await tx.financialDispute.create({
        data: {
          bookingId,
          openedById: actorId,
          reason: dto.reason,
          description: dto.description || null,
          openedAt: now,
        },
        include: disputeInclude,
      });
      await tx.bookingDeposit.update({
        where: { id: booking.deposit.id },
        data: { status: DepositStatus.DISPUTED },
      });
      return this.toDisputeResponse(dispute);
    });
  }

  async getDispute(
    actorId: string,
    bookingId: string,
  ): Promise<DisputeResponseDto> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        OR: [{ borrowerId: actorId }, { lenderId: actorId }],
      },
      select: {
        financialDispute: { include: disputeInclude },
      },
    });
    if (!booking?.financialDispute) {
      throw new NotFoundException('Спор не найден');
    }
    return this.toDisputeResponse(booking.financialDispute);
  }

  async listForAdmin(
    adminId: string,
    readCapability: AdminCapability,
    context: AdminAuditContext,
  ): Promise<AdminDisputeResponseDto[]> {
    const disputes = await this.prisma.financialDispute.findMany({
      select: adminDisputeSelect,
      orderBy: { openedAt: 'asc' },
    });
    const response = disputes.map((dispute) =>
      this.toAdminDisputeResponse(dispute),
    );
    await this.prisma.adminAuditLog.create({
      data: {
        adminId,
        action: 'FINANCIAL_DISPUTE_QUEUE_ACCESSED',
        entityType: 'FinancialDispute',
        capability: readCapability,
        requestId: context.requestId,
        ipAddress: context.ipAddress,
        deviceId: context.deviceId,
        metadata: { count: response.length },
      },
    });
    return response;
  }

  async resolveDispute(
    adminId: string,
    disputeId: string,
    dto: ResolveDisputeDto,
    idempotencyKey: string,
    context: AdminAuditContext,
    now = new Date(),
  ): Promise<DisputeResponseDto> {
    this.paymentPolicy.requireFakeSafeDeal();
    const commandKey = idempotencyKey.trim();
    if (!commandKey) {
      throw new BadRequestException('Idempotency-Key обязателен');
    }
    this.assertResolutionLeg(dto.refundToBorrowerMinor);
    this.assertResolutionLeg(dto.releaseToLenderMinor);

    const target = await this.prisma.financialDispute.findUnique({
      where: { id: disputeId },
      select: { bookingId: true },
    });
    if (!target) {
      throw new NotFoundException('Спор не найден');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${target.bookingId}))`;
      const dispute = await tx.financialDispute.findUnique({
        where: { id: disputeId },
        include: {
          ...disputeInclude,
          booking: { include: { deposit: true } },
        },
      });
      if (!dispute?.booking.deposit) {
        throw new NotFoundException('Спор не найден');
      }
      const deposit = dispute.booking.deposit;
      const refundMinor = BigInt(dto.refundToBorrowerMinor);
      const releaseMinor = BigInt(dto.releaseToLenderMinor);
      if (refundMinor + releaseMinor !== decimalToMinor(deposit.amount)) {
        throw new ConflictException('Сумма решения не равна сумме залога');
      }

      if (
        dispute.status === DisputeStatus.UNDER_REVIEW ||
        dispute.status === DisputeStatus.RESOLVED
      ) {
        if (
          dispute.resolvedById !== adminId ||
          dispute.decisionReason !== dto.reason ||
          decimalToMinor(dispute.refundToBorrowerAmount) !== refundMinor ||
          decimalToMinor(dispute.releaseToLenderAmount) !== releaseMinor ||
          !(await this.hasResolutionOperations(
            tx,
            disputeId,
            deposit.id,
            dto,
            commandKey,
          ))
        ) {
          throw new ConflictException('Спор уже имеет другое решение');
        }
        return this.toDisputeResponse(dispute);
      }
      if (
        dispute.status !== DisputeStatus.OPEN ||
        dispute.booking.status !== BookingStatus.RETURNED ||
        deposit.status !== DepositStatus.DISPUTED
      ) {
        throw new ConflictException(
          'Спор нельзя разрешить в текущем состоянии',
        );
      }

      await this.createResolutionOperation(
        tx,
        disputeId,
        deposit.id,
        DepositOperationKind.REFUND,
        dto.refundToBorrowerMinor,
        commandKey,
        now,
      );
      await this.createResolutionOperation(
        tx,
        disputeId,
        deposit.id,
        DepositOperationKind.RELEASE_TO_LENDER,
        dto.releaseToLenderMinor,
        commandKey,
        now,
      );
      await tx.bookingDeposit.update({
        where: { id: deposit.id },
        data: { status: DepositStatus.RESOLVING },
      });
      const updated = await tx.financialDispute.update({
        where: { id: dispute.id },
        data: {
          status: DisputeStatus.RESOLVED,
          resolvedById: adminId,
          decisionReason: dto.reason,
          refundToBorrowerAmount: minorToDecimal(refundMinor),
          releaseToLenderAmount: minorToDecimal(releaseMinor),
          resolvedAt: now,
        },
        include: disputeInclude,
      });
      await tx.adminAuditLog.create({
        data: {
          adminId,
          action: 'FINANCIAL_DISPUTE_RESOLVED',
          entityType: 'FinancialDispute',
          entityId: dispute.id,
          capability: AdminCapability.FINANCE,
          reason: dto.reason,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          before: {
            status: DisputeStatus.OPEN,
            depositStatus: DepositStatus.DISPUTED,
          },
          after: {
            status: DisputeStatus.RESOLVED,
            depositStatus: DepositStatus.RESOLVING,
          },
          metadata: {
            depositId: deposit.id,
            refundToBorrowerMinor: dto.refundToBorrowerMinor,
            releaseToLenderMinor: dto.releaseToLenderMinor,
            requiredCapabilities: [
              AdminCapability.DISPUTE,
              AdminCapability.FINANCE,
            ],
          },
        },
      });
      await completeBookingAfterReturnInTransaction(
        tx,
        target.bookingId,
        now,
        'DISPUTE_DECIDED',
      );
      return this.toDisputeResponse(updated);
    });
  }

  async addEvidence(
    actorId: string,
    bookingId: string,
    disputeId: string,
    dto: AddDisputeEvidenceDto,
    now = new Date(),
  ): Promise<DisputeEvidenceResponseDto> {
    const verified = await this.upload.verifyDisputeEvidenceIntent(
      actorId,
      disputeId,
      dto.intentId,
    );

    return this.prisma.$transaction(async (tx) => {
      const dispute = await tx.financialDispute.findFirst({
        where: {
          id: disputeId,
          bookingId,
          booking: {
            OR: [{ borrowerId: actorId }, { lenderId: actorId }],
          },
        },
        select: { id: true },
      });
      if (!dispute) {
        throw new NotFoundException('Спор не найден');
      }

      const consumed = await tx.uploadIntent.updateMany({
        where: {
          id: verified.intentId,
          actorId,
          entityId: disputeId,
          purpose: UploadPurpose.DISPUTE_EVIDENCE,
          confirmedAt: null,
          expiresAt: { gt: now },
        },
        data: { confirmedAt: now },
      });
      if (consumed.count !== 1) {
        throw new ConflictException('Upload intent уже использован или истёк');
      }

      const evidence = await tx.disputeEvidence.create({
        data: {
          disputeId,
          uploadIntentId: verified.intentId,
          storageKey: verified.objectKey,
          sha256: verified.sha256,
        },
        select: { id: true, sha256: true, createdAt: true },
      });
      return {
        id: evidence.id,
        sha256: evidence.sha256,
        createdAt: evidence.createdAt,
      };
    });
  }

  getEvidenceDownloadUrl(
    actorId: string,
    bookingId: string,
    disputeId: string,
    evidenceId: string,
  ) {
    return this.upload.getDisputeEvidenceDownloadUrl(
      actorId,
      bookingId,
      disputeId,
      evidenceId,
    );
  }

  getEvidenceDownloadUrlForAdmin(
    adminId: string,
    disputeId: string,
    evidenceId: string,
    readCapability: AdminCapability,
    context: AdminAuditContext,
  ) {
    return this.upload.getAdminDisputeEvidenceDownloadUrl(
      adminId,
      disputeId,
      evidenceId,
      readCapability,
      context,
    );
  }

  private assertResolutionLeg(value: number): void {
    if (!Number.isSafeInteger(value) || value < 0) {
      throw new ConflictException('Сумма решения должна быть целым числом');
    }
  }

  private resolutionOperationKey(
    disputeId: string,
    commandKey: string,
    kind: DepositOperationKind,
  ): string {
    const leg =
      kind === DepositOperationKind.REFUND ? 'refund' : 'release-to-lender';
    return `dispute:${disputeId}:resolve:${commandKey}:${leg}`;
  }

  private async createResolutionOperation(
    tx: Prisma.TransactionClient,
    disputeId: string,
    depositId: string,
    kind: DepositOperationKind,
    amountMinor: number,
    commandKey: string,
    now: Date,
  ): Promise<void> {
    if (amountMinor === 0) {
      return;
    }
    await tx.depositOperation.create({
      data: {
        depositId,
        kind,
        amount: minorToDecimal(BigInt(amountMinor)),
        status: DepositOperationStatus.PENDING,
        idempotencyKey: this.resolutionOperationKey(
          disputeId,
          commandKey,
          kind,
        ),
        nextAttemptAt: now,
      },
    });
  }

  private async hasResolutionOperations(
    tx: Prisma.TransactionClient,
    disputeId: string,
    depositId: string,
    dto: ResolveDisputeDto,
    commandKey: string,
  ): Promise<boolean> {
    for (const [kind, amountMinor] of [
      [DepositOperationKind.REFUND, dto.refundToBorrowerMinor],
      [DepositOperationKind.RELEASE_TO_LENDER, dto.releaseToLenderMinor],
    ] as const) {
      if (amountMinor === 0) {
        continue;
      }
      const operation = await tx.depositOperation.findUnique({
        where: {
          idempotencyKey: this.resolutionOperationKey(
            disputeId,
            commandKey,
            kind,
          ),
        },
        select: { depositId: true, kind: true, amount: true },
      });
      if (
        !operation ||
        operation.depositId !== depositId ||
        operation.kind !== kind ||
        decimalToMinor(operation.amount) !== BigInt(amountMinor)
      ) {
        return false;
      }
    }
    return true;
  }

  private toDisputeResponse(dispute: DisputeWithEvidence): DisputeResponseDto {
    return {
      id: dispute.id,
      bookingId: dispute.bookingId,
      openedById: dispute.openedById,
      reason: dispute.reason,
      description: dispute.description,
      status: dispute.status,
      openedAt: dispute.openedAt,
      resolvedAt: dispute.resolvedAt,
      evidence: dispute.evidence.map(({ id, sha256, createdAt }) => ({
        id,
        sha256,
        createdAt,
      })),
    };
  }

  private toAdminDisputeResponse(
    dispute: AdminDisputeWithQueue,
  ): AdminDisputeResponseDto {
    const deposit = dispute.booking.deposit;
    if (!deposit) {
      throw new ConflictException('Спор не связан с залогом');
    }
    return {
      id: dispute.id,
      bookingId: dispute.bookingId,
      reason: dispute.reason,
      description: dispute.description,
      status: dispute.status,
      refundToBorrowerMinor: minorToSafeNumber(
        decimalToMinor(dispute.refundToBorrowerAmount),
      ),
      releaseToLenderMinor: minorToSafeNumber(
        decimalToMinor(dispute.releaseToLenderAmount),
      ),
      depositAmountMinor: minorToSafeNumber(decimalToMinor(deposit.amount)),
      depositStatus: deposit.status,
      disputeWindowEndsAt: deposit.disputeWindowEndsAt,
      openedAt: dispute.openedAt,
      resolvedAt: dispute.resolvedAt,
      evidence: dispute.evidence.map(({ id, sha256, createdAt }) => ({
        id,
        sha256,
        createdAt,
      })),
      failedOperations: deposit.operations.map((operation) => ({
        id: operation.id,
        kind: operation.kind,
        amountMinor: minorToSafeNumber(decimalToMinor(operation.amount)),
        status: DepositOperationStatus.FAILED,
        errorCode: operation.providerErrorCode,
        attempts: operation.attempts,
        retryOfId: operation.retryOfId,
        retryId: operation.retries[0]?.id ?? null,
        createdAt: operation.createdAt,
        completedAt: operation.completedAt,
      })),
    };
  }
}
