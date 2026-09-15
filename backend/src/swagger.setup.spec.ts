import { Controller, Get, type INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { configureApp } from './app.setup';
import { configureSwagger } from './swagger.setup';

@Controller('swagger-smoke')
class SwaggerSmokeController {
  @Get()
  get(): { status: string } {
    return { status: 'ok' };
  }
}

describe('Swagger environment policy', () => {
  async function createApp(nodeEnv: string): Promise<INestApplication<App>> {
    const moduleFixture = await Test.createTestingModule({
      controllers: [SwaggerSmokeController],
    }).compile();
    const app = moduleFixture.createNestApplication({ bodyParser: false });
    configureApp(app, {
      nodeEnv: 'test',
      corsAllowedOrigins: '',
    });
    configureSwagger(app, nodeEnv);
    await app.init();
    return app;
  }

  it('does not expose Swagger UI or OpenAPI JSON in production', async () => {
    const app = await createApp('production');

    await request(app.getHttpServer()).get('/api/docs').expect(404);
    await request(app.getHttpServer()).get('/api/docs-json').expect(404);
    await app.close();
  });

  it('keeps Swagger available for local development', async () => {
    const app = await createApp('development');

    const response = await request(app.getHttpServer())
      .get('/api/docs-json')
      .expect(200);
    const document = response.body as { info: { title: string } };
    expect(document.info.title).toBe('Всё рядом API');
    await app.close();
  });
});
