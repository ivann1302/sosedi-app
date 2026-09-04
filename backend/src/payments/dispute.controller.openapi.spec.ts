import { type INestApplication } from '@nestjs/common';
import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
} from '@nestjs/swagger';
import { Test } from '@nestjs/testing';
import { configureApp } from '../app.setup';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { DisputeController } from './dispute.controller';
import { DisputeService } from './dispute.service';

describe('DisputeController OpenAPI contract', () => {
  let app: INestApplication | undefined;
  let document: OpenAPIObject;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      controllers: [DisputeController],
      providers: [{ provide: DisputeService, useValue: {} }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
  });

  afterAll(async () => {
    await app?.close();
  });

  it('documents standard success envelopes for all four dispute routes', () => {
    const routes = [
      {
        schema:
          document.paths['/api/v1/bookings/{bookingId}/disputes']?.post
            ?.responses['201'],
        dataRef: '#/components/schemas/DisputeResponseDto',
      },
      {
        schema:
          document.paths['/api/v1/bookings/{bookingId}/dispute']?.get
            ?.responses['200'],
        dataRef: '#/components/schemas/DisputeResponseDto',
      },
      {
        schema:
          document.paths[
            '/api/v1/bookings/{bookingId}/disputes/{disputeId}/evidence'
          ]?.post?.responses['201'],
        dataRef: '#/components/schemas/DisputeEvidenceResponseDto',
      },
      {
        schema:
          document.paths[
            '/api/v1/bookings/{bookingId}/disputes/{disputeId}/evidence/{evidenceId}/download-url'
          ]?.get?.responses['200'],
        dataRef: '#/components/schemas/DisputeEvidenceDownloadResponseDto',
      },
    ];

    for (const route of routes) {
      expect(route.schema).toEqual(
        expect.objectContaining({
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['success', 'data', 'error'],
                properties: {
                  success: { type: 'boolean', example: true },
                  data: { $ref: route.dataRef },
                  error: { type: 'object', nullable: true, example: null },
                },
              },
            },
          },
        }),
      );
    }

    expect(
      document.components?.schemas?.DisputeEvidenceDownloadResponseDto,
    ).toEqual({
      type: 'object',
      properties: {
        downloadUrl: { type: 'string', format: 'uri' },
        expiresInSeconds: { type: 'number', example: 60 },
      },
      required: ['downloadUrl', 'expiresInSeconds'],
    });
    expect(document.components?.schemas?.CreateDisputeDto).toEqual({
      type: 'object',
      properties: {
        reason: {
          type: 'string',
          enum: ['ITEM_DAMAGED', 'ITEM_LOST', 'OTHER'],
        },
        description: { type: 'string', maxLength: 2_000 },
      },
      required: ['reason'],
    });
  });
});
