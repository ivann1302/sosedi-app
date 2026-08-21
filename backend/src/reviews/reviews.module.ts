import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { BookingReviewsController } from './booking-reviews.controller';
import { PublicReviewsController } from './public-reviews.controller';
import { ReviewsService } from './reviews.service';

@Module({
  imports: [AuthModule, PrismaModule],
  controllers: [BookingReviewsController, PublicReviewsController],
  providers: [ReviewsService],
  exports: [ReviewsService],
})
export class ReviewsModule {}
