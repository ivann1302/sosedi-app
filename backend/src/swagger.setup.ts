import type { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ADMIN_SESSION_COOKIE } from './admin/admin-session.service';

export function configureSwagger(
  app: INestApplication,
  nodeEnv = process.env.NODE_ENV ?? 'development',
): boolean {
  if (nodeEnv === 'production') {
    return false;
  }

  const config = new DocumentBuilder()
    .setTitle('Всё рядом API')
    .setVersion('1.0')
    .addBearerAuth()
    .addCookieAuth(ADMIN_SESSION_COOKIE)
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);
  return true;
}
