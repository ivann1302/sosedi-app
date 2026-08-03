import { Controller, Get, type INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { CategoryListingPolicy } from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { PrismaService } from './../src/prisma/prisma.service';
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

  it('separates liveness from dependency and migration readiness', async () => {
    await request(httpServer())
      .get('/api/v1/health/live')
      .expect('Cache-Control', 'no-store')
      .expect(200)
      .expect({
        success: true,
        data: { status: 'ok' },
        error: null,
      });

    await request(httpServer())
      .get('/api/v1/health/ready')
      .expect('Cache-Control', 'no-store')
      .expect(200)
      .expect({
        success: true,
        data: {
          status: 'ready',
          checks: {
            database: 'ok',
            migrations: 'ok',
            redis: 'ok',
            clock: 'ok',
          },
        },
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

  it('exposes a category slug only through the active ALLOWED whitelist', async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const prisma = app.get(PrismaService);
    const slugs = ['public-category-e2e', 'restricted-category-e2e'];
    await prisma.category.createMany({
      data: [
        {
          name: 'Публичная категория e2e',
          slug: slugs[0],
          isActive: true,
          isAllowedForListings: true,
          listingPolicy: CategoryListingPolicy.ALLOWED,
          safetyNotice: 'Проверьте комплектность перед передачей.',
        },
        {
          name: 'Ограниченная категория e2e',
          slug: slugs[1],
          isActive: true,
          isAllowedForListings: false,
          listingPolicy: CategoryListingPolicy.RESTRICTED,
        },
      ],
    });

    try {
      await request(httpServer())
        .get(`/api/v1/categories/${slugs[0]}`)
        .expect(200)
        .expect(({ body }) => {
          expect(body).toMatchObject({
            success: true,
            data: {
              slug: slugs[0],
              listingPolicy: CategoryListingPolicy.ALLOWED,
              safetyNotice: 'Проверьте комплектность перед передачей.',
            },
            error: null,
          });
        });
      await request(httpServer())
        .get(`/api/v1/categories/${slugs[1]}`)
        .expect(404);
    } finally {
      await prisma.category.deleteMany({ where: { slug: { in: slugs } } });
    }
  });

  it('connects to the isolated Redis instance', async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    const redis = app.get(RedisService).getClient();
    await expect(redis.ping()).resolves.toBe('PONG');
  });

  it('protects operational metrics with a dedicated bearer token', async () => {
    await request(httpServer()).get('/api/v1/internal/metrics').expect(401);

    const response = await request(httpServer())
      .get('/api/v1/internal/metrics')
      .set('Authorization', `Bearer ${process.env.METRICS_TOKEN}`)
      .expect('Content-Type', /text\/plain/)
      .expect(200);

    expect(response.text).toContain('sosedi_http_requests_total');
    expect(response.text).toContain('sosedi_database_connections');
    expect(response.text).toContain('sosedi_redis_memory_bytes');
    expect(response.text).toContain('sosedi_outbox_pending');
    expect(response.text).not.toContain(process.env.METRICS_TOKEN);
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
