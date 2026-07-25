import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { AuthService } from './auth.service';
import { SmsService } from './sms.service';

class RedisMock {
  private readonly values = new Map<string, string>();
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

type TestUser = {
  id: string;
  phone: string;
  name: string | null;
  role: UserRole;
  kycStatus: null;
  isBlocked: boolean;
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
            role: UserRole.RENTER,
            kycStatus: null,
            isBlocked: false,
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

  const service = new TestAuthService(prisma, redisService, jwt, config, sms);

  return {
    service,
    jwt,
    redis,
    sendOtp,
  };
}

describe('AuthService', () => {
  it('limits OTP requests to 3 per 10 minutes', async () => {
    const { service, sendOtp } = createService();

    await service.requestOtp('+7 999 123-45-67');
    await service.requestOtp('+7 999 123-45-67');
    await service.requestOtp('+7 999 123-45-67');

    await expect(service.requestOtp('+7 999 123-45-67')).rejects.toBeInstanceOf(
      TooManyRequestsException,
    );
    expect(sendOtp).toHaveBeenCalledTimes(3);
  });

  it('atomically increments OTP counters and sets TTL only once', async () => {
    const { service, redis } = createService();
    const evalSpy = jest.spyOn(redis, 'eval');
    const phone = '+79991234567';
    const sendKey = `auth:otp:send:${phone}`;
    const failKey = `auth:otp:fail:${phone}`;

    await service.requestOtp(phone);
    await service.requestOtp(phone);

    expect(redis.getValue(sendKey)).toBe('2');
    expect(redis.getExpirySeconds(sendKey)).toBe(10 * 60);
    expect(redis.getExpiryWriteCount(sendKey)).toBe(1);

    await expect(service.verifyOtp(phone, '000000')).rejects.toThrow(
      'Неверный код',
    );
    await expect(service.verifyOtp(phone, '000000')).rejects.toThrow(
      'Неверный код',
    );

    expect(redis.getValue(failKey)).toBe('2');
    expect(redis.getExpirySeconds(failKey)).toBe(30 * 60);
    expect(redis.getExpiryWriteCount(failKey)).toBe(1);

    const counterCalls = evalSpy.mock.calls.filter(([script]) =>
      String(script).includes("redis.call('INCR'"),
    );
    expect(counterCalls).toHaveLength(4);
    expect(counterCalls).toEqual(
      expect.arrayContaining([
        [expect.any(String), 1, sendKey, '600'],
        [expect.any(String), 1, failKey, '1800'],
      ]),
    );
  });

  it('creates user and returns tokens after valid OTP', async () => {
    const { service } = createService();

    await service.requestOtp('8 999 123-45-67');
    const result = await service.verifyOtp('+7 999 123-45-67', '123456');

    expect(result.user.phone).toBe('+79991234567');
    expect(result.user.role).toBe(UserRole.RENTER);
    expect(result.accessToken).toBe('access:user-1:');
    expect(result.refreshToken).toMatch(/^refresh:user-1:/);
  });

  it('does not hide a Redis failure while revoking a valid session', async () => {
    const { service, jwt, redis } = createService();
    jwt.verifyAsync = jest.fn().mockResolvedValue({
      sub: 'user-1',
      phone: '+79991234567',
      role: UserRole.RENTER,
      tokenType: 'refresh',
      jti: 'refresh-id',
    });
    jest.spyOn(redis, 'del').mockRejectedValueOnce(new Error('Redis is down'));

    await expect(service.logout('valid-refresh-token')).rejects.toThrow(
      'Redis is down',
    );
  });
});
