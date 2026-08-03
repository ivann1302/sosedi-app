import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const OUTBOX_POLL_INTERVAL_MS = 5 * 1000;
const OUTBOX_BATCH_SIZE = 50;

@Injectable()
export class BookingOutboxProcessor
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(BookingOutboxProcessor.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    if (process.env.NODE_ENV === 'test') {
      return;
    }

    await this.run();
    this.timer = setInterval(() => void this.run(), OUTBOX_POLL_INTERVAL_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  async processPending(): Promise<number> {
    const pending = await this.prisma.notificationOutboxEvent.findMany({
      where: { processedAt: null },
      select: { id: true },
      orderBy: { createdAt: 'asc' },
      take: OUTBOX_BATCH_SIZE,
    });
    let processed = 0;
    for (const event of pending) {
      processed += await this.deliver(event.id);
    }
    return processed;
  }

  private async deliver(eventId: string): Promise<number> {
    return this.prisma.$transaction(async (tx) => {
      const event = await tx.notificationOutboxEvent.findFirst({
        where: { id: eventId, processedAt: null },
        select: {
          id: true,
          bookingId: true,
          supportTicketId: true,
          recipientId: true,
          itemId: true,
          eventType: true,
          createdAt: true,
          booking: {
            select: { borrowerId: true, lenderId: true },
          },
          supportTicket: {
            select: { userId: true },
          },
        },
      });
      if (!event) {
        return 0;
      }

      const recipientIds = event.recipientId
        ? [event.recipientId]
        : event.booking
          ? [...new Set([event.booking.borrowerId, event.booking.lenderId])]
          : event.supportTicket
            ? [event.supportTicket.userId]
            : [];
      if (recipientIds.length === 0) {
        throw new Error(`Outbox event ${event.id} has no entity`);
      }
      await tx.inboxEvent.createMany({
        data: recipientIds.map((recipientId) => ({
          eventId: event.id,
          recipientId,
          bookingId: event.bookingId,
          supportTicketId: event.supportTicketId,
          itemId: event.itemId,
          eventType: event.eventType,
          createdAt: event.createdAt,
        })),
        skipDuplicates: true,
      });
      const tokens = await tx.devicePushToken.findMany({
        where: { userId: { in: recipientIds } },
        select: { id: true },
      });
      await tx.pushDelivery.createMany({
        data: tokens.map((token) => ({
          eventId: event.id,
          tokenId: token.id,
        })),
        skipDuplicates: true,
      });
      await tx.notificationOutboxEvent.updateMany({
        where: { id: event.id, processedAt: null },
        data: { processedAt: new Date() },
      });
      return 1;
    });
  }

  private async run(): Promise<void> {
    try {
      await this.processPending();
    } catch (error) {
      this.logger.error('Не удалось обработать notification outbox', error);
    }
  }
}
