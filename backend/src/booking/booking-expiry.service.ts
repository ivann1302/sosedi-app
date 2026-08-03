import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import { BookingStatus } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { BookingEventType, bookingEventKey } from './booking-events';

export const BOOKING_PENDING_TIMEOUT_REASON = 'PENDING_TIMEOUT';
const BOOKING_EXPIRY_INTERVAL_MS = 60 * 1000;

@Injectable()
export class BookingExpiryService
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(BookingExpiryService.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    if (process.env.NODE_ENV === 'test') {
      return;
    }

    await this.runCleanup();
    this.timer = setInterval(
      () => void this.runCleanup(),
      BOOKING_EXPIRY_INTERVAL_MS,
    );
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  async expirePending(now = new Date()): Promise<number> {
    const candidates = await this.prisma.booking.findMany({
      where: {
        status: BookingStatus.PENDING,
        expiresAt: { lte: now },
      },
      select: { id: true },
    });
    let expiredCount = 0;
    const requestId = randomUUID();

    for (const candidate of candidates) {
      expiredCount += await this.prisma.$transaction(async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${candidate.id}))`;
        const result = await tx.booking.updateMany({
          where: {
            id: candidate.id,
            status: BookingStatus.PENDING,
            expiresAt: { lte: now },
          },
          data: {
            status: BookingStatus.CANCELLED,
            cancellationReason: BOOKING_PENDING_TIMEOUT_REASON,
          },
        });
        if (result.count === 0) {
          return 0;
        }
        await tx.bookingTransitionHistory.create({
          data: {
            bookingId: candidate.id,
            actorId: null,
            actorType: 'SYSTEM',
            command: 'EXPIRE',
            oldStatus: BookingStatus.PENDING,
            newStatus: BookingStatus.CANCELLED,
            reason: BOOKING_PENDING_TIMEOUT_REASON,
            requestId,
          },
        });
        await tx.notificationOutboxEvent.create({
          data: {
            bookingId: candidate.id,
            eventType: BookingEventType.PENDING_TIMEOUT,
            deduplicationKey: bookingEventKey(
              candidate.id,
              BookingEventType.PENDING_TIMEOUT,
            ),
          },
        });
        return 1;
      });
    }

    return expiredCount;
  }

  private async runCleanup(): Promise<void> {
    try {
      await this.expirePending();
    } catch (error) {
      this.logger.error('Не удалось освободить истёкшие бронирования', error);
    }
  }
}
