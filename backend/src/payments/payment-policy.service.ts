import {
  BadRequestException,
  Injectable,
  type OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export enum PaymentScenario {
  PAY_ON_HANDOVER = 'PAY_ON_HANDOVER',
  FAKE_SAFE_DEAL = 'FAKE_SAFE_DEAL',
  SAFE_DEAL = 'SAFE_DEAL',
}

export type MarketplacePolicy = {
  paymentScenario: PaymentScenario;
  deposit: {
    enabled: boolean;
    currency: 'RUB';
    maximumMinor: number | null;
    policyVersion: string | null;
    disputeWindowSeconds: number | null;
  };
};

@Injectable()
export class PaymentPolicyService implements OnModuleInit {
  private policy!: MarketplacePolicy;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    this.policy = this.parse();
  }

  current(): MarketplacePolicy {
    return this.policy;
  }

  requireFakeSafeDeal(): void {
    if (this.policy.paymentScenario !== PaymentScenario.FAKE_SAFE_DEAL) {
      throw new BadRequestException('FAKE_SAFE_DEAL_REQUIRED');
    }
  }

  assertDepositAllowed(amountMinor: bigint): void {
    if (amountMinor < 0n) {
      throw new BadRequestException('Deposit amount cannot be negative');
    }
    if (
      this.policy.paymentScenario === PaymentScenario.PAY_ON_HANDOVER &&
      amountMinor !== 0n
    ) {
      throw new BadRequestException('Deposits require FAKE_SAFE_DEAL');
    }
    if (
      this.policy.paymentScenario === PaymentScenario.FAKE_SAFE_DEAL &&
      amountMinor > BigInt(this.policy.deposit.maximumMinor ?? 0)
    ) {
      throw new BadRequestException(
        'Deposit exceeds the active policy maximum',
      );
    }
  }

  private parse(): MarketplacePolicy {
    const scenario = this.config.get<string>('PAYMENT_SCENARIO')?.trim();

    if (!scenario || scenario === 'PAY_ON_HANDOVER') {
      return {
        paymentScenario: PaymentScenario.PAY_ON_HANDOVER,
        deposit: {
          enabled: false,
          currency: 'RUB',
          maximumMinor: null,
          policyVersion: null,
          disputeWindowSeconds: null,
        },
      };
    }

    if (scenario === 'SAFE_DEAL') {
      throw new Error('SAFE_DEAL_PROVIDER_NOT_CONFIGURED');
    }
    if (scenario !== 'FAKE_SAFE_DEAL') {
      throw new Error('PAYMENT_SCENARIO is invalid');
    }
    if (
      this.config.get<string>('NODE_ENV') === 'production' ||
      this.config.get<string>('DEPLOYMENT_ENVIRONMENT') === 'production'
    ) {
      throw new Error('FAKE_SAFE_DEAL is not allowed in production');
    }

    const maximumRaw = this.config
      .get<string>('FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR')
      ?.trim();
    const policyVersion = this.config
      .get<string>('FAKE_SAFE_DEAL_POLICY_VERSION')
      ?.trim();
    const disputeWindowRaw = this.config
      .get<string>('FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS')
      ?.trim();
    if (!maximumRaw || !policyVersion || !disputeWindowRaw) {
      throw new Error(
        'FAKE_SAFE_DEAL requires complete deposit policy configuration',
      );
    }

    return {
      paymentScenario: PaymentScenario.FAKE_SAFE_DEAL,
      deposit: {
        enabled: true,
        currency: 'RUB',
        maximumMinor: this.parsePositiveSafeInteger(
          maximumRaw,
          'FAKE_SAFE_DEAL_DEPOSIT_MAX_MINOR',
        ),
        policyVersion,
        disputeWindowSeconds: this.parsePositiveSafeInteger(
          disputeWindowRaw,
          'FAKE_SAFE_DEAL_DISPUTE_WINDOW_SECONDS',
        ),
      },
    };
  }

  private parsePositiveSafeInteger(value: string, name: string): number {
    const parsed = Number(value);
    if (!Number.isSafeInteger(parsed) || parsed <= 0) {
      throw new Error(`${name} must be a positive safe integer`);
    }
    return parsed;
  }
}
