import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { PrismaService } from './../src/prisma/prisma.service';
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';

describe('Device tokens (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    return app.getHttpServer();
  }

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(S3StorageService)
      .useValue({})
      .compile();
    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
    jwt = app.get(JwtService);
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    await resetTestState(app);
  });

  it('upserts by installation, transfers ownership and deletes only self token', async () => {
    const [firstUser, secondUser] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990009201', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009202', role: UserRole.USER },
      }),
    ]);
    const firstAuthorization = await bearerToken(firstUser);
    const secondAuthorization = await bearerToken(secondUser);
    const firstInstallation = '11111111-1111-4111-8111-111111111111';
    const secondInstallation = '22222222-2222-4222-8222-222222222222';

    const [first, repeated] = await Promise.all([
      register(
        firstAuthorization,
        firstInstallation,
        'first-device-token-value',
      ),
      register(
        firstAuthorization,
        firstInstallation,
        'first-device-token-value',
      ),
    ]);
    expect(repeated.id).toBe(first.id);
    const updated = await register(
      firstAuthorization,
      firstInstallation,
      'rotated-device-token-value',
    );
    expect(updated.id).toBe(first.id);
    expect(updated).not.toHaveProperty('token');

    const transferred = await register(
      secondAuthorization,
      secondInstallation,
      'rotated-device-token-value',
    );
    await expect(
      prisma.devicePushToken.count({ where: { userId: firstUser.id } }),
    ).resolves.toBe(0);

    const foreignDelete = await request(httpServer())
      .delete(`/api/v1/device-tokens/${String(transferred.id)}`)
      .set('Authorization', firstAuthorization)
      .expect(200);
    expect(asRecord(asRecord(foreignDelete.body as unknown).data)).toEqual({
      id: transferred.id,
      removed: false,
    });
    await expect(
      prisma.devicePushToken.count({ where: { userId: secondUser.id } }),
    ).resolves.toBe(1);

    await request(httpServer())
      .post('/api/v1/device-tokens')
      .set('Authorization', secondAuthorization)
      .set('X-Installation-Id', secondInstallation)
      .send({
        provider: 'RUSTORE',
        platform: 'IOS',
        token: 'rustore-device-token-value',
      })
      .expect(400);
  });

  async function register(
    authorization: string,
    installationId: string,
    token: string,
  ): Promise<Record<string, unknown>> {
    const response = await request(httpServer())
      .post('/api/v1/device-tokens')
      .set('Authorization', authorization)
      .set('X-Installation-Id', installationId)
      .send({ provider: 'FCM', platform: 'ANDROID', token })
      .expect(201);
    return asRecord(asRecord(response.body as unknown).data);
  }

  async function bearerToken(user: {
    id: string;
    phone: string;
    role: UserRole;
  }): Promise<string> {
    return `Bearer ${await jwt.signAsync(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      { secret: 'e2e-access-secret', expiresIn: '15m' },
    )}`;
  }

  afterAll(async () => {
    await app?.close();
  });
});

function asRecord(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('Expected object');
  }
  return value as Record<string, unknown>;
}
