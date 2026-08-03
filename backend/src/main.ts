import { NestFactory } from '@nestjs/core';
import type { Server } from 'node:http';
import { AppModule } from './app.module';
import { configureApp, configureHttpServer } from './app.setup';
import { RedactingLogger } from './common/logging/redacting-logger';
import { configureSwagger } from './swagger.setup';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bodyParser: false,
    logger: new RedactingLogger(),
  });
  configureApp(app);
  configureSwagger(app);
  configureHttpServer(app.getHttpServer() as Server);

  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
