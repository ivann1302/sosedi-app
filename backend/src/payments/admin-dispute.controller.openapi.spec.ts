import { type INestApplication } from '@nestjs/common';
import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
} from '@nestjs/swagger';
import { Test } from '@nestjs/testing';
import { AdminSessionGuard } from '../admin/admin-session.guard';
import { configureApp } from '../app.setup';
import { AdminDisputeController } from './admin-dispute.controller';
import { DepositService } from './deposit.service';
import { DisputeService } from './dispute.service';

describe('AdminDisputeController OpenAPI contract', () => {
  let app: INestApplication | undefined;
  let document: OpenAPIObject;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      controllers: [AdminDisputeController],
      providers: [
        { provide: DisputeService, useValue: {} },
        { provide: DepositService, useValue: {} },
      ],
    })
      .overrideGuard(AdminSessionGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addCookieAuth('admin_session').build(),
    );
  });

  afterAll(async () => {
    await app?.close();
  });

  it('documents actual success statuses and envelopes for all four admin routes', () => {
    const routes = [
      {
        response:
          document.paths['/api/v1/admin/disputes']?.get?.responses['200'],
        data: {
          type: 'array',
          items: { $ref: '#/components/schemas/AdminDisputeResponseDto' },
        },
      },
      {
        response:
          document.paths[
            '/api/v1/admin/disputes/{id}/evidence/{evidenceId}/download-url'
          ]?.get?.responses['200'],
        data: {
          $ref: '#/components/schemas/DisputeEvidenceDownloadResponseDto',
        },
      },
      {
        response:
          document.paths['/api/v1/admin/disputes/{id}/resolve']?.post
            ?.responses['201'],
        data: { $ref: '#/components/schemas/DisputeResponseDto' },
      },
      {
        response:
          document.paths['/api/v1/admin/deposit-operations/{id}/retry']?.post
            ?.responses['201'],
        data: {
          $ref: '#/components/schemas/DepositOperationCommandResponseDto',
        },
      },
    ];

    for (const route of routes) {
      expect(route.response).toEqual(
        expect.objectContaining({
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['success', 'data', 'error'],
                properties: {
                  success: { type: 'boolean', example: true },
                  data: route.data,
                  error: { type: 'object', nullable: true, example: null },
                },
              },
            },
          },
        }),
      );
    }

    expect(
      document.paths['/api/v1/admin/disputes/{id}/resolve']?.post?.responses[
        '200'
      ],
    ).toBeUndefined();
    expect(
      document.paths['/api/v1/admin/deposit-operations/{id}/retry']?.post
        ?.responses['200'],
    ).toBeUndefined();
    expect(
      document.components?.schemas?.DepositOperationCommandResponseDto,
    ).toEqual({
      type: 'object',
      properties: {
        id: { type: 'string', format: 'uuid' },
        depositId: { type: 'string', format: 'uuid' },
        kind: {
          type: 'string',
          enum: ['HOLD', 'CANCEL', 'REFUND', 'RELEASE_TO_LENDER'],
        },
        amountMinor: { type: 'number', minimum: 0 },
        status: {
          type: 'string',
          enum: ['PENDING', 'SUCCEEDED', 'FAILED'],
        },
        retryOfId: { type: 'string', format: 'uuid', nullable: true },
      },
      required: [
        'id',
        'depositId',
        'kind',
        'amountMinor',
        'status',
        'retryOfId',
      ],
    });
    expect(document.components?.schemas?.AdminDisputeResponseDto).toEqual({
      type: 'object',
      properties: {
        id: { type: 'string', format: 'uuid' },
        bookingId: { type: 'string', format: 'uuid' },
        reason: {
          type: 'string',
          enum: ['ITEM_DAMAGED', 'ITEM_LOST', 'OTHER'],
        },
        description: { type: 'string', nullable: true },
        status: {
          type: 'string',
          enum: ['OPEN', 'UNDER_REVIEW', 'RESOLVED'],
        },
        refundToBorrowerMinor: { type: 'number', minimum: 0 },
        releaseToLenderMinor: { type: 'number', minimum: 0 },
        depositAmountMinor: { type: 'number', minimum: 0 },
        depositStatus: {
          type: 'string',
          enum: [
            'PENDING',
            'HELD',
            'DISPUTED',
            'RESOLVING',
            'RESOLVED',
            'CANCELLED',
          ],
        },
        disputeWindowEndsAt: {
          type: 'string',
          format: 'date-time',
          nullable: true,
        },
        openedAt: { type: 'string', format: 'date-time' },
        resolvedAt: {
          type: 'string',
          format: 'date-time',
          nullable: true,
        },
        evidence: {
          type: 'array',
          items: { $ref: '#/components/schemas/DisputeEvidenceResponseDto' },
        },
        failedOperations: {
          type: 'array',
          items: {
            $ref: '#/components/schemas/AdminFailedDepositOperationResponseDto',
          },
        },
      },
      required: [
        'id',
        'bookingId',
        'reason',
        'description',
        'status',
        'refundToBorrowerMinor',
        'releaseToLenderMinor',
        'depositAmountMinor',
        'depositStatus',
        'disputeWindowEndsAt',
        'openedAt',
        'resolvedAt',
        'evidence',
        'failedOperations',
      ],
    });
  });
});
