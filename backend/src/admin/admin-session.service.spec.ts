import {
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { AdminMfaService } from './admin-mfa.service';
import { AdminSessionService } from './admin-session.service';

describe('AdminSessionService', () => {
  it('creates a privileged session only after a redacted step-up audit', async () => {
    const mfa = {
      verifyStepUp: jest.fn().mockResolvedValue(undefined),
    };
    const auditCreate = jest
      .fn<Promise<{ id: string }>, [{ data: Record<string, unknown> }]>()
      .mockResolvedValue({ id: 'audit-1' });
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'admin-1',
          phone: '+79990000001',
          role: UserRole.ADMIN,
          adminCapabilities: [],
          isBlocked: false,
          sessionVersion: 0,
          deletedAt: null,
        }),
      },
      adminAuditLog: { create: auditCreate },
    };
    const config = {
      get: jest.fn().mockReturnValue('5m'),
    };
    const redis = {
      set: jest.fn().mockResolvedValue('OK'),
    };
    const service = new AdminSessionService(
      mfa as unknown as AdminMfaService,
      prisma as unknown as PrismaService,
      { getClient: () => redis } as unknown as RedisService,
      config as unknown as ConfigService,
    );

    const session = await service.stepUp('admin-1', '123456', {
      requestId: 'step-up-request-1',
      ipAddress: '127.0.0.1',
      deviceId: 'device-hash',
    });

    expect(auditCreate).toHaveBeenCalledTimes(1);
    expect(auditCreate.mock.calls[0]?.[0]).toMatchObject({
      data: {
        adminId: 'admin-1',
        action: 'ADMIN_STEP_UP_SUCCEEDED',
        entityType: 'User',
        entityId: 'admin-1',
        requestId: 'step-up-request-1',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
      },
    });
    expect(JSON.stringify(auditCreate.mock.calls)).not.toContain(
      session.sessionId,
    );
    expect(JSON.stringify(auditCreate.mock.calls)).not.toContain(
      session.csrfToken,
    );
  });

  it('rejects an admin session TTL above 15 minutes', async () => {
    const mfa = {
      verifyStepUp: jest.fn().mockResolvedValue(undefined),
    };
    const prisma = {
      user: {
        findUnique: jest.fn(() =>
          Promise.resolve({
            id: 'admin-1',
            phone: '+79990000001',
            role: UserRole.ADMIN,
            adminCapabilities: [],
            isBlocked: false,
            sessionVersion: 0,
            deletedAt: null,
          }),
        ),
      },
    };
    const configValues: Record<string, string> = {
      ADMIN_SESSION_EXPIRES_IN: '16m',
    };
    const config = {
      get: jest.fn((key: string) => configValues[key]),
    };
    const redis = { set: jest.fn() };
    const redisService = { getClient: () => redis };
    const service = new AdminSessionService(
      mfa as unknown as AdminMfaService,
      prisma as unknown as PrismaService,
      redisService as unknown as RedisService,
      config as unknown as ConfigService,
    );

    await expect(
      service.stepUp('admin-1', '123456', {
        requestId: 'step-up-request-2',
        ipAddress: '127.0.0.1',
        deviceId: null,
      }),
    ).rejects.toBeInstanceOf(InternalServerErrorException);
    expect(mfa.verifyStepUp).not.toHaveBeenCalled();
    expect(redis.set).not.toHaveBeenCalled();
  });

  it('rejects an opaque admin session from an older session generation', async () => {
    const mfa = {};
    const config = { get: jest.fn() };
    const redis = {
      get: jest.fn().mockResolvedValue(
        JSON.stringify({
          userId: 'admin-1',
          sessionVersion: 0,
          csrfTokenHash:
            '46d4c4facb78360d9e1af043635b703fb07ab0c52014cd9785b2bcfba8d637b4',
        }),
      ),
      del: jest.fn().mockResolvedValue(1),
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'admin-1',
          phone: '+79990000001',
          role: UserRole.ADMIN,
          adminCapabilities: [],
          isBlocked: false,
          sessionVersion: 1,
          deletedAt: null,
        }),
      },
    };
    const service = new AdminSessionService(
      mfa as AdminMfaService,
      prisma as unknown as PrismaService,
      { getClient: () => redis } as unknown as RedisService,
      config as unknown as ConfigService,
    );

    await expect(
      service.authenticate('old-admin-session'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(redis.del).toHaveBeenCalledWith(
      'auth:admin-session:old-admin-session',
    );
  });
});
