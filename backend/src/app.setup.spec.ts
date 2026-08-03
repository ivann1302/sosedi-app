import {
  Body,
  Controller,
  Get,
  type INestApplication,
  Post,
  Req,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import type { Request } from 'express';
import { createServer } from 'node:http';
import request from 'supertest';
import { App } from 'supertest/types';
import { configureApp, configureHttpServer } from './app.setup';

function readIp(value: unknown): unknown {
  if (typeof value !== 'object' || value === null || !('ip' in value)) {
    throw new Error('Expected response with ip');
  }
  return value.ip;
}

@Controller('test-ip')
class TestIpController {
  @Get()
  getIp(@Req() req: Request): { ip: string | undefined } {
    return { ip: req.ip };
  }

  @Post('echo')
  echo(@Body() body: unknown): unknown {
    return body;
  }

  @Get('error')
  error(): never {
    throw new Error('sensitive internal failure');
  }
}

describe('application HTTP configuration', () => {
  async function createApp(
    options: Parameters<typeof configureApp>[1] = {},
  ): Promise<INestApplication<App>> {
    const moduleFixture = await Test.createTestingModule({
      controllers: [TestIpController],
    }).compile();
    const app = moduleFixture.createNestApplication({ bodyParser: false });
    configureApp(app, options);
    await app.init();
    return app;
  }

  it('ignores a forged X-Forwarded-For without a trusted direct proxy', async () => {
    const app = await createApp({ trustedProxyIps: '' });

    const response = await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('X-Forwarded-For', '203.0.113.10')
      .expect(200);

    expect(readIp(response.body as unknown)).not.toBe('203.0.113.10');
    await app.close();
  });

  it('uses only the nearest untrusted hop behind an allowlisted proxy', async () => {
    const app = await createApp({
      trustedProxyIps: '127.0.0.0/8,::1/128',
    });

    const response = await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('X-Forwarded-For', '198.51.100.77, 10.0.0.9')
      .expect(200);

    expect(readIp(response.body as unknown)).toBe('10.0.0.9');
    await app.close();
  });

  it.each(['*', '0.0.0.0/0', '::/0'])(
    'fails startup for unsafe proxy configuration %s',
    async (trustedProxyIps) => {
      const moduleFixture = await Test.createTestingModule({
        controllers: [TestIpController],
      }).compile();
      const app = moduleFixture.createNestApplication();

      expect(() => configureApp(app, { trustedProxyIps })).toThrow(
        'TRUSTED_PROXY_IPS',
      );
      await app.close();
    },
  );

  it('fails production startup without an explicit CORS allowlist', async () => {
    const moduleFixture = await Test.createTestingModule({
      controllers: [TestIpController],
    }).compile();
    const app = moduleFixture.createNestApplication({ bodyParser: false });

    expect(() =>
      configureApp(app, {
        nodeEnv: 'production',
        corsAllowedOrigins: '',
      }),
    ).toThrow('CORS_ALLOWED_ORIGINS');
    await app.close();
  });

  it('allows only configured browser origins and requires HTTPS in production', async () => {
    const app = await createApp({
      nodeEnv: 'production',
      trustedProxyIps: '127.0.0.0/8,::1/128',
      corsAllowedOrigins: 'https://operator.sosedi.ru',
    });

    await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('Origin', 'https://operator.sosedi.ru')
      .expect(426);

    const allowed = await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('X-Forwarded-Proto', 'https')
      .set('Origin', 'https://operator.sosedi.ru')
      .expect(200);
    expect(allowed.headers['access-control-allow-origin']).toBe(
      'https://operator.sosedi.ru',
    );

    const disallowed = await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('X-Forwarded-Proto', 'https')
      .set('Origin', 'https://attacker.example')
      .expect(200);
    expect(disallowed.headers['access-control-allow-origin']).toBeUndefined();
    await app.close();
  });

  it('requires an update only for an explicitly incompatible mobile client', async () => {
    const app = await createApp({
      minSupportedMobileVersion: '2.1.0',
      androidUpdateUrl: 'https://store.example/sosedi',
    });

    const outdated = await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('X-Api-Version', '1')
      .set('X-Mobile-Version', '2.0.9')
      .set('X-Mobile-Platform', 'android')
      .expect(426);

    expect(outdated.body).toEqual({
      success: false,
      data: null,
      error: {
        code: 'MOBILE_UPDATE_REQUIRED',
        message: 'Требуется версия приложения 2.1.0 или новее',
      },
    });
    expect(outdated.headers['x-min-mobile-version']).toBe('2.1.0');
    expect(outdated.headers['x-mobile-update-url']).toBe(
      'https://store.example/sosedi',
    );

    await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('X-Api-Version', '1')
      .set('X-Mobile-Version', '2.1.0')
      .set('X-Mobile-Platform', 'android')
      .expect(200);
    await app.close();
  });

  it('rejects an explicitly unsupported API contract', async () => {
    const app = await createApp();

    const response = await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .set('X-Api-Version', '2')
      .expect(426);

    expect(response.body).toEqual({
      success: false,
      data: null,
      error: {
        code: 'API_VERSION_UNSUPPORTED',
        message: 'Эта версия API больше не поддерживается',
      },
    });
    await app.close();
  });

  it('fails startup for an unsafe mobile update URL', async () => {
    const moduleFixture = await Test.createTestingModule({
      controllers: [TestIpController],
    }).compile();
    const app = moduleFixture.createNestApplication({ bodyParser: false });

    expect(() =>
      configureApp(app, {
        androidUpdateUrl: 'http://store.example/sosedi',
      }),
    ).toThrow('ANDROID_UPDATE_URL');
    await app.close();
  });

  it('adds baseline security headers', async () => {
    const app = await createApp();

    const response = await request(app.getHttpServer())
      .get('/api/v1/test-ip')
      .expect(200);

    expect(response.headers['x-content-type-options']).toBe('nosniff');
    expect(response.headers['x-frame-options']).toBe('DENY');
    expect(response.headers['content-security-policy']).toContain(
      "frame-ancestors 'none'",
    );
    expect(response.headers['referrer-policy']).toBe('no-referrer');
    await app.close();
  });

  it('does not expose internal error details or stack traces', async () => {
    const app = await createApp();
    const consoleError = jest
      .spyOn(console, 'error')
      .mockImplementation(() => undefined);

    const response = await request(app.getHttpServer())
      .get('/api/v1/test-ip/error')
      .expect(500);

    const responseText = JSON.stringify(response.body);
    expect(responseText).not.toContain('sensitive internal failure');
    expect(responseText).not.toContain('app.setup.spec.ts');
    expect(response.body).toEqual({
      success: false,
      data: null,
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Внутренняя ошибка сервера',
      },
    });
    expect(consoleError).toHaveBeenCalledTimes(1);
    consoleError.mockRestore();
    await app.close();
  });

  it('rejects a JSON body larger than the configured limit', async () => {
    const app = await createApp({ bodyLimit: '1kb' });

    await request(app.getHttpServer())
      .post('/api/v1/test-ip/echo')
      .send({ value: 'x'.repeat(2048) })
      .expect(413);
    await app.close();
  });

  it('applies bounded HTTP server timeouts', () => {
    const server = createServer();

    configureHttpServer(server, {
      requestTimeoutMs: 30_000,
      headersTimeoutMs: 15_000,
      keepAliveTimeoutMs: 5_000,
    });

    expect(server.requestTimeout).toBe(30_000);
    expect(server.headersTimeout).toBe(15_000);
    expect(server.keepAliveTimeout).toBe(5_000);
    expect(server.timeout).toBe(30_000);
    server.close();
  });
});
