import { ConfigService } from '@nestjs/config';
import {
  PaymentPolicyService,
  PaymentScenario,
} from './payment-policy.service';

const completeFakePolicy = {
  PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
  FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '10000000',
  FAKE_SAFE_DEAL_POLICY_VERSION: 'fake-deposit-2026-09-02',
  FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS: '300',
};

function createService(values: Record<string, string | undefined> = {}) {
  const config: Record<string, string | undefined> = {
    NODE_ENV: 'test',
    ...values,
  };
  const service = new PaymentPolicyService(new ConfigService(config));

  service.onModuleInit();
  return service;
}

describe('PaymentPolicyService', () => {
  it('defaults to PAY_ON_HANDOVER without deposit terms', () => {
    expect(createService().current()).toEqual({
      paymentScenario: PaymentScenario.PAY_ON_HANDOVER,
      deposit: {
        enabled: false,
        currency: 'RUB',
        maximumMinor: null,
        policyVersion: null,
        disputeWindowSeconds: null,
      },
    });
  });

  it.each(['development', 'staging', 'test'])(
    'accepts a complete fake policy in %s',
    (nodeEnv) => {
      expect(
        createService({ NODE_ENV: nodeEnv, ...completeFakePolicy }).current(),
      ).toEqual({
        paymentScenario: PaymentScenario.FAKE_SAFE_DEAL,
        deposit: {
          enabled: true,
          currency: 'RUB',
          maximumMinor: 10_000_000,
          policyVersion: 'fake-deposit-2026-09-02',
          disputeWindowSeconds: 300,
        },
      });
    },
  );

  it.each([
    { NODE_ENV: 'production' },
    { DEPLOYMENT_ENVIRONMENT: 'production' },
  ])('rejects fake policy in production', (environment) => {
    expect(() =>
      createService({ ...environment, ...completeFakePolicy }),
    ).toThrow('FAKE_SAFE_DEAL is not allowed in production');
  });

  it('rejects a partial fake policy', () => {
    expect(() =>
      createService({
        PAYMENT_SCENARIO: 'FAKE_SAFE_DEAL',
        FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: '10000000',
      }),
    ).toThrow('FAKE_SAFE_DEAL requires complete deposit policy configuration');
  });

  it.each(['0', '9007199254740992'])(
    'rejects a zero or unsafe fake deposit maximum: %s',
    (maximum) => {
      expect(() =>
        createService({
          ...completeFakePolicy,
          FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR: maximum,
        }),
      ).toThrow(
        'FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR must be a positive safe integer',
      );
    },
  );

  it('rejects SAFE_DEAL while no provider is configured', () => {
    expect(() => createService({ PAYMENT_SCENARIO: 'SAFE_DEAL' })).toThrow(
      'SAFE_DEAL_PROVIDER_NOT_CONFIGURED',
    );
  });
});
