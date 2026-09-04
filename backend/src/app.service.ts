import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { PrismaService } from './prisma/prisma.service';
import { RedisService } from './redis/redis.service';

export type HealthResponse = {
  status: 'ok';
};

export type ReadinessResponse = {
  status: 'ready';
  checks: {
    database: 'ok';
    migrations: 'ok';
    redis: 'ok';
    clock: 'ok';
  };
};

export const LATEST_REQUIRED_MIGRATION =
  '20260904000300_widen_financial_dispute_description';
export const DEFAULT_MAX_CLOCK_SKEW_MS = 5_000;
const READINESS_TIMEOUT_MS = 2_000;

@Injectable()
export class AppService {
  private readonly maxClockSkewMs: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    config: ConfigService,
  ) {
    const configured = config.get<string | number>('MAX_CLOCK_SKEW_MS');
    const parsed =
      configured === undefined ? DEFAULT_MAX_CLOCK_SKEW_MS : Number(configured);
    if (!Number.isInteger(parsed) || parsed < 1_000 || parsed > 60_000) {
      throw new Error(
        'MAX_CLOCK_SKEW_MS must be an integer between 1000 and 60000',
      );
    }
    this.maxClockSkewMs = parsed;
  }

  getHealth(): HealthResponse {
    return { status: 'ok' };
  }

  getLiveness(): HealthResponse {
    return { status: 'ok' };
  }

  async getReadiness(): Promise<ReadinessResponse> {
    try {
      await Promise.all([
        this.withTimeout(this.checkDatabaseAndMigrations()),
        this.withTimeout(this.redis.getClient().ping()),
      ]);
    } catch {
      throw new ServiceUnavailableException({
        code: 'NOT_READY',
        message: 'Сервис ещё не готов принимать трафик',
      });
    }

    return {
      status: 'ready',
      checks: {
        database: 'ok',
        migrations: 'ok',
        redis: 'ok',
        clock: 'ok',
      },
    };
  }

  private async checkDatabaseAndMigrations(): Promise<void> {
    const queryStartedAt = Date.now();
    const rows = await this.prisma.$queryRaw<
      Array<{
        databaseReady: boolean;
        migrationReady: boolean;
        databaseTime: Date | string;
      }>
    >(Prisma.sql`
      SELECT
        TRUE AS "databaseReady",
        clock_timestamp() AS "databaseTime",
        EXISTS (
          SELECT 1
          FROM "_prisma_migrations"
          WHERE migration_name = ${LATEST_REQUIRED_MIGRATION}
            AND finished_at IS NOT NULL
            AND rolled_back_at IS NULL
        ) AND NOT EXISTS (
          SELECT 1
          FROM "_prisma_migrations"
          WHERE finished_at IS NULL
            AND rolled_back_at IS NULL
        ) AS "migrationReady"
    `);
    const queryFinishedAt = Date.now();

    if (rows.length !== 1 || rows[0].databaseReady !== true) {
      throw new Error('Database readiness failed');
    }
    if (rows[0].migrationReady !== true) {
      throw new Error('Migration readiness failed');
    }
    const databaseTime = new Date(rows[0].databaseTime).getTime();
    if (
      !Number.isFinite(databaseTime) ||
      databaseTime < queryStartedAt - this.maxClockSkewMs ||
      databaseTime > queryFinishedAt + this.maxClockSkewMs
    ) {
      throw new Error('Clock readiness failed');
    }
  }

  private withTimeout<T>(operation: Promise<T>): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const timeout = setTimeout(
        () => reject(new Error('Readiness check timed out')),
        READINESS_TIMEOUT_MS,
      );
      operation.then(
        (value) => {
          clearTimeout(timeout);
          resolve(value);
        },
        (error: unknown) => {
          clearTimeout(timeout);
          reject(error instanceof Error ? error : new Error('Check failed'));
        },
      );
    });
  }
}
