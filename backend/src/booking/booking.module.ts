import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { UploadModule } from '../upload/upload.module';
import { UsersModule } from '../users/users.module';
import { BookingActController } from './booking-act.controller';
import { BookingActService } from './booking-act.service';
import { BookingAvailabilityController } from './booking-availability.controller';
import { BookingAvailabilityService } from './booking-availability.service';
import { BookingController } from './booking.controller';
import { BookingMessageController } from './booking-message.controller';
import { BookingMessageService } from './booking-message.service';
import { BookingExpiryService } from './booking-expiry.service';
import { BookingOutboxProcessor } from './booking-outbox.processor';
import { BookingService } from './booking.service';
import { InboxController } from './inbox.controller';
import { InboxService } from './inbox.service';

@Module({
  imports: [AuthModule, PrismaModule, UploadModule, UsersModule],
  controllers: [
    BookingController,
    BookingMessageController,
    BookingAvailabilityController,
    BookingActController,
    InboxController,
  ],
  providers: [
    BookingService,
    BookingMessageService,
    BookingAvailabilityService,
    BookingExpiryService,
    BookingOutboxProcessor,
    BookingActService,
    InboxService,
  ],
  exports: [BookingExpiryService, BookingOutboxProcessor],
})
export class BookingModule {}
