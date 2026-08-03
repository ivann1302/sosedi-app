import {
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import type Redis from 'ioredis';
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import { AdminAuthUser } from '../auth/auth.types';
import { parseDurationToSeconds } from '../auth/auth.util';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import type { AdminAuditContext } from './admin-audit-context';
import { AdminMfaService } from './admin-mfa.service';

const MAX_ADMIN_SESSION_SECONDS = 15 * 60;
export const ADMIN_SESSION_COOKIE = '__Host-sosedi_admin';
export const ADMIN_CSRF_COOKIE = '__Host-sosedi_admin_csrf';

export type AdminSessionResponse = {
  sessionId: string;
  csrfToken: string;
  expiresInSeconds: number;
};

type StoredAdminSession = {
  userId: string;
  sessionVersion: number;
  csrfTokenHash: string;
};

@Injectable()
export class AdminSessionService {
  private readonly redis: Redis;

  constructor(
    private readonly mfa: AdminMfaService,
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly config: ConfigService,
  ) {
    this.redis = this.redisService.getClient();
  }

  async stepUp(
    userId: string,
    code: string,
    context: AdminAuditContext,
  ): Promise<AdminSessionResponse> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        role: true,
        adminCapabilities: true,
        isBlocked: true,
        sessionVersion: true,
        deletedAt: true,
      },
    });
    if (
      !user ||
      user.role !== UserRole.ADMIN ||
      user.isBlocked ||
      user.deletedAt
    ) {
      throw new UnauthorizedException('Доступ администратора отозван');
    }
    const expiresInSeconds = this.getAdminSessionTtl();
    await this.mfa.verifyStepUp(userId, code, context);
    await this.prisma.adminAuditLog.create({
      data: {
        adminId: userId,
        action: 'ADMIN_STEP_UP_SUCCEEDED',
        entityType: 'User',
        entityId: userId,
        requestId: context.requestId,
        ipAddress: context.ipAddress,
        deviceId: context.deviceId,
        before: { stepUpAuthenticated: false },
        after: { stepUpAuthenticated: true },
      },
    });
    const sessionId = randomBytes(32).toString('base64url');
    const csrfToken = randomBytes(32).toString('base64url');
    const stored: StoredAdminSession = {
      userId: user.id,
      sessionVersion: user.sessionVersion,
      csrfTokenHash: this.hashCsrfToken(csrfToken),
    };

    await this.redis.set(
      this.sessionKey(sessionId),
      JSON.stringify(stored),
      'EX',
      expiresInSeconds,
    );
    return { sessionId, csrfToken, expiresInSeconds };
  }

  async authenticate(
    sessionId: string,
    csrfToken?: string,
  ): Promise<{
    user: AdminAuthUser;
    sessionId: string;
  }> {
    const stored = await this.getStoredSession(sessionId);
    if (csrfToken !== undefined && !this.matchesCsrfToken(stored, csrfToken)) {
      throw new ForbiddenException('Недействительный CSRF token');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: stored.userId },
      select: {
        id: true,
        phone: true,
        role: true,
        adminCapabilities: true,
        isBlocked: true,
        sessionVersion: true,
        deletedAt: true,
      },
    });

    if (
      !user ||
      user.role !== UserRole.ADMIN ||
      stored.sessionVersion !== user.sessionVersion ||
      user.isBlocked ||
      user.deletedAt
    ) {
      await this.redis.del(this.sessionKey(sessionId));
      throw new UnauthorizedException('Admin-сессия отозвана');
    }

    return {
      user: {
        id: user.id,
        phone: user.phone,
        role: UserRole.ADMIN,
        adminCapabilities: user.adminCapabilities,
        sessionVersion: user.sessionVersion,
      },
      sessionId,
    };
  }

  async revoke(
    sessionId: string,
    adminId: string,
    context: AdminAuditContext,
  ): Promise<{ revoked: true }> {
    await this.redis.del(this.sessionKey(sessionId));
    await this.prisma.adminAuditLog.create({
      data: {
        adminId,
        action: 'ADMIN_SESSION_REVOKED',
        entityType: 'User',
        entityId: adminId,
        requestId: context.requestId,
        ipAddress: context.ipAddress,
        deviceId: context.deviceId,
        before: { adminSessionActive: true },
        after: { adminSessionActive: false },
      },
    });
    return { revoked: true };
  }

  async remainingSeconds(sessionId: string): Promise<number> {
    const seconds = await this.redis.ttl(this.sessionKey(sessionId));
    if (seconds < 1) {
      throw new UnauthorizedException('Admin-сессия истекла');
    }
    return seconds;
  }

  private async getStoredSession(
    sessionId: string,
  ): Promise<StoredAdminSession> {
    const value = await this.redis.get(this.sessionKey(sessionId));
    if (!value) {
      throw new UnauthorizedException('Недействительная admin-сессия');
    }

    try {
      const stored = JSON.parse(value) as Partial<StoredAdminSession>;
      if (
        typeof stored.userId !== 'string' ||
        !Number.isInteger(stored.sessionVersion) ||
        typeof stored.csrfTokenHash !== 'string'
      ) {
        throw new Error('Invalid stored session');
      }
      return stored as StoredAdminSession;
    } catch {
      await this.redis.del(this.sessionKey(sessionId));
      throw new UnauthorizedException('Недействительная admin-сессия');
    }
  }

  private matchesCsrfToken(
    stored: StoredAdminSession,
    csrfToken: string,
  ): boolean {
    const actual = Buffer.from(this.hashCsrfToken(csrfToken), 'hex');
    const expected = Buffer.from(stored.csrfTokenHash, 'hex');
    return (
      actual.length === expected.length && timingSafeEqual(actual, expected)
    );
  }

  private hashCsrfToken(csrfToken: string): string {
    return createHash('sha256').update(csrfToken).digest('hex');
  }

  private getAdminSessionTtl(): number {
    const value = this.config.get<string>('ADMIN_SESSION_EXPIRES_IN') ?? '5m';
    const seconds = parseDurationToSeconds(value);
    if (seconds < 1 || seconds > MAX_ADMIN_SESSION_SECONDS) {
      throw new InternalServerErrorException(
        'ADMIN_SESSION_EXPIRES_IN должен быть не больше 15 минут',
      );
    }
    return seconds;
  }

  private sessionKey(sessionId: string): string {
    return `auth:admin-session:${sessionId}`;
  }
}
