import {
  Body,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  NotFoundException,
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
import type { ProviderOperationResult } from './fake-safe-deal.provider';
import { PaymentPolicyService } from './payment-policy.service';

@ApiTags('fake-safe-deal')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('dev/fake-safe-deal/bookings')
export class FakeSafeDealController {
  constructor(
    private readonly deposits: DepositService,
    private readonly paymentPolicy: PaymentPolicyService,
  ) {}

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
    try {
      this.paymentPolicy.requireFakeSafeDeal();
    } catch {
      throw new NotFoundException('Ресурс не найден');
    }
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
