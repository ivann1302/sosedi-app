import { Module } from '@nestjs/common';
import { FakePaymentProvider } from './fake-payment.provider';
import { MarketplacePolicyController } from './marketplace-policy.controller';
import { PaymentPolicyService } from './payment-policy.service';

@Module({
  controllers: [MarketplacePolicyController],
  providers: [FakePaymentProvider, PaymentPolicyService],
  exports: [FakePaymentProvider, PaymentPolicyService],
})
export class PaymentsModule {}
