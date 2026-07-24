import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication<App> | undefined;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  it('/health (GET)', () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    return request(app.getHttpServer())
      .get('/api/v1/health')
      .expect(200)
      .expect({
        success: true,
        data: { status: 'ok' },
        error: null,
      });
  });

  afterEach(async () => {
    await app?.close();
  });
});
