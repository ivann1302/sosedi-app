import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { MetricsService } from '../observability/metrics.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { AuthService } from './auth.service';
import { SmsService } from './sms.service';

const OTP_CONTEXT = {
  installationId: '11111111-1111-4111-8111-111111111111',
  ipAddress: '127.0.0.1',
};

class RedisMock {
  private readonly values = new Map<string, string>();
  private readonly sets = new Map<string, Set<string>>();
  private readonly expirySeconds = new Map<string, number>();
  private readonly expiryWrites = new Map<string, number>();

  set(key: string, value: string): Promise<'OK'> {
    this.values.set(key, value);
    return Promise.resolve('OK');
  }

  get(key: string): Promise<string | null> {
    return Promise.resolve(this.values.get(key) ?? null);
  }

  getdel(key: string): Promise<string | null> {
    const value = this.values.get(key) ?? null;
    this.values.delete(key);
    return Promise.resolve(value);
  }

  eval(
    script: string,
    _numberOfKeys: number,
    key: string,
    argument: string,
  ): Promise<number> {
    if (script.includes("redis.call('INCR'")) {
      const nextValue = Number(this.values.get(key) ?? '0') + 1;
      this.values.set(key, nextValue.toString());

      if (nextValue === 1) {
        this.expirySeconds.set(key, Number(argument));
        this.expiryWrites.set(key, (this.expiryWrites.get(key) ?? 0) + 1);
      }

      return Promise.resolve(nextValue);
    }

    if (this.values.get(key) !== argument) {
      return Promise.resolve(0);
    }

    this.values.delete(key);
    return Promise.resolve(1);
  }

  del(...keys: string[]): Promise<number> {
    let deleted = 0;
    for (const key of keys) {
      if (this.values.delete(key)) {
        deleted += 1;
      }
    }

    return Promise.resolve(deleted);
  }

  sadd(key: string, ...members: string[]): Promise<number> {
    const values = this.sets.get(key) ?? new Set<string>();
    let added = 0;
    for (const member of members) {
      if (!values.has(member)) {
        values.add(member);
        added += 1;
      }
    }
    this.sets.set(key, values);
    return Promise.resolve(added);
  }

  smembers(key: string): Promise<string[]> {
    return Promise.resolve(Array.from(this.sets.get(key) ?? []));
  }

  srem(key: string, ...members: string[]): Promise<number> {
    const values = this.sets.get(key);
    if (!values) {
      return Promise.resolve(0);
    }
    let removed = 0;
    for (const member of members) {
      if (values.delete(member)) {
        removed += 1;
      }
    }
    return Promise.resolve(removed);
  }

  expire(): Promise<number> {
    return Promise.resolve(1);
  }

  getValue(key: string): string | null {
    return this.values.get(key) ?? null;
  }

  getExpirySeconds(key: string): number | null {
    return this.expirySeconds.get(key) ?? null;
  }

  getExpiryWriteCount(key: string): number {
    return this.expiryWrites.get(key) ?? 0;
  }
}

class TestAuthService extends AuthService {
  protected generateOtpCode(): string {
    return '123456';
  }
}

class ConfigurableAuthService extends AuthService {
  generateOtpCodeForTest(): string {
    return this.generateOtpCode();
  }
}

type TestUser = {
  id: string;
  phone: string;
  name: string | null;
  role: UserRole;
  kycStatus: null;
  isBlocked: boolean;
  sessionVersion: number;
  deletedAt: null;
};

function createService() {
  const redis = new RedisMock();
  const users = new Map<string, TestUser>();
  let userSeq = 1;

  const prisma = {
    user: {
      upsert: jest.fn(
        ({
          where,
          create,
        }: {
          where: { phone: string };
          create: { phone: string };
        }) => {
          const existingUser = users.get(where.phone);
          if (existingUser) {
            return existingUser;
          }

          const user: TestUser = {
            id: `user-${userSeq}`,
            phone: create.phone,
            name: null,
            role: UserRole.USER,
            kycStatus: null,
            isBlocked: false,
            sessionVersion: 0,
            deletedAt: null,
          };
          userSeq += 1;
          users.set(user.phone, user);

          return Promise.resolve(user);
        },
      ),
      findUnique: jest.fn(
        ({ where }: { where: { id?: string; phone?: string } }) => {
          if (where.phone) {
            return Promise.resolve(users.get(where.phone) ?? null);
          }

          return Promise.resolve(
            Array.from(users.values()).find((user) => user.id === where.id) ??
              null,
          );
        },
      ),
    },
  } as unknown as PrismaService;

  const redisService = {
    getClient: () => redis,
  } as unknown as RedisService;

  const jwt = {
    signAsync: jest.fn(
      (payload: { sub: string; tokenType: string; jti?: string }) =>
        Promise.resolve(
          `${payload.tokenType}:${payload.sub}:${payload.jti ?? ''}`,
        ),
    ),
    verifyAsync: jest.fn(),
  } as unknown as JwtService;

  const configValues: Record<string, string> = {
    JWT_ACCESS_SECRET: 'access-secret',
    JWT_REFRESH_SECRET: 'refresh-secret',
    JWT_ACCESS_EXPIRES_IN: '15m',
    JWT_REFRESH_EXPIRES_IN: '30d',
  };
  const config = {
    get: jest.fn((key: string) => configValues[key]),
  } as unknown as ConfigService;

  const sendOtp = jest.fn(() => Promise.resolve(undefined));
  const sms = {
    sendOtp,
  } as unknown as SmsService;
  const recordOperation = jest.fn();
  const metrics = { recordOperation } as unknown as MetricsService;

  const service = new TestAuthService(
    prisma,
    redisService,
    jwt,
    config,
    sms,
    metrics,
  );

  return {
    service,
    jwt,
    redis,
    sendOtp,
    configValues,
    recordOperation,
  };
}

describe('AuthService', () => {
  it('uses an explicit fixed OTP for the local console provider only', () => {
    const originalNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    const config = new ConfigService({
      SMS_PROVIDER: 'console',
      DEV_SMS_OTP_CODE: '654321',
    });
    const service = new ConfigurableAuthService(
      {} as PrismaService,
      { getClient: () => ({}) } as unknown as RedisService,
      {} as JwtService,
      config,
      {} as SmsService,
      { recordOperation: jest.fn() } as unknown as MetricsService,
    );

    try {
      expect(service.generateOtpCodeForTest()).toBe('654321');
    } finally {
      if (originalNodeEnv === undefined) {
        delete process.env.NODE_ENV;
      } else {
        process.env.NODE_ENV = originalNodeEnv;
      }
    }
  });

  it('limits OTP requests to 3 per 10 minutes', async () => {
    const { service, sendOtp } = createService();

    await service.requestOtp('+7 999 123-45-67', OTP_CONTEXT);
    await service.requestOtp('+7 999 123-45-67', OTP_CONTEXT);
    await service.requestOtp('+7 999 123-45-67', OTP_CONTEXT);

    await expect(
      service.requestOtp('+7 999 123-45-67', OTP_CONTEXT),
    ).rejects.toBeInstanceOf(TooManyRequestsException);
    expect(sendOtp).toHaveBeenCalledTimes(3);
  });

  it('stops SMS sends when the global expense limit is exhausted', async () => {
    const { service, redis, sendOtp, configValues, recordOperation } =
      createService();
    configValues.OTP_GLOBAL_RATE_LIMIT = '2';

    await service.requestOtp('+7 999 123-45-61', OTP_CONTEXT);
    await service.requestOtp('+7 999 123-45-62', {
      installationId: '22222222-2222-4222-8222-222222222222',
      ipAddress: '127.0.0.2',
    });

    await expect(
      service.requestOtp('+7 999 123-45-63', {
        installationId: '33333333-3333-4333-8333-333333333333',
        ipAddress: '127.0.0.3',
      }),
    ).rejects.toBeInstanceOf(TooManyRequestsException);
    expect(sendOtp).toHaveBeenCalledTimes(2);
    expect(redis.getValue('auth:otp:code:+79991234563')).toBeNull();
    expect(recordOperation).toHaveBeenCalledWith('otp_global_limit', 'failure');
  });

  it('removes an undelivered OTP hash when the SMS provider fails', async () => {
    const { service, redis, sendOtp } = createService();
    sendOtp.mockRejectedValueOnce(new Error('provider unavailable'));

    await expect(
      service.requestOtp('+7 999 123-45-64', OTP_CONTEXT),
    ).rejects.toThrow('provider unavailable');
    expect(redis.getValue('auth:otp:code:+79991234564')).toBeNull();
  });

  it('atomically increments OTP counters and sets TTL only once', async () => {
    const { service, redis } = createService();
    const evalSpy = jest.spyOn(redis, 'eval');
    const phone = '+79991234567';
    const sendKey = `auth:otp:send:${phone}`;
    const globalSendKey = 'auth:otp:send:global';
    const failKey = `auth:otp:fail:${phone}`;

    await service.requestOtp(phone, OTP_CONTEXT);
    await service.requestOtp(phone, OTP_CONTEXT);

    expect(redis.getValue(sendKey)).toBe('2');
    expect(redis.getExpirySeconds(sendKey)).toBe(10 * 60);
    expect(redis.getExpiryWriteCount(sendKey)).toBe(1);
    expect(redis.getValue(globalSendKey)).toBe('2');
    expect(redis.getExpirySeconds(globalSendKey)).toBe(24 * 60 * 60);
    expect(redis.getExpiryWriteCount(globalSendKey)).toBe(1);

    await expect(
      service.verifyOtp(phone, '000000', OTP_CONTEXT.installationId),
    ).rejects.toThrow('Неверный код');
    await expect(
      service.verifyOtp(phone, '000000', OTP_CONTEXT.installationId),
    ).rejects.toThrow('Неверный код');

    expect(redis.getValue(failKey)).toBe('2');
    expect(redis.getExpirySeconds(failKey)).toBe(30 * 60);
    expect(redis.getExpiryWriteCount(failKey)).toBe(1);

    const counterCalls = evalSpy.mock.calls.filter(([script]) =>
      String(script).includes("redis.call('INCR'"),
    );
    expect(counterCalls).toHaveLength(10);
    expect(counterCalls).toEqual(
      expect.arrayContaining([
        [expect.any(String), 1, sendKey, '600'],
        [expect.any(String), 1, globalSendKey, '86400'],
        [expect.any(String), 1, failKey, '1800'],
      ]),
    );
  });

  it('creates user and returns tokens after valid OTP', async () => {
    const { service } = createService();

    await service.requestOtp('8 999 123-45-67', OTP_CONTEXT);
    const result = await service.verifyOtp(
      '+7 999 123-45-67',
      '123456',
      OTP_CONTEXT.installationId,
    );

    expect(result.user.phone).toBe('+79991234567');
    expect(result.user.role).toBe(UserRole.USER);
    expect(result.accessToken).toBe('access:user-1:');
    expect(result.refreshToken).toMatch(/^refresh:user-1:/);
  });

  it('issues and consumes a one-time data export step-up token', async () => {
    const { service, jwt } = createService();
    await service.requestOtp('+7 999 123-45-67', OTP_CONTEXT);
    const login = await service.verifyOtp(
      '+7 999 123-45-67',
      '123456',
      OTP_CONTEXT.installationId,
    );
    await service.requestUserStepUpOtp(login.user.phone, OTP_CONTEXT);
    const stepUp = await service.verifyUserStepUpOtp(
      login.user.id,
      login.user.phone,
      '123456',
      'DATA_EXPORT',
    );
    const jti = stepUp.stepUpToken.split(':')[2];
    jwt.verifyAsync = jest.fn().mockResolvedValue({
      sub: login.user.id,
      tokenType: 'user-step-up',
      purpose: 'DATA_EXPORT',
      sessionVersion: 0,
      jti,
    });

    await expect(
      service.consumeUserStepUpToken(
        stepUp.stepUpToken,
        login.user.id,
        'DATA_EXPORT',
      ),
    ).resolves.toBeUndefined();
    await expect(
      service.consumeUserStepUpToken(
        stepUp.stepUpToken,
        login.user.id,
        'DATA_EXPORT',
      ),
    ).rejects.toMatchObject({
      response: { code: 'STEP_UP_REQUIRED' },
    });
  });

  it('does not hide a Redis failure while revoking a valid session', async () => {
    const { service, jwt, redis } = createService();
    jwt.verifyAsync = jest.fn().mockResolvedValue({
      sub: 'user-1',
      phone: '+79991234567',
      role: UserRole.USER,
      tokenType: 'refresh',
      sessionVersion: 0,
      jti: 'refresh-id',
      sid: 'session-id',
    });
    jest.spyOn(redis, 'del').mockRejectedValueOnce(new Error('Redis is down'));

    await expect(service.logout('valid-refresh-token')).rejects.toThrow(
      'Redis is down',
    );
  });
});
