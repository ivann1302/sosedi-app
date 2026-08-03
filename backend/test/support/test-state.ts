import type { INestApplication } from '@nestjs/common';
import { PrismaService } from '../../src/prisma/prisma.service';
import { RedisService } from '../../src/redis/redis.service';

const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '[::1]']);

export async function resetTestState(app: INestApplication): Promise<void> {
  assertSafeTestTargets();

  const prisma = app.get(PrismaService);
  const redis = app.get(RedisService).getClient();

  await prisma.$executeRawUnsafe('TRUNCATE TABLE "admin_audit_logs"');
  await prisma.$executeRawUnsafe('TRUNCATE TABLE "booking_transition_history"');
  await prisma.$transaction([
    prisma.adminRecoveryCode.deleteMany(),
    prisma.adminMfaCredential.deleteMany(),
    prisma.payment.deleteMany(),
    prisma.supportAttachment.deleteMany(),
    prisma.supportMessage.deleteMany(),
    prisma.supportTicket.deleteMany(),
    prisma.userReport.deleteMany(),
    prisma.userBlock.deleteMany(),
    prisma.devicePushToken.deleteMany(),
    prisma.bookingEvidence.deleteMany(),
    prisma.bookingAct.deleteMany(),
    prisma.uploadIntent.deleteMany(),
    prisma.itemPhoto.deleteMany(),
    prisma.booking.deleteMany(),
    prisma.kycDocument.deleteMany(),
    prisma.item.deleteMany(),
    prisma.category.deleteMany(),
    prisma.user.deleteMany(),
  ]);
  await redis.flushdb();
}

function assertSafeTestTargets(): void {
  if (process.env.NODE_ENV !== 'test') {
    throw new Error('Test state reset requires NODE_ENV=test');
  }

  const databaseUrl = parseRequiredUrl('DATABASE_URL');
  const databaseName = decodeURIComponent(databaseUrl.pathname.slice(1));
  if (
    !LOCAL_HOSTS.has(databaseUrl.hostname) ||
    databaseUrl.port === '' ||
    databaseUrl.port === '5432' ||
    databaseName !== 'sosedi_test'
  ) {
    throw new Error('Refusing to reset a non-local sosedi_test database');
  }

  const redisUrl = parseRequiredUrl('REDIS_URL');
  if (
    !LOCAL_HOSTS.has(redisUrl.hostname) ||
    redisUrl.port === '' ||
    redisUrl.port === '6379' ||
    redisUrl.pathname !== '/15'
  ) {
    throw new Error('Refusing to reset a non-local Redis test database');
  }
}

function parseRequiredUrl(name: 'DATABASE_URL' | 'REDIS_URL'): URL {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required for e2e tests`);
  }

  return new URL(value);
}
