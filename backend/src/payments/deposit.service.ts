import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  DisputeStatus,
  PaymentStatus,
  Prisma,
} from '@prisma/client';
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
        !booking.deposit?.disputeWindowEndsAt ||
        booking.deposit.disputeWindowEndsAt > now ||
        (booking.financialDispute &&
          booking.financialDispute.status !== DisputeStatus.RESOLVED)
      ) {
        return 0;
      }
      assertDepositSettledForCompletionOrPayout(booking.deposit);

      const completed = await tx.booking.updateMany({
        where: { id: bookingId, status: BookingStatus.RETURNED },
        data: { status: BookingStatus.COMPLETED },
      });
      if (completed.count === 0) {
        return 0;
      }
      await tx.bookingTransitionHistory.create({
        data: {
          bookingId,
          actorId: null,
          actorType: 'SYSTEM',
          command: 'COMPLETE_AFTER_DEPOSIT_SETTLED',
          oldStatus: BookingStatus.RETURNED,
          newStatus: BookingStatus.COMPLETED,
          requestId: `deposit:${booking.deposit.id}:complete`,
        },
      });
      await tx.notificationOutboxEvent.create({
        data: {
          bookingId,
          eventType: BookingEventType.COMPLETED,
          deduplicationKey: bookingEventKey(
            bookingId,
            BookingEventType.COMPLETED,
          ),
        },
      });
      return 1;
    });
  }
}
