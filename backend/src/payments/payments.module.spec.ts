import { MODULE_METADATA } from '@nestjs/common/constants';
import { DepositService } from './deposit.service';
import { FakeSafeDealController } from './fake-safe-deal.controller';
import { FakeSafeDealProvider } from './fake-safe-deal.provider';
import { MarketplacePolicyController } from './marketplace-policy.controller';
import { PaymentPolicyService } from './payment-policy.service';
import { PaymentsModule } from './payments.module';

describe('PaymentsModule payment policy boundary', () => {
  it('exposes the public policy and no manual payout service', () => {
    expect(
      Reflect.getMetadata(MODULE_METADATA.CONTROLLERS, PaymentsModule) ?? [],
    ).toEqual([MarketplacePolicyController, FakeSafeDealController]);
    expect(
      Reflect.getMetadata(MODULE_METADATA.PROVIDERS, PaymentsModule),
    ).toEqual([DepositService, FakeSafeDealProvider, PaymentPolicyService]);
  });
});
