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
  PaymentStatus,
  Prisma,
} from '@prisma/client';
import type { AdminAuditContext } from '../admin/admin-audit-context';
import { readBoundBookingTermsSnapshot } from '../booking/booking-terms';
import { BookingEventType, bookingEventKey } from '../booking/booking-events';
import { PrismaService } from '../prisma/prisma.service';
import {
  decimalToMinor,
  minorToDecimal,
  minorToSafeNumber,
} from './money-minor';
import {
  FakeSafeDealProvider,
  type FakeOperationOutcome,
  type ProviderOperationResult,
} from './fake-safe-deal.provider';
import { PaymentPolicyService } from './payment-policy.service';

type SettlementAmounts = {
  status: DepositStatus;
  amount: Prisma.Decimal;
  refundedAmount: Prisma.Decimal;
  releasedToLenderAmount: Prisma.Decimal;
};

export type DepositOperationCommandResponse = {
  id: string;
  depositId: string;
  kind: DepositOperationKind;
  amountMinor: number;
  status: DepositOperationStatus;
  retryOfId: string | null;
};

export function assertDepositSettledForCompletionOrPayout(
  deposit: SettlementAmounts | null,
): void {
  if (!deposit) {
    return;
  }
  if (
    deposit.status !== DepositStatus.RESOLVED ||
    decimalToMinor(deposit.refundedAmount) +
      decimalToMinor(deposit.releasedToLenderAmount) !==
      decimalToMinor(deposit.amount)
  ) {
    throw new ConflictException('Deposit is not fully settled');
  }
}

export type BookingCompletionTrigger =
  | 'DEPOSIT_SETTLED'
  | 'ZERO_DEPOSIT_RETURN';

export async function completeBookingAfterReturnInTransaction(
  tx: Prisma.TransactionClient,
  bookingId: string,
  now: Date,
  trigger: BookingCompletionTrigger,
): Promise<number> {
  const booking = await tx.booking.findUnique({
    where: { id: bookingId },
    include: {
      deposit: true,
      financialDispute: { select: { status: true } },
    },
  });
  if (!booking || booking.status === BookingStatus.COMPLETED) {
    return 0;
  }
  if (
    booking.status !== BookingStatus.RETURNED ||
    (booking.financialDispute &&
      booking.financialDispute.status !== DisputeStatus.RESOLVED)
  ) {
    return 0;
  }

  if (trigger === 'ZERO_DEPOSIT_RETURN') {
    if (booking.deposit) {
      throw new ConflictException('Unexpected deposit for zero-deposit return');
    }
    assertDepositSettledForCompletionOrPayout(null);
  } else {
    if (!booking.deposit?.disputeWindowEndsAt) {
      return 0;
    }
    if (
      booking.deposit.disputeWindowEndsAt > now &&
      booking.financialDispute?.status !== DisputeStatus.RESOLVED
    ) {
      return 0;
    }
    assertDepositSettledForCompletionOrPayout(booking.deposit);
  }

  const completed = await tx.booking.updateMany({
    where: { id: bookingId, status: BookingStatus.RETURNED },
    data: { status: BookingStatus.COMPLETED },
  });
  if (completed.count === 0) {
    return 0;
  }
  const command =
    trigger === 'ZERO_DEPOSIT_RETURN'
      ? 'COMPLETE_AFTER_RETURN'
      : 'COMPLETE_AFTER_DEPOSIT_SETTLED';
  const requestId =
    trigger === 'ZERO_DEPOSIT_RETURN'
      ? `booking:${bookingId}:complete-after-return`
      : `deposit:${booking.deposit!.id}:complete`;
  await tx.bookingTransitionHistory.create({
    data: {
      bookingId,
      actorId: null,
      actorType: 'SYSTEM',
      command,
      oldStatus: BookingStatus.RETURNED,
      newStatus: BookingStatus.COMPLETED,
      requestId,
    },
  });
  await tx.notificationOutboxEvent.create({
    data: {
      bookingId,
      eventType: BookingEventType.COMPLETED,
      deduplicationKey: bookingEventKey(bookingId, BookingEventType.COMPLETED),
    },
  });
  return 1;
}

@Injectable()
export class DepositService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly paymentPolicy: PaymentPolicyService,
    private readonly provider: FakeSafeDealProvider,
  ) {}

  async checkout(
    borrowerId: string,
    bookingId: string,
    outcome: FakeOperationOutcome,
    idempotencyKey: string,
  ): Promise<ProviderOperationResult> {
    this.paymentPolicy.requireFakeSafeDeal();
    if (!idempotencyKey?.trim()) {
      throw new BadRequestException('Idempotency-Key обязателен');
    }

    return this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
        const booking = await tx.booking.findUnique({
          where: { id: bookingId },
          include: { payment: true, deposit: true },
        });
        if (!booking || booking.borrowerId !== borrowerId) {
          throw new NotFoundException('Бронирование не найдено');
        }
        if (booking.status !== BookingStatus.CONFIRMED) {
          throw new ConflictException({
            code: 'INVALID_BOOKING_TRANSITION',
            message: 'Тестовая оплата доступна только подтверждённой брони',
          });
        }

        const days =
          Math.floor(
            (booking.endDate.getTime() - booking.startDate.getTime()) /
              86_400_000,
          ) + 1;
        const snapshot = readBoundBookingTermsSnapshot(booking.termsSnapshot, {
          borrowerId: booking.borrowerId,
          lenderId: booking.lenderId,
          days,
          totalAmount: booking.totalAmount.toNumber(),
        });
        if (!snapshot || snapshot.paymentScenario !== 'FAKE_SAFE_DEAL') {
          throw new ConflictException({
            code: 'INVALID_BOOKING_PAYMENT_TERMS',
            message: 'Условия тестовой оплаты недействительны',
          });
        }

        const amountMinor = BigInt(snapshot.moneyMinor.total);
        const checkout = await this.provider.checkout({
          idempotencyKey,
          bookingId,
          amountMinor,
          currency: 'RUB',
          outcome,
        });
        if (checkout.outcome !== 'SUCCEEDED') {
          return checkout;
        }

        if (booking.payment) {
          if (
            booking.payment.userId !== borrowerId ||
            booking.payment.status !== PaymentStatus.SUCCEEDED ||
            decimalToMinor(booking.payment.amount) !== amountMinor ||
            !booking.payment.yookassaPaymentId
          ) {
            throw new ConflictException(
              'Payment state conflicts with checkout',
            );
          }
          if (
            booking.deposit &&
            booking.deposit.status !== DepositStatus.HELD
          ) {
            throw new ConflictException(
              'Deposit state conflicts with checkout',
            );
          }
          return {
            outcome: 'SUCCEEDED',
            providerOperationId: booking.payment.yookassaPaymentId,
          };
        }

        if (
          snapshot.moneyMinor.deposit > 0 &&
          (!booking.deposit ||
            booking.deposit.status !== DepositStatus.PENDING ||
            booking.deposit.currency !== 'RUB' ||
            minorToSafeNumber(decimalToMinor(booking.deposit.amount)) !==
              snapshot.moneyMinor.deposit)
        ) {
          throw new ConflictException('Deposit state conflicts with snapshot');
        }
        if (snapshot.moneyMinor.deposit === 0 && booking.deposit) {
          throw new ConflictException(
            'Unexpected deposit for zero-deposit booking',
          );
        }

        const hold = booking.deposit
          ? await this.provider.executeDepositOperation({
              idempotencyKey: `deposit:${booking.deposit.id}:hold`,
              depositId: booking.deposit.id,
              kind: DepositOperationKind.HOLD,
              amountMinor: BigInt(snapshot.moneyMinor.deposit),
              currency: 'RUB',
              outcome: 'SUCCESS',
            })
          : null;
        if (hold && hold.outcome !== 'SUCCEEDED') {
          throw new ConflictException('Fake deposit hold did not succeed');
        }

        await tx.payment.create({
          data: {
            bookingId,
            userId: borrowerId,
            amount: minorToDecimal(amountMinor),
            status: PaymentStatus.SUCCEEDED,
            yookassaPaymentId: checkout.providerOperationId,
          },
        });
        if (booking.deposit && hold?.outcome === 'SUCCEEDED') {
          const completedAt = new Date();
          await tx.bookingDeposit.update({
            where: { id: booking.deposit.id },
            data: { status: DepositStatus.HELD },
          });
          await tx.depositOperation.create({
            data: {
              depositId: booking.deposit.id,
              kind: DepositOperationKind.HOLD,
              amount: minorToDecimal(BigInt(snapshot.moneyMinor.deposit)),
              status: DepositOperationStatus.SUCCEEDED,
              idempotencyKey: `deposit:${booking.deposit.id}:hold`,
              providerOperationId: hold.providerOperationId,
              attempts: 1,
              completedAt,
              nextAttemptAt: completedAt,
            },
          });
        }
        return checkout;
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted },
    );
  }

  async completeAfterDepositSettled(
    bookingId: string,
    now = new Date(),
  ): Promise<number> {
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
      return completeBookingAfterReturnInTransaction(
        tx,
        bookingId,
        now,
        'DEPOSIT_SETTLED',
      );
    });
  }

  async retryFailedOperation(
    adminId: string,
    operationId: string,
    idempotencyKey: string,
    context: AdminAuditContext,
    now = new Date(),
  ): Promise<DepositOperationCommandResponse> {
    this.paymentPolicy.requireFakeSafeDeal();
    const commandKey = idempotencyKey.trim();
    if (!commandKey) {
      throw new BadRequestException('Idempotency-Key обязателен');
    }
    const target = await this.prisma.depositOperation.findUnique({
      where: { id: operationId },
      select: { deposit: { select: { bookingId: true } } },
    });
    if (!target) {
      throw new NotFoundException('Операция залога не найдена');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${target.deposit.bookingId}))`;
      const operation = await tx.depositOperation.findUnique({
        where: { id: operationId },
        include: {
          deposit: {
            include: {
              booking: {
                select: {
                  financialDispute: {
                    select: {
                      status: true,
                      refundToBorrowerAmount: true,
                      releaseToLenderAmount: true,
                    },
                  },
                },
              },
            },
          },
        },
      });
      if (!operation) {
        throw new NotFoundException('Операция залога не найдена');
      }
      const retryKey = `deposit-operation:${operation.id}:retry:${commandKey}`;
      const existing = await tx.depositOperation.findUnique({
        where: { idempotencyKey: retryKey },
      });
      if (existing) {
        if (
          existing.retryOfId !== operation.id ||
          existing.depositId !== operation.depositId ||
          existing.kind !== operation.kind ||
          decimalToMinor(existing.amount) !== decimalToMinor(operation.amount)
        ) {
          throw new ConflictException('Idempotency-Key уже использован');
        }
        return this.toOperationResponse(existing);
      }
      const dispute = operation.deposit.booking.financialDispute;
      const requiredAmount =
        operation.kind === DepositOperationKind.REFUND
          ? dispute?.refundToBorrowerAmount
          : operation.kind === DepositOperationKind.RELEASE_TO_LENDER
            ? dispute?.releaseToLenderAmount
            : null;
      if (
        operation.status !== DepositOperationStatus.FAILED ||
        operation.deposit.status !== DepositStatus.RESOLVING ||
        dispute?.status !== DisputeStatus.UNDER_REVIEW ||
        !requiredAmount ||
        decimalToMinor(requiredAmount) <= 0n ||
        decimalToMinor(requiredAmount) !== decimalToMinor(operation.amount)
      ) {
        throw new ConflictException('Операцию нельзя повторить');
      }
      const anotherRetry = await tx.depositOperation.findFirst({
        where: { retryOfId: operation.id },
        select: { id: true },
      });
      if (anotherRetry) {
        throw new ConflictException('Повтор уже создан');
      }

      const retry = await tx.depositOperation.create({
        data: {
          depositId: operation.depositId,
          kind: operation.kind,
          amount: operation.amount,
          status: DepositOperationStatus.PENDING,
          idempotencyKey: retryKey,
          retryOfId: operation.id,
          nextAttemptAt: now,
        },
      });
      await tx.adminAuditLog.create({
        data: {
          adminId,
          action: 'DEPOSIT_OPERATION_RETRY_CREATED',
          entityType: 'DepositOperation',
          entityId: retry.id,
          capability: AdminCapability.FINANCE,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          metadata: {
            retryOfId: operation.id,
            depositId: operation.depositId,
            requiredCapabilities: [
              AdminCapability.DISPUTE,
              AdminCapability.FINANCE,
            ],
          },
        },
      });
      return this.toOperationResponse(retry);
    });
  }

  private toOperationResponse(operation: {
    id: string;
    depositId: string;
    kind: DepositOperationKind;
    amount: Prisma.Decimal;
    status: DepositOperationStatus;
    retryOfId: string | null;
  }): DepositOperationCommandResponse {
    return {
      id: operation.id,
      depositId: operation.depositId,
      kind: operation.kind,
      amountMinor: minorToSafeNumber(decimalToMinor(operation.amount)),
      status: operation.status,
      retryOfId: operation.retryOfId,
    };
  }
}
