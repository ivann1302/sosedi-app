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

  it('requires FAKE_SAFE_DEAL before a fake payment command', () => {
    expect(() => createService().requireFakeSafeDeal()).toThrow(
      'FAKE_SAFE_DEAL_REQUIRED',
    );
    expect(() =>
      createService(completeFakePolicy).requireFakeSafeDeal(),
    ).not.toThrow();
  });

  it.each([
    {
      scenario: 'PAY_ON_HANDOVER',
      amountMinor: -1n,
      error: 'Deposit amount cannot be negative',
    },
    {
      scenario: 'PAY_ON_HANDOVER',
      amountMinor: 0n,
      error: null,
    },
    {
      scenario: 'PAY_ON_HANDOVER',
      amountMinor: 1n,
      error: 'Deposits require FAKE_SAFE_DEAL',
    },
    {
      scenario: 'FAKE_SAFE_DEAL',
      amountMinor: 10_000_000n,
      error: null,
    },
    {
      scenario: 'FAKE_SAFE_DEAL',
      amountMinor: 10_000_001n,
      error: 'Deposit exceeds the active policy maximum',
    },
  ])(
    'enforces $scenario deposit boundary for $amountMinor',
    ({ scenario, amountMinor, error }) => {
      const service = createService(
        scenario === 'FAKE_SAFE_DEAL'
          ? completeFakePolicy
          : { PAYMENT_SCENARIO: scenario },
      );

      if (error) {
        expect(() => service.assertDepositAllowed(amountMinor)).toThrow(error);
        return;
      }
      expect(() => service.assertDepositAllowed(amountMinor)).not.toThrow();
    },
  );
});
