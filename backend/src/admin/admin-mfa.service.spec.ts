import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { AdminMfaService } from './admin-mfa.service';

describe('AdminMfaService', () => {
  it('removes a pending TOTP secret when the required setup audit fails', async () => {
    const auditError = new Error('audit unavailable');
    const auditCreate = jest.fn().mockRejectedValue(auditError);
    const prisma = {
      adminMfaCredential: {
        findUnique: jest.fn().mockResolvedValue(null),
      },
      adminAuditLog: { create: auditCreate },
    };
    const redis = {
      set: jest.fn().mockResolvedValue('OK'),
      del: jest.fn().mockResolvedValue(1),
    };
    const config = {
      get: jest.fn().mockReturnValue(Buffer.alloc(32, 7).toString('base64')),
    };
    const service = new AdminMfaService(
      prisma as unknown as PrismaService,
      { getClient: () => redis } as unknown as RedisService,
      config as unknown as ConfigService,
    );

    await expect(
      service.beginTotpSetup('admin-1', '+79990000001', {
        requestId: 'mfa-setup-request',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
      }),
    ).rejects.toBe(auditError);

    expect(redis.set).toHaveBeenCalledWith(
      'auth:admin-mfa-setup:admin-1',
      expect.stringMatching(/^v1\./),
      'EX',
      600,
    );
    expect(redis.del).toHaveBeenCalledWith('auth:admin-mfa-setup:admin-1');
    expect(auditCreate).toHaveBeenCalledWith({
      data: {
        adminId: 'admin-1',
        action: 'ADMIN_MFA_SETUP_STARTED',
        entityType: 'User',
        entityId: 'admin-1',
        requestId: 'mfa-setup-request',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
        before: { pendingMfaSetup: false },
        after: { pendingMfaSetup: true },
      },
    });
    expect(JSON.stringify(auditCreate.mock.calls)).not.toMatch(
      /secret|otpauth|recovery/i,
    );
  });
});
