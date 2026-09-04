import { Module } from '@nestjs/common';
import { AdminModule } from '../admin/admin.module';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { UploadModule } from '../upload/upload.module';
import { AdminDisputeController } from './admin-dispute.controller';
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

@Module({
  imports: [AdminModule, AuthModule, PrismaModule, UploadModule],
  controllers: [
    MarketplacePolicyController,
    FakeSafeDealController,
    DisputeController,
    AdminDisputeController,
  ],
  providers: [
    DepositDeadlineService,
    DepositOperationProcessor,
    DepositService,
    DisputeService,
    FakeSafeDealGuard,
    FakeSafeDealProvider,
    PaymentPolicyService,
  ],
  exports: [DepositService, FakeSafeDealProvider, PaymentPolicyService],
})
export class PaymentsModule {}
