import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { MetricsService } from './metrics.service';

describe('MetricsService', () => {
  const token = 'metrics-token-with-at-least-32-characters';

  function createService(): MetricsService {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([
        {
          connections: 4n,
          maxConnections: 100n,
          databaseBytes: 2048n,
        },
      ]),
      notificationOutboxEvent: {
        aggregate: jest.fn().mockResolvedValue({
          _count: 2,
          _min: { createdAt: new Date(Date.now() - 5_000) },
        }),
      },
      pushDelivery: {
        groupBy: jest.fn().mockResolvedValue([
          { status: 'PENDING', _count: 1 },
          { status: 'RETRY', _count: 2 },
        ]),
        aggregate: jest.fn().mockResolvedValue({
          _min: { createdAt: new Date(Date.now() - 10_000) },
        }),
      },
    };
    const redis = {
      getClient: jest.fn().mockReturnValue({
        info: jest
          .fn()
          .mockResolvedValue('used_memory:1024\r\nmaxmemory:4096\r\n'),
      }),
    };

    return new MetricsService(
      new ConfigService({ NODE_ENV: 'test', METRICS_TOKEN: token }),
      prisma as unknown as PrismaService,
      redis as unknown as RedisService,
    );
  }

  it('requires the exact bearer token', () => {
    const service = createService();

    expect(service.isAuthorized()).toBe(false);
    expect(service.isAuthorized(`Bearer ${token}-wrong`)).toBe(false);
    expect(service.isAuthorized(`Bearer ${token}`)).toBe(true);
  });

  it('renders operational metrics without user identifiers', async () => {
    const service = createService();
    service.recordHttpRequest('get', 503, 0.08);
    service.recordOperation('sms_send', 'failure');
    service.recordOperation('otp_global_limit', 'failure');

    const output = await service.render();

    expect(output).toContain(
      'sosedi_http_requests_total{method="GET",status="503"} 1',
    );
    expect(output).toContain(
      'sosedi_http_request_duration_seconds_bucket{le="0.1"} 1',
    );
    expect(output).toContain('sosedi_database_connections 4');
    expect(output).toContain('sosedi_redis_memory_bytes{kind="used"} 1024');
    expect(output).toContain('sosedi_outbox_pending 2');
    expect(output).toContain('sosedi_push_deliveries{status="PENDING"} 1');
    expect(output).toContain('sosedi_push_deliveries{status="RETRY"} 2');
    expect(output).toContain('sosedi_push_delivery_oldest_pending_age_seconds');
    expect(output).toContain(
      'sosedi_operation_total{operation="sms_send",result="failure"} 1',
    );
    expect(output).toContain(
      'sosedi_operation_total{operation="otp_global_limit",result="failure"} 1',
    );
    expect(output).not.toContain(token);
  });

  it('rejects a short production metrics token', () => {
    expect(
      () =>
        new MetricsService(
          new ConfigService({
            NODE_ENV: 'production',
            METRICS_TOKEN: 'short',
          }),
          {} as PrismaService,
          {} as RedisService,
        ),
    ).toThrow('METRICS_TOKEN must contain at least 32 characters');
  });
});
