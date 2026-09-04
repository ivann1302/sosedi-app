import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import {
  BookingStatus,
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const DEADLINE_POLL_INTERVAL_MS = 60 * 1000;

@Injectable()
export class DepositDeadlineService
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(DepositDeadlineService.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    if (process.env.NODE_ENV === 'test') {
      return;
    }
    await this.run();
    this.timer = setInterval(() => void this.run(), DEADLINE_POLL_INTERVAL_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  async processDue(now = new Date()): Promise<number> {
    const candidates = await this.prisma.bookingDeposit.findMany({
      where: {
        status: DepositStatus.HELD,
        disputeWindowEndsAt: { lte: now },
      },
      select: { id: true, bookingId: true },
      orderBy: { disputeWindowEndsAt: 'asc' },
    });
    let scheduled = 0;
    for (const candidate of candidates) {
      scheduled += await this.prisma.$transaction(async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${candidate.bookingId}))`;
        const deposit = await tx.bookingDeposit.findUnique({
          where: { id: candidate.id },
          include: {
            booking: {
              select: {
                status: true,
                financialDispute: { select: { id: true } },
              },
            },
          },
        });
        if (
          !deposit ||
          deposit.status !== DepositStatus.HELD ||
          !deposit.disputeWindowEndsAt ||
          deposit.disputeWindowEndsAt > now ||
          deposit.booking.status !== BookingStatus.RETURNED ||
          deposit.booking.financialDispute
        ) {
          return 0;
        }

        const idempotencyKey = `deposit:${deposit.id}:auto-refund`;
        const existing = await tx.depositOperation.findUnique({
          where: { idempotencyKey },
          select: { id: true },
        });
        if (existing) {
          return 0;
        }
        await tx.depositOperation.create({
          data: {
            depositId: deposit.id,
            kind: DepositOperationKind.REFUND,
            amount: deposit.amount,
            status: DepositOperationStatus.PENDING,
            idempotencyKey,
            nextAttemptAt: now,
          },
        });
        await tx.bookingDeposit.update({
          where: { id: deposit.id },
          data: { status: DepositStatus.RESOLVING },
        });
        return 1;
      });
    }
    return scheduled;
  }

  private async run(): Promise<void> {
    try {
      await this.processDue();
    } catch (error) {
      this.logger.error('Не удалось запланировать возврат залога', error);
    }
  }
}
