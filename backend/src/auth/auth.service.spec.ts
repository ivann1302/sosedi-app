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

  incr(key: string): Promise<number> {
    const nextValue = Number(this.values.get(key) ?? '0') + 1;
    this.values.set(key, nextValue.toString());
    return Promise.resolve(nextValue);
  }

  expire(key: string, ttlSeconds: number): Promise<number> {
    void key;
    void ttlSeconds;
    return Promise.resolve(1);
  }

  set(key: string, value: string): Promise<'OK'> {
    this.values.set(key, value);
    return Promise.resolve('OK');
  }

  get(key: string): Promise<string | null> {
    return Promise.resolve(this.values.get(key) ?? null);
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

  it('creates user and returns tokens after valid OTP', async () => {
    const { service } = createService();

    await service.requestOtp('8 999 123-45-67');
    const result = await service.verifyOtp('+7 999 123-45-67', '123456');

    expect(result.user.phone).toBe('+79991234567');
    expect(result.user.role).toBe(UserRole.RENTER);
    expect(result.accessToken).toBe('access:user-1:');
    expect(result.refreshToken).toMatch(/^refresh:user-1:/);
  });
});
