import { MODULE_METADATA } from '@nestjs/common/constants';
import { DepositDeadlineService } from './deposit-deadline.service';
import { DepositOperationProcessor } from './deposit-operation.processor';
import { DepositService } from './deposit.service';
import { DisputeController } from './dispute.controller';
import { DisputeService } from './dispute.service';
import { FakeSafeDealController } from './fake-safe-deal.controller';
import { FakeSafeDealGuard } from './fake-safe-deal.guard';
import { FakeSafeDealProvider } from './fake-safe-deal.provider';
import { MarketplacePolicyController } from './marketplace-policy.controller';
import { PaymentPolicyService } from './payment-policy.service';
import { PaymentsModule } from './payments.module';

describe('PaymentsModule payment policy boundary', () => {
  it('exposes the public policy and no manual payout service', () => {
    expect(
      Reflect.getMetadata(MODULE_METADATA.CONTROLLERS, PaymentsModule) ?? [],
    ).toEqual([
      MarketplacePolicyController,
      FakeSafeDealController,
      DisputeController,
    ]);
    expect(
      Reflect.getMetadata(MODULE_METADATA.PROVIDERS, PaymentsModule),
    ).toEqual([
      DepositDeadlineService,
      DepositOperationProcessor,
      DepositService,
      DisputeService,
      FakeSafeDealGuard,
      FakeSafeDealProvider,
      PaymentPolicyService,
    ]);
  });
});
