import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  AppService,
  DEFAULT_MAX_CLOCK_SKEW_MS,
  LATEST_REQUIRED_MIGRATION,
} from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { RedisService } from './redis/redis.service';

describe('AppService readiness', () => {
  const prisma = {
    $queryRaw: jest.fn(),
  };
  const redisClient = {
    ping: jest.fn(),
  };
  const redis = {
    getClient: jest.fn(() => redisClient),
  };
  const service = new AppService(
    prisma as unknown as PrismaService,
    redis as unknown as RedisService,
    new ConfigService(),
  );

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('tracks the latest Prisma migration used by this release', () => {
    const latestMigration = readdirSync(
      resolve(process.cwd(), 'prisma/migrations'),
      { withFileTypes: true },
    )
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort()
      .at(-1);

    expect(LATEST_REQUIRED_MIGRATION).toBe(latestMigration);
  });

  it('is ready only when database, migrations and Redis are ready', async () => {
    prisma.$queryRaw.mockResolvedValue([
      {
        databaseReady: true,
        migrationReady: true,
        databaseTime: new Date(),
      },
    ]);
    redisClient.ping.mockResolvedValue('PONG');

    await expect(service.getReadiness()).resolves.toEqual({
      status: 'ready',
      checks: {
        database: 'ok',
        migrations: 'ok',
        redis: 'ok',
        clock: 'ok',
      },
    });
  });

  it('returns a safe 503 when a critical dependency is unavailable', async () => {
    prisma.$queryRaw.mockResolvedValue([
      {
        databaseReady: true,
        migrationReady: true,
        databaseTime: new Date(),
      },
    ]);
    redisClient.ping.mockRejectedValue(new Error('redis topology details'));

    await expect(service.getReadiness()).rejects.toEqual(
      expect.objectContaining<ServiceUnavailableException>({
        message: 'Сервис ещё не готов принимать трафик',
      }),
    );
  });

  it('is not ready before the required migration is applied', async () => {
    prisma.$queryRaw.mockResolvedValue([
      {
        databaseReady: true,
        migrationReady: false,
        databaseTime: new Date(),
      },
    ]);
    redisClient.ping.mockResolvedValue('PONG');

    await expect(service.getReadiness()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('is not ready when the database and application clocks drift', async () => {
    const now = Date.parse('2026-07-29T12:00:00.000Z');
    const dateNow = jest.spyOn(Date, 'now').mockReturnValue(now);
    prisma.$queryRaw.mockResolvedValue([
      {
        databaseReady: true,
        migrationReady: true,
        databaseTime: new Date(now - DEFAULT_MAX_CLOCK_SKEW_MS - 1),
      },
    ]);
    redisClient.ping.mockResolvedValue('PONG');

    await expect(service.getReadiness()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
    dateNow.mockRestore();
  });

  it('rejects an unsafe clock-skew threshold at startup', () => {
    expect(
      () =>
        new AppService(
          prisma as unknown as PrismaService,
          redis as unknown as RedisService,
          new ConfigService({ MAX_CLOCK_SKEW_MS: '60001' }),
        ),
    ).toThrow('MAX_CLOCK_SKEW_MS must be an integer between 1000 and 60000');
  });
});
