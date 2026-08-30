import {
  InternalServerErrorException,
  type INestApplication,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingStatus,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  UserRole,
} from '@prisma/client';
import request, { type Response } from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { SmsService } from './../src/auth/sms.service';
import { PrismaService } from './../src/prisma/prisma.service';
import { RedisService } from './../src/redis/redis.service';
import { UsersService } from './../src/users/users.service';
import { resetTestState } from './support/test-state';

const TEST_PHONE = '+79991234567';
const TEST_INSTALLATION_ID = '11111111-1111-4111-8111-111111111111';
const SECOND_INSTALLATION_ID = '22222222-2222-4222-8222-222222222222';
const THIRD_INSTALLATION_ID = '44444444-4444-4444-8444-444444444444';

type AuthSession = {
  userId: string;
  accessToken: string;
  refreshToken: string;
};

class FakeSmsService {
  private readonly codes = new Map<string, string>();
  private shouldFailNextSend = false;

  sendOtp(phone: string, code: string): Promise<void> {
    if (this.shouldFailNextSend) {
      this.shouldFailNextSend = false;
      throw new InternalServerErrorException('Не удалось отправить SMS');
    }
    this.codes.set(phone, code);
    return Promise.resolve();
  }

  failNextSend(): void {
    this.shouldFailNextSend = true;
  }

  codeFor(phone: string): string {
    const code = this.codes.get(phone);
    if (!code) {
      throw new Error(`No OTP captured for ${phone}`);
    }

    return code;
  }

  reset(): void {
    this.codes.clear();
    this.shouldFailNextSend = false;
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object');
  }

  return value as Record<string, unknown>;
}

function requiredString(record: Record<string, unknown>, key: string): string {
  const value = record[key];
  if (typeof value !== 'string') {
    throw new Error(`Expected ${key} to be a string`);
  }

  return value;
}

function expectErrorCode(response: Response, code: string): void {
  expect(response.body).toMatchObject({
    success: false,
    data: null,
    error: { code },
  });
}

describe('Auth API (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let fakeSms: FakeSmsService;

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    return app.getHttpServer();
  }

  function otpRequest(phone: string, installationId = TEST_INSTALLATION_ID) {
    return request(httpServer())
      .post('/api/v1/auth/otp/request')
      .set('X-Installation-Id', installationId)
      .send({ phone });
  }

  beforeAll(async () => {
    fakeSms = new FakeSmsService();
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(SmsService)
      .useValue(fakeSms)
      .compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
  });

  beforeEach(async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    fakeSms.reset();
    await resetTestState(app);
  });

  async function login(
    phone = TEST_PHONE,
    installationId = TEST_INSTALLATION_ID,
  ): Promise<AuthSession> {
    await otpRequest(phone, installationId).expect(201);

    const verifyResponse = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .set('X-Installation-Id', installationId)
      .send({
        phone,
        code: fakeSms.codeFor(TEST_PHONE),
      })
      .expect(201);

    const body = asRecord(verifyResponse.body as unknown);
    const data = asRecord(body.data);
    const user = asRecord(data.user);

    return {
      userId: requiredString(user, 'id'),
      accessToken: requiredString(data, 'accessToken'),
      refreshToken: requiredString(data, 'refreshToken'),
    };
  }

  it('runs OTP login and returns the current user', async () => {
    const session = await login('8 (999) 123-45-67');

    const response = await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${session.accessToken}`)
      .expect(200);

    expect(response.body).toMatchObject({
      success: true,
      data: {
        id: session.userId,
        phone: TEST_PHONE,
        role: 'USER',
      },
      error: null,
    });
  });

  it('exports only self data after one-time SMS step-up', async () => {
    const session = await login();
    const authorization = `Bearer ${session.accessToken}`;

    const withoutStepUp = await request(httpServer())
      .post('/api/v1/users/me/data-export')
      .set('Authorization', authorization)
      .send({ stepUpToken: 'invalid' })
      .expect(401);
    expectErrorCode(withoutStepUp, 'STEP_UP_REQUIRED');

    await request(httpServer())
      .post('/api/v1/auth/step-up/data-export/otp/request')
      .set('Authorization', authorization)
      .set('X-Installation-Id', TEST_INSTALLATION_ID)
      .send()
      .expect(201);
    const verification = await request(httpServer())
      .post('/api/v1/auth/step-up/data-export/otp/verify')
      .set('Authorization', authorization)
      .send({ code: fakeSms.codeFor(TEST_PHONE) })
      .expect(201);
    const stepUpToken = requiredString(
      asRecord(asRecord(verification.body as unknown).data),
      'stepUpToken',
    );

    const exported = await request(httpServer())
      .post('/api/v1/users/me/data-export')
      .set('Authorization', authorization)
      .send({ stepUpToken })
      .expect(201);
    expect(exported.body).toMatchObject({
      success: true,
      data: {
        schemaVersion: '2026-08-30.1',
        profile: { id: session.userId, phone: TEST_PHONE },
        listings: [],
        bookings: [],
        financialHistory: [],
      },
      error: null,
    });
    const serialized = JSON.stringify(exported.body);
    expect(serialized).not.toContain(session.accessToken);
    expect(serialized).not.toContain(session.refreshToken);
    expect(serialized).not.toContain(stepUpToken);

    const replay = await request(httpServer())
      .post('/api/v1/users/me/data-export')
      .set('Authorization', authorization)
      .send({ stepUpToken })
      .expect(401);
    expectErrorCode(replay, 'STEP_UP_REQUIRED');
  });

  it('rejects an expired OTP code', async () => {
    await otpRequest(TEST_PHONE).expect(201);
    const validCode = fakeSms.codeFor(TEST_PHONE);

    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const redis = app.get(RedisService).getClient();
    await redis.del(`auth:otp:code:${TEST_PHONE}`);

    const expiredResponse = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .set('X-Installation-Id', TEST_INSTALLATION_ID)
      .send({ phone: TEST_PHONE, code: validCode })
      .expect(401);
    expectErrorCode(expiredResponse, 'UNAUTHORIZED');
  });

  it('blocks OTP verification after five incorrect codes', async () => {
    await otpRequest(TEST_PHONE).expect(201);

    for (let attempt = 1; attempt < 5; attempt += 1) {
      const response = await request(httpServer())
        .post('/api/v1/auth/otp/verify')
        .set('X-Installation-Id', TEST_INSTALLATION_ID)
        .send({ phone: TEST_PHONE, code: '000000' })
        .expect(401);
      expectErrorCode(response, 'UNAUTHORIZED');
    }

    const blockedResponse = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .set('X-Installation-Id', TEST_INSTALLATION_ID)
      .send({ phone: TEST_PHONE, code: '000000' })
      .expect(429);
    expectErrorCode(blockedResponse, 'TOO_MANY_REQUESTS');

    await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .set('X-Installation-Id', TEST_INSTALLATION_ID)
      .send({ phone: TEST_PHONE, code: fakeSms.codeFor(TEST_PHONE) })
      .expect(429);
  });

  it('limits OTP delivery to three requests in ten minutes', async () => {
    for (let attempt = 0; attempt < 3; attempt += 1) {
      await otpRequest(TEST_PHONE).expect(201);
    }

    const response = await otpRequest(TEST_PHONE).expect(429);
    expectErrorCode(response, 'TOO_MANY_REQUESTS');
  });

  it('limits one installation without prematurely blocking its shared IP', async () => {
    for (let index = 1; index <= 6; index += 1) {
      await otpRequest(`+7999000100${index}`, TEST_INSTALLATION_ID).expect(201);
    }

    const limitedDevice = await otpRequest(
      '+79990001007',
      TEST_INSTALLATION_ID,
    ).expect(429);
    expectErrorCode(limitedDevice, 'TOO_MANY_REQUESTS');

    await otpRequest('+79990001008', SECOND_INSTALLATION_ID).expect(201);
    const limitedIp = await otpRequest(
      '+79990001009',
      THIRD_INSTALLATION_ID,
    ).expect(429);
    expectErrorCode(limitedIp, 'TOO_MANY_REQUESTS');
  });

  it('enforces the global SMS expense limit across actors', async () => {
    const previousLimit = process.env.OTP_GLOBAL_RATE_LIMIT;
    process.env.OTP_GLOBAL_RATE_LIMIT = '2';

    try {
      await otpRequest(
        '+79990001101',
        '10000000-0000-4000-8000-000000000001',
      ).expect(201);
      await otpRequest(
        '+79990001102',
        '10000000-0000-4000-8000-000000000002',
      ).expect(201);
      const limited = await otpRequest(
        '+79990001103',
        '10000000-0000-4000-8000-000000000003',
      ).expect(429);

      expectErrorCode(limited, 'TOO_MANY_REQUESTS');
      expect(() => fakeSms.codeFor('+79990001103')).toThrow('No OTP captured');
      const metrics = await request(httpServer())
        .get('/api/v1/internal/metrics')
        .set('Authorization', `Bearer ${process.env.METRICS_TOKEN}`)
        .expect(200);
      expect(metrics.text).toContain(
        'sosedi_operation_total{operation="otp_global_limit",result="failure"} 1',
      );
    } finally {
      if (previousLimit === undefined) {
        delete process.env.OTP_GLOBAL_RATE_LIMIT;
      } else {
        process.env.OTP_GLOBAL_RATE_LIMIT = previousLimit;
      }
    }
  });

  it('invalidates an OTP when the SMS provider rejects delivery', async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    fakeSms.failNextSend();

    await otpRequest(TEST_PHONE).expect(500);

    const redis = app.get(RedisService).getClient();
    await expect(redis.get(`auth:otp:code:${TEST_PHONE}`)).resolves.toBeNull();
    expect(() => fakeSms.codeFor(TEST_PHONE)).toThrow('No OTP captured');
  });

  it('requires a valid installation identifier for OTP delivery', async () => {
    await request(httpServer())
      .post('/api/v1/auth/otp/request')
      .send({ phone: TEST_PHONE })
      .expect(400);
    await otpRequest(TEST_PHONE, 'not-a-uuid').expect(400);
  });

  it('rotates refresh tokens and revokes them on logout', async () => {
    const session = await login();

    const refreshResponse = await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(201);
    const refreshBody = asRecord(refreshResponse.body as unknown);
    const nextTokens = asRecord(refreshBody.data);
    const nextAccessToken = requiredString(nextTokens, 'accessToken');
    const nextRefreshToken = requiredString(nextTokens, 'refreshToken');

    expect(nextRefreshToken).not.toBe(session.refreshToken);

    const replayResponse = await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: session.refreshToken })
      .expect(401);
    expectErrorCode(replayResponse, 'UNAUTHORIZED');

    await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: nextRefreshToken })
      .expect(401);

    await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${nextAccessToken}`)
      .expect(200);

    await request(httpServer())
      .post('/api/v1/auth/logout')
      .send({ refreshToken: nextRefreshToken })
      .expect(201);

    await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: nextRefreshToken })
      .expect(401);
  });

  it('accepts a refresh token only once under concurrency', async () => {
    const session = await login();

    const responses = await Promise.all([
      request(httpServer())
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: session.refreshToken }),
      request(httpServer())
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: session.refreshToken }),
    ]);

    expect(responses.map((response) => response.status).sort()).toEqual([
      201, 401,
    ]);
  });

  it('lists self sessions and revokes one or all without exposing tokens', async () => {
    const first = await login(TEST_PHONE, TEST_INSTALLATION_ID);
    const second = await login(TEST_PHONE, SECOND_INSTALLATION_ID);

    const listResponse = await request(httpServer())
      .get('/api/v1/auth/sessions')
      .set('Authorization', `Bearer ${first.accessToken}`)
      .set('X-Installation-Id', TEST_INSTALLATION_ID)
      .expect(200);
    const sessions = asRecord(listResponse.body).data as Array<
      Record<string, unknown>
    >;

    expect(sessions).toHaveLength(2);
    expect(JSON.stringify(sessions)).not.toContain('refreshToken');
    expect(JSON.stringify(sessions)).not.toContain('accessToken');
    const current = sessions.find((session) => session.isCurrent === true);
    const other = sessions.find((session) => session.isCurrent === false);
    expect(current?.installationId).toBe(TEST_INSTALLATION_ID);
    expect(other?.installationId).toBe(SECOND_INSTALLATION_ID);

    await request(httpServer())
      .delete(`/api/v1/auth/sessions/${String(other?.sessionId)}`)
      .set('Authorization', `Bearer ${first.accessToken}`)
      .expect(200);
    await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: second.refreshToken })
      .expect(401);

    await request(httpServer())
      .delete('/api/v1/auth/sessions')
      .set('Authorization', `Bearer ${first.accessToken}`)
      .expect(200);
    await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: first.refreshToken })
      .expect(401);
  });

  it('revokes every session when an account is closed', async () => {
    const firstSession = await login();
    const secondSession = await login();

    const closeResponse = await request(httpServer())
      .delete('/api/v1/users/me')
      .set('Authorization', `Bearer ${firstSession.accessToken}`)
      .expect(200);
    const closeData = asRecord(asRecord(closeResponse.body).data);
    expect(closeData.status).toBe('ANONYMIZED');
    expect(requiredString(closeData, 'anonymizedAt')).not.toBe('');

    await request(httpServer())
      .post('/api/v1/uploads/presigned-url')
      .set('Authorization', `Bearer ${secondSession.accessToken}`)
      .send({})
      .expect(401);

    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const prisma = app.get(PrismaService);
    await prisma.user.update({
      where: { id: firstSession.userId },
      data: {
        phone: TEST_PHONE,
        deletedAt: null,
        anonymizedAt: null,
      },
    });

    await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${secondSession.accessToken}`)
      .expect(401);
    await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: firstSession.refreshToken })
      .expect(401);
    await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: secondSession.refreshToken })
      .expect(401);
  });

  it('hides a closed account and anonymizes it after obligations complete', async () => {
    const session = await login();

    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const prisma = app.get(PrismaService);
    const borrower = await prisma.user.create({
      data: {
        phone: '+79990002001',
        role: UserRole.USER,
      },
    });
    const category = await prisma.category.create({
      data: {
        name: 'Проекторы и экраны',
        slug: 'account-deletion-contract',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: session.userId,
        categoryId: category.id,
        title: 'Проектор для проверки закрытия аккаунта',
        description: 'Активная аренда должна блокировать закрытие аккаунта',
        condition: ItemCondition.GOOD,
        completeness: 'Проектор, пульт и кабель питания',
        handoverTerms: 'Личная передача по договорённости',
        pricePerDay: 900,
        status: ItemStatus.APPROVED,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
    });
    await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: borrower.id,
        lenderId: session.userId,
        startDate: new Date('2026-08-10T00:00:00.000Z'),
        endDate: new Date('2026-08-11T00:00:00.000Z'),
        totalAmount: 1800,
        status: BookingStatus.CONFIRMED,
      },
    });

    await request(httpServer()).get(`/api/v1/items/${item.id}`).expect(200);

    const response = await request(httpServer())
      .delete('/api/v1/users/me')
      .set('Authorization', `Bearer ${session.accessToken}`)
      .expect(200);
    const closureData = asRecord(asRecord(response.body).data);
    expect(closureData.status).toBe('PENDING_OBLIGATIONS');
    expect(requiredString(closureData, 'requestedAt')).not.toBe('');
    expect(closureData.anonymizedAt).toBeNull();

    const closedUser = await prisma.user.findUniqueOrThrow({
      where: { id: session.userId },
    });
    expect(closedUser).toMatchObject({
      phone: TEST_PHONE,
      name: null,
      sessionVersion: 1,
      anonymizedAt: null,
    });
    expect(closedUser.deletedAt).toBeInstanceOf(Date);

    await request(httpServer()).get(`/api/v1/items/${item.id}`).expect(404);
    await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${session.accessToken}`)
      .expect(401);

    await prisma.booking.update({
      where: { id: (await prisma.booking.findFirstOrThrow()).id },
      data: { status: BookingStatus.COMPLETED },
    });
    await expect(
      app.get(UsersService).finalizeEligibleAccountClosures(),
    ).resolves.toBe(1);
    const anonymizedUser = await prisma.user.findUniqueOrThrow({
      where: { id: session.userId },
    });
    expect(anonymizedUser).toMatchObject({
      phone: `deleted:${session.userId}`,
      name: null,
      city: null,
      avatarUrl: null,
    });
    expect(anonymizedUser.anonymizedAt).toBeInstanceOf(Date);
  });

  it('accepts an OTP only once under concurrency', async () => {
    await otpRequest(TEST_PHONE).expect(201);
    const code = fakeSms.codeFor(TEST_PHONE);

    const responses = await Promise.all([
      request(httpServer())
        .post('/api/v1/auth/otp/verify')
        .set('X-Installation-Id', TEST_INSTALLATION_ID)
        .send({ phone: TEST_PHONE, code }),
      request(httpServer())
        .post('/api/v1/auth/otp/verify')
        .set('X-Installation-Id', TEST_INSTALLATION_ID)
        .send({ phone: TEST_PHONE, code }),
    ]);

    expect(responses.map((response) => response.status).sort()).toEqual([
      201, 401,
    ]);
  });

  it('enforces authentication, current user status, and roles', async () => {
    const noTokenResponse = await request(httpServer())
      .get('/api/v1/users/me')
      .expect(401);
    expectErrorCode(noTokenResponse, 'UNAUTHORIZED');

    const session = await login();

    const refreshAsAccessResponse = await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${session.refreshToken}`)
      .expect(401);
    expectErrorCode(refreshAsAccessResponse, 'UNAUTHORIZED');

    const forbiddenResponse = await request(httpServer())
      .post('/api/v1/categories')
      .set('Authorization', `Bearer ${session.accessToken}`)
      .send({})
      .expect(401);
    expectErrorCode(forbiddenResponse, 'UNAUTHORIZED');

    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const prisma = app.get(PrismaService);
    await prisma.user.update({
      where: { id: session.userId },
      data: { role: UserRole.ADMIN },
    });

    await request(httpServer())
      .post('/api/v1/categories')
      .set('Authorization', `Bearer ${session.accessToken}`)
      .send({
        name: 'Фото и видео',
        slug: 'power-items',
        sortOrder: 1,
      })
      .expect(401);

    await prisma.user.update({
      where: { id: session.userId },
      data: { isBlocked: true },
    });

    const blockedResponse = await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${session.accessToken}`)
      .expect(403);
    expectErrorCode(blockedResponse, 'FORBIDDEN');

    await prisma.user.update({
      where: { id: session.userId },
      data: {
        isBlocked: false,
        deletedAt: new Date(),
      },
    });

    const deletedResponse = await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${session.accessToken}`)
      .expect(401);
    expectErrorCode(deletedResponse, 'UNAUTHORIZED');
  });

  it('rejects a signed access token without a subject', async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    const jwt = app.get(JwtService);
    const malformedToken = await jwt.signAsync(
      {
        phone: TEST_PHONE,
        role: 'ADMIN',
        tokenType: 'access',
      },
      {
        secret: 'e2e-access-secret',
        algorithm: 'HS256',
      },
    );

    const response = await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${malformedToken}`)
      .expect(401);
    expectErrorCode(response, 'UNAUTHORIZED');
  });

  afterAll(async () => {
    await app?.close();
  });
});
