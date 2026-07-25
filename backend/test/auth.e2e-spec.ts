import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import request, { type Response } from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { SmsService } from './../src/auth/sms.service';
import { PrismaService } from './../src/prisma/prisma.service';
import { RedisService } from './../src/redis/redis.service';
import { resetTestState } from './support/test-state';

const TEST_PHONE = '+79991234567';

type AuthSession = {
  userId: string;
  accessToken: string;
  refreshToken: string;
};

class FakeSmsService {
  private readonly codes = new Map<string, string>();

  sendOtp(phone: string, code: string): Promise<void> {
    this.codes.set(phone, code);
    return Promise.resolve();
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

  async function login(phone = TEST_PHONE): Promise<AuthSession> {
    await request(httpServer())
      .post('/api/v1/auth/otp/request')
      .send({ phone })
      .expect(201);

    const verifyResponse = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
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
        role: 'RENTER',
      },
      error: null,
    });
  });

  it('rejects an expired OTP code', async () => {
    await request(httpServer())
      .post('/api/v1/auth/otp/request')
      .send({ phone: TEST_PHONE })
      .expect(201);
    const validCode = fakeSms.codeFor(TEST_PHONE);

    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const redis = app.get(RedisService).getClient();
    await redis.del(`auth:otp:code:${TEST_PHONE}`);

    const expiredResponse = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ phone: TEST_PHONE, code: validCode })
      .expect(401);
    expectErrorCode(expiredResponse, 'UNAUTHORIZED');
  });

  it('blocks OTP verification after five incorrect codes', async () => {
    await request(httpServer())
      .post('/api/v1/auth/otp/request')
      .send({ phone: TEST_PHONE })
      .expect(201);

    for (let attempt = 1; attempt < 5; attempt += 1) {
      const response = await request(httpServer())
        .post('/api/v1/auth/otp/verify')
        .send({ phone: TEST_PHONE, code: '000000' })
        .expect(401);
      expectErrorCode(response, 'UNAUTHORIZED');
    }

    const blockedResponse = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ phone: TEST_PHONE, code: '000000' })
      .expect(429);
    expectErrorCode(blockedResponse, 'TOO_MANY_REQUESTS');

    await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .send({ phone: TEST_PHONE, code: fakeSms.codeFor(TEST_PHONE) })
      .expect(429);
  });

  it('limits OTP delivery to three requests in ten minutes', async () => {
    for (let attempt = 0; attempt < 3; attempt += 1) {
      await request(httpServer())
        .post('/api/v1/auth/otp/request')
        .send({ phone: TEST_PHONE })
        .expect(201);
    }

    const response = await request(httpServer())
      .post('/api/v1/auth/otp/request')
      .send({ phone: TEST_PHONE })
      .expect(429);
    expectErrorCode(response, 'TOO_MANY_REQUESTS');
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

  it('accepts an OTP only once under concurrency', async () => {
    await request(httpServer())
      .post('/api/v1/auth/otp/request')
      .send({ phone: TEST_PHONE })
      .expect(201);
    const code = fakeSms.codeFor(TEST_PHONE);

    const responses = await Promise.all([
      request(httpServer())
        .post('/api/v1/auth/otp/verify')
        .send({ phone: TEST_PHONE, code }),
      request(httpServer())
        .post('/api/v1/auth/otp/verify')
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
      .expect(403);
    expectErrorCode(forbiddenResponse, 'FORBIDDEN');

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
        name: 'Электроинструмент',
        slug: 'power-tools',
        sortOrder: 1,
      })
      .expect(201);

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
