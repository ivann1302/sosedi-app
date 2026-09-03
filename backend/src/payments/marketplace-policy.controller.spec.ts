import { type INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { configureApp } from '../app.setup';
import { configureSwagger } from '../swagger.setup';
import { MarketplacePolicyController } from './marketplace-policy.controller';
import {
  PaymentPolicyService,
  PaymentScenario,
  type MarketplacePolicy,
} from './payment-policy.service';

const policy: MarketplacePolicy = {
  paymentScenario: PaymentScenario.PAY_ON_HANDOVER,
  deposit: {
    enabled: false,
    currency: 'RUB',
    maximumMinor: null,
    policyVersion: null,
    disputeWindowSeconds: null,
  },
};

describe('MarketplacePolicyController', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture = await Test.createTestingModule({
      controllers: [MarketplacePolicyController],
      providers: [
        {
          provide: PaymentPolicyService,
          useValue: { current: () => policy },
        },
      ],
    }).compile();
    app = moduleFixture.createNestApplication({ bodyParser: false });
    configureApp(app, { nodeEnv: 'test', corsAllowedOrigins: '' });
    configureSwagger(app, 'development');
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('returns the unauthenticated marketplace policy in the standard envelope', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/marketplace-policy')
      .expect(200);

    expect(response.body).toEqual({ success: true, data: policy, error: null });
  });

  it('documents the standard envelope in OpenAPI', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/docs-json')
      .expect(200);

    const document = response.body as {
      paths: {
        '/api/v1/marketplace-policy': {
          get: {
            responses: {
              '200': {
                content: { 'application/json': { schema: unknown } };
              };
            };
          };
        };
      };
    };

    expect(
      document.paths['/api/v1/marketplace-policy'].get.responses['200'].content[
        'application/json'
      ].schema,
    ).toEqual({
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: {
          $ref: '#/components/schemas/MarketplacePolicyResponseDto',
        },
        error: { type: 'object', nullable: true, example: null },
      },
    });
  });
});
