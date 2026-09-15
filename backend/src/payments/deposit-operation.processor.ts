import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import {
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  DisputeStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { MetricsService } from '../observability/metrics.service';
import { completeBookingAfterReturnInTransaction } from './deposit.service';
import {
  FakeSafeDealProvider,
  type ProviderOperationResult,
} from './fake-safe-deal.provider';
import { decimalToMinor } from './money-minor';
import {
  PaymentPolicyService,
  PaymentScenario,
} from './payment-policy.service';

const OPERATION_POLL_INTERVAL_MS = 5 * 1000;
const OPERATION_BATCH_SIZE = 50;
const OPERATION_LEASE_MS = 60 * 1000;
const INITIAL_RETRY_MS = 30 * 1000;
const MAX_RETRY_MS = 60 * 60 * 1000;

type OperationMetric = {
  operation: 'payout' | 'refund';
  result: 'failure';
};

@Injectable()
export class DepositOperationProcessor
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(DepositOperationProcessor.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly paymentPolicy: PaymentPolicyService,
    private readonly provider: FakeSafeDealProvider,
    private readonly metrics: MetricsService,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (
      process.env.NODE_ENV === 'test' ||
      this.paymentPolicy.current().paymentScenario !==
        PaymentScenario.FAKE_SAFE_DEAL
    ) {
      return;
    }
    await this.run();
    this.timer = setInterval(() => void this.run(), OPERATION_POLL_INTERVAL_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  async processPending(now = new Date()): Promise<number> {
    this.paymentPolicy.requireFakeSafeDeal();
    const pending = await this.prisma.depositOperation.findMany({
      where: {
        status: DepositOperationStatus.PENDING,
        nextAttemptAt: { lte: now },
        OR: [{ processingUntil: null }, { processingUntil: { lte: now } }],
      },
      select: { id: true },
      orderBy: [{ nextAttemptAt: 'asc' }, { createdAt: 'asc' }],
      take: OPERATION_BATCH_SIZE,
    });
    let processed = 0;
    for (const operation of pending) {
      processed += await this.processOne(operation.id, now);
    }
    return processed;
  }

  private async processOne(operationId: string, now: Date): Promise<number> {
    const processingUntil = new Date(now.getTime() + OPERATION_LEASE_MS);
    const claimed = await this.prisma.$transaction(async (tx) => {
      const result = await tx.depositOperation.updateMany({
        where: {
          id: operationId,
          status: DepositOperationStatus.PENDING,
          nextAttemptAt: { lte: now },
          OR: [{ processingUntil: null }, { processingUntil: { lte: now } }],
        },
        data: {
          processingUntil,
          attempts: { increment: 1 },
        },
      });
      if (result.count === 0) {
        return null;
      }
      return tx.depositOperation.findUnique({
        where: { id: operationId },
        include: { deposit: true },
      });
    });
    if (!claimed) {
      return 0;
    }
    if (claimed.deposit.currency !== 'RUB') {
      throw new Error('Deposit operation currency must be RUB');
    }

    let outcome: ProviderOperationResult;
    try {
      this.paymentPolicy.requireFakeSafeDeal();
      outcome = await this.provider.executeDepositOperation({
        idempotencyKey: claimed.idempotencyKey,
        depositId: claimed.depositId,
        kind: claimed.kind,
        amountMinor: decimalToMinor(claimed.amount),
        currency: 'RUB',
        outcome: 'SUCCESS',
      });
    } catch {
      outcome = { outcome: 'TIMEOUT' };
    }

    const metric = await this.applyOutcome(
      claimed.id,
      claimed.deposit.bookingId,
      claimed.attempts,
      processingUntil,
      outcome,
      now,
    );
    if (metric) {
      this.metrics.recordOperation(metric.operation, metric.result);
    }
    return 1;
  }

  private async applyOutcome(
    operationId: string,
    bookingId: string,
    attempts: number,
    processingUntil: Date,
    outcome: ProviderOperationResult,
    now: Date,
  ): Promise<OperationMetric | null> {
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
      const operation = await tx.depositOperation.findUnique({
        where: { id: operationId },
        include: { deposit: true },
      });
      if (
        !operation ||
        operation.status !== DepositOperationStatus.PENDING ||
        operation.processingUntil?.getTime() !== processingUntil.getTime()
      ) {
        return null;
      }

      if (outcome.outcome === 'TIMEOUT') {
        const retryDelay = Math.min(
          INITIAL_RETRY_MS * 2 ** Math.min(Math.max(attempts - 1, 0), 10),
          MAX_RETRY_MS,
        );
        const retryScheduled = await tx.depositOperation.updateMany({
          where: {
            id: operation.id,
            status: DepositOperationStatus.PENDING,
            processingUntil,
          },
          data: {
            processingUntil: null,
            nextAttemptAt: new Date(now.getTime() + retryDelay),
          },
        });
        if (retryScheduled.count === 0) {
          return null;
        }
        return null;
      }

      if (outcome.outcome === 'DECLINED') {
        const failed = await tx.depositOperation.updateMany({
          where: {
            id: operation.id,
            status: DepositOperationStatus.PENDING,
            processingUntil,
          },
          data: {
            status: DepositOperationStatus.FAILED,
            processingUntil: null,
            providerErrorCode: outcome.errorCode,
            completedAt: now,
          },
        });
        if (failed.count === 0) {
          return null;
        }
        await tx.adminAuditLog.create({
          data: {
            adminId: null,
            action: 'DEPOSIT_OPERATION_PROVIDER_DECLINED',
            entityType: 'DepositOperation',
            entityId: operation.id,
            reason: outcome.errorCode,
            metadata: { kind: operation.kind, attempts },
          },
        });
        return operation.kind === DepositOperationKind.REFUND
          ? { operation: 'refund', result: 'failure' }
          : operation.kind === DepositOperationKind.RELEASE_TO_LENDER
            ? { operation: 'payout', result: 'failure' }
            : null;
      }

      if (operation.deposit.status !== DepositStatus.RESOLVING) {
        return null;
      }
      const amountMinor = decimalToMinor(operation.amount);
      const refundedMinor = decimalToMinor(operation.deposit.refundedAmount);
      const releasedMinor = decimalToMinor(
        operation.deposit.releasedToLenderAmount,
      );
      const nextRefunded =
        operation.kind === DepositOperationKind.REFUND
          ? refundedMinor + amountMinor
          : refundedMinor;
      const nextReleased =
        operation.kind === DepositOperationKind.RELEASE_TO_LENDER
          ? releasedMinor + amountMinor
          : releasedMinor;
      const totalMinor = decimalToMinor(operation.deposit.amount);
      if (
        (operation.kind !== DepositOperationKind.REFUND &&
          operation.kind !== DepositOperationKind.RELEASE_TO_LENDER) ||
        nextRefunded + nextReleased > totalMinor
      ) {
        throw new Error('Deposit operation exceeds unsettled amount');
      }
      let resolved = nextRefunded + nextReleased === totalMinor;
      const succeeded = await tx.depositOperation.updateMany({
        where: {
          id: operation.id,
          status: DepositOperationStatus.PENDING,
          processingUntil,
        },
        data: {
          status: DepositOperationStatus.SUCCEEDED,
          processingUntil: null,
          providerOperationId: outcome.providerOperationId,
          providerErrorCode: null,
          completedAt: now,
        },
      });
      if (succeeded.count === 0) {
        return null;
      }
      const dispute = resolved
        ? await tx.financialDispute.findUnique({
            where: { bookingId },
            select: {
              id: true,
              status: true,
              refundToBorrowerAmount: true,
              releaseToLenderAmount: true,
            },
          })
        : null;
      if (
        dispute?.status === DisputeStatus.UNDER_REVIEW ||
        dispute?.status === DisputeStatus.RESOLVED
      ) {
        const requiredLegs = [
          {
            kind: DepositOperationKind.REFUND,
            amount: dispute.refundToBorrowerAmount,
          },
          {
            kind: DepositOperationKind.RELEASE_TO_LENDER,
            amount: dispute.releaseToLenderAmount,
          },
        ];
        for (const leg of requiredLegs) {
          if (decimalToMinor(leg.amount) === 0n) {
            continue;
          }
          const successfulAttempt = await tx.depositOperation.findFirst({
            where: {
              depositId: operation.depositId,
              kind: leg.kind,
              amount: leg.amount,
              status: DepositOperationStatus.SUCCEEDED,
            },
            select: { id: true },
          });
          if (!successfulAttempt) {
            resolved = false;
            break;
          }
        }
      }
      await tx.bookingDeposit.update({
        where: { id: operation.depositId },
        data: {
          refundedAmount:
            operation.kind === DepositOperationKind.REFUND
              ? { increment: operation.amount }
              : undefined,
          releasedToLenderAmount:
            operation.kind === DepositOperationKind.RELEASE_TO_LENDER
              ? { increment: operation.amount }
              : undefined,
          status: resolved ? DepositStatus.RESOLVED : DepositStatus.RESOLVING,
        },
      });
      if (resolved) {
        await completeBookingAfterReturnInTransaction(
          tx,
          bookingId,
          now,
          'DEPOSIT_SETTLED',
        );
      }
      return null;
    });
  }

  private async run(): Promise<void> {
    try {
      await this.processPending();
    } catch (error) {
      this.logger.error('Не удалось обработать операцию залога', error);
    }
  }
}
