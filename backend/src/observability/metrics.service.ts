import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma, PushDeliveryStatus } from '@prisma/client';
import { Queue, QueueEvents, type ConnectionOptions } from 'bullmq';
import { timingSafeEqual } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { PHOTO_PROCESSING_QUEUE_NAME } from '../upload/photo-processing.queue';

const HTTP_DURATION_BUCKETS = [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5] as const;
const METRICS_TOKEN_MIN_LENGTH = 32;
const OPERATIONS = [
  'sms_send',
  'otp_global_limit',
  'upload_processing',
  'payment_checkout',
  'payment_webhook',
  'payout',
  'refund',
  'receipt',
  'backup',
] as const;

type DatabaseStats = {
  connections: bigint;
  maxConnections: bigint;
  databaseBytes: bigint;
};

type Operation = (typeof OPERATIONS)[number];
type OperationResult = 'success' | 'failure';

@Injectable()
export class MetricsService implements OnModuleInit, OnModuleDestroy {
  private readonly token: string;
  private readonly startedAtSeconds = Date.now() / 1000;
  private readonly httpRequests = new Map<string, number>();
  private readonly durationBucketCounts = HTTP_DURATION_BUCKETS.map(() => 0);
  private readonly operationCounts = new Map<string, number>();
  private durationCount = 0;
  private durationSum = 0;
  private stalledJobs = 0;
  private photoQueue: Queue | null = null;
  private photoQueueEvents: QueueEvents | null = null;

  constructor(
    config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {
    this.token = config.get<string>('METRICS_TOKEN') ?? '';
    if (
      config.get<string>('NODE_ENV') === 'production' &&
      this.token.length < METRICS_TOKEN_MIN_LENGTH
    ) {
      throw new Error(
        `METRICS_TOKEN must contain at least ${METRICS_TOKEN_MIN_LENGTH} characters in production`,
      );
    }

    if (config.get<string>('NODE_ENV') !== 'test') {
      const connection = this.getConnectionOptions(config);
      this.photoQueue = new Queue(PHOTO_PROCESSING_QUEUE_NAME, { connection });
      this.photoQueueEvents = new QueueEvents(PHOTO_PROCESSING_QUEUE_NAME, {
        connection,
      });
    }
  }

  onModuleInit(): void {
    this.photoQueueEvents?.on('stalled', () => {
      this.stalledJobs += 1;
    });
  }

  async onModuleDestroy(): Promise<void> {
    await Promise.all([
      this.photoQueue?.close(),
      this.photoQueueEvents?.close(),
    ]);
  }

  isAuthorized(authorization?: string): boolean {
    if (this.token.length < METRICS_TOKEN_MIN_LENGTH || !authorization) {
      return false;
    }

    const expected = Buffer.from(`Bearer ${this.token}`);
    const received = Buffer.from(authorization);
    return (
      expected.length === received.length && timingSafeEqual(expected, received)
    );
  }

  recordHttpRequest(
    method: string,
    statusCode: number,
    durationSeconds: number,
  ): void {
    const key = `${method.toUpperCase()}:${statusCode}`;
    this.httpRequests.set(key, (this.httpRequests.get(key) ?? 0) + 1);
    this.durationCount += 1;
    this.durationSum += durationSeconds;
    HTTP_DURATION_BUCKETS.forEach((upperBound, index) => {
      if (durationSeconds <= upperBound) {
        this.durationBucketCounts[index] += 1;
      }
    });
  }

  recordOperation(operation: Operation, result: OperationResult): void {
    const key = `${operation}:${result}`;
    this.operationCounts.set(key, (this.operationCounts.get(key) ?? 0) + 1);
  }

  async render(): Promise<string> {
    const [database, redis, queue, outbox, push] = await Promise.all([
      this.getDatabaseStats(),
      this.getRedisStats(),
      this.getQueueStats(),
      this.getOutboxStats(),
      this.getPushStats(),
    ]);
    const lines: string[] = [
      '# HELP sosedi_process_start_time_seconds Backend process start time.',
      '# TYPE sosedi_process_start_time_seconds gauge',
      `sosedi_process_start_time_seconds ${this.startedAtSeconds}`,
      '# HELP sosedi_http_requests_total HTTP requests by method and status.',
      '# TYPE sosedi_http_requests_total counter',
    ];

    for (const [key, count] of [...this.httpRequests.entries()].sort()) {
      const [method, status] = key.split(':');
      lines.push(
        `sosedi_http_requests_total{method="${method}",status="${status}"} ${count}`,
      );
    }

    lines.push(
      '# HELP sosedi_http_request_duration_seconds HTTP request duration.',
      '# TYPE sosedi_http_request_duration_seconds histogram',
    );
    HTTP_DURATION_BUCKETS.forEach((upperBound, index) => {
      lines.push(
        `sosedi_http_request_duration_seconds_bucket{le="${upperBound}"} ${this.durationBucketCounts[index]}`,
      );
    });
    lines.push(
      `sosedi_http_request_duration_seconds_bucket{le="+Inf"} ${this.durationCount}`,
      `sosedi_http_request_duration_seconds_sum ${this.durationSum}`,
      `sosedi_http_request_duration_seconds_count ${this.durationCount}`,
      '# HELP sosedi_database_connections Current connections to the application database.',
      '# TYPE sosedi_database_connections gauge',
      `sosedi_database_connections ${database.connections}`,
      '# HELP sosedi_database_max_connections PostgreSQL max_connections.',
      '# TYPE sosedi_database_max_connections gauge',
      `sosedi_database_max_connections ${database.maxConnections}`,
      '# HELP sosedi_database_size_bytes Current application database size.',
      '# TYPE sosedi_database_size_bytes gauge',
      `sosedi_database_size_bytes ${database.databaseBytes}`,
      '# HELP sosedi_redis_memory_bytes Redis memory usage and configured maximum.',
      '# TYPE sosedi_redis_memory_bytes gauge',
      `sosedi_redis_memory_bytes{kind="used"} ${redis.used}`,
      `sosedi_redis_memory_bytes{kind="max"} ${redis.max}`,
      '# HELP sosedi_bullmq_jobs Photo processing jobs by state.',
      '# TYPE sosedi_bullmq_jobs gauge',
      `sosedi_bullmq_jobs{queue="${PHOTO_PROCESSING_QUEUE_NAME}",state="waiting"} ${queue.wait}`,
      `sosedi_bullmq_jobs{queue="${PHOTO_PROCESSING_QUEUE_NAME}",state="active"} ${queue.active}`,
      `sosedi_bullmq_jobs{queue="${PHOTO_PROCESSING_QUEUE_NAME}",state="failed"} ${queue.failed}`,
      `sosedi_bullmq_jobs{queue="${PHOTO_PROCESSING_QUEUE_NAME}",state="delayed"} ${queue.delayed}`,
      '# HELP sosedi_bullmq_stalled_total BullMQ stalled job events since process start.',
      '# TYPE sosedi_bullmq_stalled_total counter',
      `sosedi_bullmq_stalled_total{queue="${PHOTO_PROCESSING_QUEUE_NAME}"} ${this.stalledJobs}`,
      '# HELP sosedi_outbox_pending Notification outbox events awaiting delivery.',
      '# TYPE sosedi_outbox_pending gauge',
      `sosedi_outbox_pending ${outbox.pending}`,
      '# HELP sosedi_outbox_oldest_pending_age_seconds Age of the oldest pending outbox event.',
      '# TYPE sosedi_outbox_oldest_pending_age_seconds gauge',
      `sosedi_outbox_oldest_pending_age_seconds ${outbox.oldestAgeSeconds}`,
      '# HELP sosedi_push_deliveries Push delivery records by state.',
      '# TYPE sosedi_push_deliveries gauge',
      ...Object.values(PushDeliveryStatus).map(
        (status) =>
          `sosedi_push_deliveries{status="${status}"} ${push.counts[status]}`,
      ),
      '# HELP sosedi_push_delivery_oldest_pending_age_seconds Age of the oldest outstanding push delivery.',
      '# TYPE sosedi_push_delivery_oldest_pending_age_seconds gauge',
      `sosedi_push_delivery_oldest_pending_age_seconds ${push.oldestAgeSeconds}`,
      '# HELP sosedi_operation_total Provider and worker outcomes without user identifiers.',
      '# TYPE sosedi_operation_total counter',
    );

    for (const operation of OPERATIONS) {
      for (const result of ['success', 'failure'] as const) {
        const count = this.operationCounts.get(`${operation}:${result}`) ?? 0;
        lines.push(
          `sosedi_operation_total{operation="${operation}",result="${result}"} ${count}`,
        );
      }
    }

    return `${lines.join('\n')}\n`;
  }

  private async getDatabaseStats(): Promise<DatabaseStats> {
    const rows = await this.prisma.$queryRaw<DatabaseStats[]>(Prisma.sql`
      SELECT
        (
          SELECT COUNT(*)
          FROM pg_stat_activity
          WHERE datname = current_database()
        )::bigint AS "connections",
        current_setting('max_connections')::bigint AS "maxConnections",
        pg_database_size(current_database())::bigint AS "databaseBytes"
    `);
    if (rows.length !== 1) {
      throw new Error('Database metrics query returned an invalid result');
    }
    return rows[0];
  }

  private async getRedisStats(): Promise<{ used: number; max: number }> {
    const info = await this.redis.getClient().info('memory');
    return {
      used: this.readRedisNumber(info, 'used_memory'),
      max: this.readRedisNumber(info, 'maxmemory'),
    };
  }

  private async getQueueStats(): Promise<{
    wait: number;
    active: number;
    failed: number;
    delayed: number;
  }> {
    if (!this.photoQueue) {
      return { wait: 0, active: 0, failed: 0, delayed: 0 };
    }
    const counts = await this.photoQueue.getJobCounts(
      'wait',
      'active',
      'failed',
      'delayed',
    );
    return {
      wait: counts.wait ?? 0,
      active: counts.active ?? 0,
      failed: counts.failed ?? 0,
      delayed: counts.delayed ?? 0,
    };
  }

  private async getOutboxStats(): Promise<{
    pending: number;
    oldestAgeSeconds: number;
  }> {
    const result = await this.prisma.notificationOutboxEvent.aggregate({
      where: { processedAt: null },
      _count: true,
      _min: { createdAt: true },
    });
    return {
      pending: result._count,
      oldestAgeSeconds: result._min.createdAt
        ? Math.max(
            0,
            Math.floor((Date.now() - result._min.createdAt.getTime()) / 1000),
          )
        : 0,
    };
  }

  private async getPushStats(): Promise<{
    counts: Record<PushDeliveryStatus, number>;
    oldestAgeSeconds: number;
  }> {
    const [groups, pending] = await Promise.all([
      this.prisma.pushDelivery.groupBy({
        by: ['status'],
        _count: true,
      }),
      this.prisma.pushDelivery.aggregate({
        where: {
          status: {
            in: [
              PushDeliveryStatus.PENDING,
              PushDeliveryStatus.PROCESSING,
              PushDeliveryStatus.RETRY,
            ],
          },
        },
        _min: { createdAt: true },
      }),
    ]);
    const counts = Object.fromEntries(
      Object.values(PushDeliveryStatus).map((status) => [status, 0]),
    ) as Record<PushDeliveryStatus, number>;
    for (const group of groups) {
      counts[group.status] = group._count;
    }
    return {
      counts,
      oldestAgeSeconds: pending._min.createdAt
        ? Math.max(
            0,
            Math.floor((Date.now() - pending._min.createdAt.getTime()) / 1000),
          )
        : 0,
    };
  }

  private readRedisNumber(info: string, name: string): number {
    const line = info
      .split('\n')
      .find((candidate) => candidate.startsWith(`${name}:`));
    const value = Number(line?.slice(name.length + 1).trim() ?? 0);
    return Number.isFinite(value) ? value : 0;
  }

  private getConnectionOptions(config: ConfigService): ConnectionOptions {
    const redisUrl = new URL(
      config.get<string>('REDIS_URL') ?? 'redis://localhost:6379',
    );
    return {
      host: redisUrl.hostname,
      port: Number(redisUrl.port || 6379),
      username: redisUrl.username || undefined,
      password: redisUrl.password || undefined,
      db: redisUrl.pathname ? Number(redisUrl.pathname.slice(1)) || 0 : 0,
      maxRetriesPerRequest: 1,
    };
  }
}
