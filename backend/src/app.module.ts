import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminModule } from './admin/admin.module';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { CategoriesModule } from './categories/categories.module';
import { ItemsModule } from './items/items.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ObservabilityModule } from './observability/observability.module';
import { UploadModule } from './upload/upload.module';
import { BookingModule } from './booking/booking.module';
import { PaymentsModule } from './payments/payments.module';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { ReportsModule } from './reports/reports.module';
import { ReviewsModule } from './reviews/reviews.module';
import { SupportModule } from './support/support.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    RedisModule,
    ObservabilityModule,
    AuthModule,
    UsersModule,
    CategoriesModule,
    ItemsModule,
    NotificationsModule,
    UploadModule,
    BookingModule,
    PaymentsModule,
    ReportsModule,
    ReviewsModule,
    SupportModule,
    AdminModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
