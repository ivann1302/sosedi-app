import { MODULE_METADATA } from '@nestjs/common/constants';
import { FakePaymentProvider } from './fake-payment.provider';
import { PaymentsModule } from './payments.module';

describe('PaymentsModule pre-provider boundary', () => {
  it('exposes no HTTP controller or manual payout service', () => {
    expect(
      Reflect.getMetadata(MODULE_METADATA.CONTROLLERS, PaymentsModule) ?? [],
    ).toEqual([]);
    expect(
      Reflect.getMetadata(MODULE_METADATA.PROVIDERS, PaymentsModule),
    ).toEqual([FakePaymentProvider]);
  });
});
