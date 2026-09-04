import {
  Body,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiHeader,
  ApiOkResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { DepositService } from './deposit.service';
import { FakeCheckoutDto } from './dto/fake-checkout.dto';
import { FakeSafeDealGuard } from './fake-safe-deal.guard';
import type { ProviderOperationResult } from './fake-safe-deal.provider';

@ApiTags('fake-safe-deal')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(FakeSafeDealGuard, JwtAuthGuard, RolesGuard)
@Controller('dev/fake-safe-deal/bookings')
export class FakeSafeDealController {
  constructor(private readonly deposits: DepositService) {}

  @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiOkResponse()
  @HttpCode(HttpStatus.OK)
  @Post(':bookingId/checkout')
  async checkout(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Body() dto: FakeCheckoutDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ): Promise<ApiResponse<ProviderOperationResult>> {
    return ok(
      await this.deposits.checkout(
        user.id,
        bookingId,
        dto.outcome,
        idempotencyKey ?? '',
      ),
    );
  }
}
