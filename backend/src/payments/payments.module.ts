import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { DepositService } from './deposit.service';
import { FakeSafeDealController } from './fake-safe-deal.controller';
import { FakeSafeDealProvider } from './fake-safe-deal.provider';
import { MarketplacePolicyController } from './marketplace-policy.controller';
import { PaymentPolicyService } from './payment-policy.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [MarketplacePolicyController, FakeSafeDealController],
  providers: [DepositService, FakeSafeDealProvider, PaymentPolicyService],
  exports: [DepositService, FakeSafeDealProvider, PaymentPolicyService],
})
export class PaymentsModule {}
