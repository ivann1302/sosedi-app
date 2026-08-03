import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { DeviceTokensController } from './device-tokens.controller';
import { DeviceTokensService } from './device-tokens.service';
import { DisabledPushProvider } from './disabled-push.provider';
import { PushDeliveryProcessor } from './push-delivery.processor';
import { PUSH_PROVIDER } from './push-provider';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [DeviceTokensController],
  providers: [
    DeviceTokensService,
    DisabledPushProvider,
    {
      provide: PUSH_PROVIDER,
      useExisting: DisabledPushProvider,
    },
    PushDeliveryProcessor,
  ],
  exports: [DeviceTokensService, PushDeliveryProcessor],
})
export class NotificationsModule {}
