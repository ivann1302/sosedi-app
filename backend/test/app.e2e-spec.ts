import { Controller, Get, type INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { RedisService } from './../src/redis/redis.service';

@Controller('__e2e')
class E2eController {
  @Get('failure')
  fail(): never {
    throw new Error('internal test details');
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object response body');
  }

  return value as Record<string, unknown>;
}

describe('Application (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let consoleErrorSpy: jest.SpiedFunction<typeof console.error>;

  beforeAll(async () => {
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();

    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
      controllers: [E2eController],
    }).compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
  });

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    return app.getHttpServer();
  }

  it('returns the health success envelope', async () => {
    await request(httpServer())
      .get('/api/v1/health')
      .expect(200)
      .expect({
        success: true,
        data: { status: 'ok' },
        error: null,
      });
  });

  it('connects to the isolated PostgreSQL database through the API', async () => {
    const response = await request(httpServer())
      .get('/api/v1/categories')
      .expect(200);
    const body = asRecord(response.body as unknown);

    expect(body.success).toBe(true);
    expect(body.error).toBeNull();
    expect(Array.isArray(body.data)).toBe(true);
  });

  it('connects to the isolated Redis instance', async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    const redis = app.get(RedisService).getClient();
    await expect(redis.ping()).resolves.toBe('PONG');
  });

  it('returns the standard envelope for DTO validation errors', async () => {
    const response = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .send({
        phone: '+79991234567',
        code: '123',
      })
      .expect(400);
    const body = asRecord(response.body as unknown);
    const error = asRecord(body.error);

    expect(body).toMatchObject({
      success: false,
      data: null,
      error: {
        code: 'VALIDATION_ERROR',
      },
    });
    expect(error.message).toEqual(
      expect.stringContaining('Код должен состоять из 6 цифр'),
    );
  });

  it('rejects fields that are not declared by the DTO', async () => {
    const response = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .send({
        phone: '+79991234567',
        code: '123456',
        role: 'ADMIN',
      })
      .expect(400);
    const body = asRecord(response.body as unknown);
    const error = asRecord(body.error);

    expect(body).toMatchObject({
      success: false,
      data: null,
      error: {
        code: 'VALIDATION_ERROR',
      },
    });
    expect(error.message).toEqual(
      expect.stringContaining('property role should not exist'),
    );
  });

  it('returns the standard envelope for an unknown route', async () => {
    await request(httpServer())
      .get('/api/v1/not-a-route')
      .expect(404)
      .expect({
        success: false,
        data: null,
        error: {
          code: 'NOT_FOUND',
          message: 'Cannot GET /api/v1/not-a-route',
        },
      });
  });

  it('does not expose unexpected internal errors', async () => {
    const response = await request(httpServer())
      .get('/api/v1/__e2e/failure')
      .expect(500);

    expect(response.body).toEqual({
      success: false,
      data: null,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Внутренняя ошибка сервера',
      },
    });
    expect(JSON.stringify(response.body)).not.toContain(
      'internal test details',
    );
    expect(consoleErrorSpy).toHaveBeenCalled();
  });

  afterAll(async () => {
    await app?.close();
    consoleErrorSpy.mockRestore();
  });
});
