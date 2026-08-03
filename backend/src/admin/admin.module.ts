import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PrismaModule } from '../prisma/prisma.module';
import { RedisModule } from '../redis/redis.module';
import { AdminController } from './admin.controller';
import { AdminMfaService } from './admin-mfa.service';
import { AdminSessionController } from './admin-session.controller';
import { AdminSessionGuard } from './admin-session.guard';
import { AdminSessionService } from './admin-session.service';
import { AdminService } from './admin.service';

@Module({
  imports: [AuthModule, PrismaModule, RedisModule],
  controllers: [AdminController, AdminSessionController],
  providers: [
    AdminService,
    AdminMfaService,
    AdminSessionService,
    AdminSessionGuard,
  ],
  exports: [AdminSessionService, AdminSessionGuard],
})
export class AdminModule {}
