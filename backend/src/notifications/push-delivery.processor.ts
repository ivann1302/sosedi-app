import {
  Inject,
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import { PushDeliveryStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  PUSH_PROVIDER,
  PushDeliveryOutcome,
  type PushProvider,
} from './push-provider';

const PUSH_POLL_INTERVAL_MS = 5 * 1000;
const PUSH_BATCH_SIZE = 50;
const PUSH_PROCESSING_LEASE_MS = 60 * 1000;
const PUSH_INITIAL_RETRY_MS = 30 * 1000;
const PUSH_MAX_RETRY_MS = 60 * 60 * 1000;

@Injectable()
export class PushDeliveryProcessor
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(PushDeliveryProcessor.name);
  private timer: NodeJS.Timeout | null = null;

  constructor(
    private readonly prisma: PrismaService,
    @Inject(PUSH_PROVIDER) private readonly provider: PushProvider,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    if (
      process.env.NODE_ENV === 'test' ||
      process.env.PUSH_DELIVERY_ENABLED !== 'true'
    ) {
      return;
    }

    await this.run();
    this.timer = setInterval(() => void this.run(), PUSH_POLL_INTERVAL_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) {
      clearInterval(this.timer);
    }
  }

  async processPending(now: Date = new Date()): Promise<number> {
    const pending = await this.prisma.pushDelivery.findMany({
      where: {
        OR: [
          {
            status: {
              in: [PushDeliveryStatus.PENDING, PushDeliveryStatus.RETRY],
            },
            nextAttemptAt: { lte: now },
          },
          {
            status: PushDeliveryStatus.PROCESSING,
            processingUntil: { lte: now },
          },
        ],
      },
      select: { id: true },
      orderBy: [{ nextAttemptAt: 'asc' }, { createdAt: 'asc' }],
      take: PUSH_BATCH_SIZE,
    });

    let processed = 0;
    for (const delivery of pending) {
      processed += await this.deliver(delivery.id, now);
    }
    return processed;
  }

  private async deliver(deliveryId: string, now: Date): Promise<number> {
    const claimUntil = new Date(now.getTime() + PUSH_PROCESSING_LEASE_MS);
    const claimed = await this.prisma.pushDelivery.updateMany({
      where: {
        id: deliveryId,
        OR: [
          {
            status: {
              in: [PushDeliveryStatus.PENDING, PushDeliveryStatus.RETRY],
            },
            nextAttemptAt: { lte: now },
          },
          {
            status: PushDeliveryStatus.PROCESSING,
            processingUntil: { lte: now },
          },
        ],
      },
      data: {
        status: PushDeliveryStatus.PROCESSING,
        processingUntil: claimUntil,
      },
    });
    if (claimed.count === 0) {
      return 0;
    }

    const delivery = await this.prisma.pushDelivery.findUnique({
      where: { id: deliveryId },
      select: {
        id: true,
        eventId: true,
        attempts: true,
        token: {
          select: { id: true, provider: true, token: true },
        },
      },
    });
    if (!delivery) {
      return 0;
    }

    let outcome: PushDeliveryOutcome;
    let errorCode: string | null = null;
    try {
      outcome = await this.provider.send(delivery.token.provider, {
        token: delivery.token.token,
        eventId: delivery.eventId,
      });
    } catch {
      outcome = PushDeliveryOutcome.RETRY;
      errorCode = 'PROVIDER_ERROR';
    }

    if (outcome === PushDeliveryOutcome.DELIVERED) {
      await this.prisma.pushDelivery.updateMany({
        where: { id: delivery.id, status: PushDeliveryStatus.PROCESSING },
        data: {
          status: PushDeliveryStatus.DELIVERED,
          attempts: { increment: 1 },
          processingUntil: null,
          deliveredAt: now,
          lastErrorCode: null,
        },
      });
      return 1;
    }

    if (outcome === PushDeliveryOutcome.INVALID_TOKEN) {
      await this.prisma.devicePushToken.deleteMany({
        where: { id: delivery.token.id, token: delivery.token.token },
      });
      return 1;
    }

    const retryNumber = delivery.attempts + 1;
    const retryDelay = Math.min(
      PUSH_INITIAL_RETRY_MS * 2 ** Math.min(retryNumber - 1, 10),
      PUSH_MAX_RETRY_MS,
    );
    await this.prisma.pushDelivery.updateMany({
      where: { id: delivery.id, status: PushDeliveryStatus.PROCESSING },
      data: {
        status: PushDeliveryStatus.RETRY,
        attempts: { increment: 1 },
        processingUntil: null,
        nextAttemptAt: new Date(now.getTime() + retryDelay),
        lastErrorCode: errorCode ?? 'PROVIDER_RETRY',
      },
    });
    return 1;
  }

  private async run(): Promise<void> {
    try {
      await this.processPending();
    } catch (error) {
      this.logger.error('Не удалось обработать push delivery', error);
    }
  }
}
