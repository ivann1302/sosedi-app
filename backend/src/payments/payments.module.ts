import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { DepositDeadlineService } from './deposit-deadline.service';
import { DepositOperationProcessor } from './deposit-operation.processor';
import { DepositService } from './deposit.service';
import { FakeSafeDealController } from './fake-safe-deal.controller';
import { FakeSafeDealGuard } from './fake-safe-deal.guard';
import { FakeSafeDealProvider } from './fake-safe-deal.provider';
import { MarketplacePolicyController } from './marketplace-policy.controller';
import { PaymentPolicyService } from './payment-policy.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [MarketplacePolicyController, FakeSafeDealController],
  providers: [
    DepositDeadlineService,
    DepositOperationProcessor,
    DepositService,
    FakeSafeDealGuard,
    FakeSafeDealProvider,
    PaymentPolicyService,
  ],
  exports: [DepositService, FakeSafeDealProvider, PaymentPolicyService],
})
export class PaymentsModule {}
