import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiNoContentResponse,
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
import { BookingAvailabilityService } from './booking-availability.service';
import { CreateUnavailablePeriodDto } from './dto/create-unavailable-period.dto';
import { ItemAvailabilityResponseDto } from './dto/item-availability-response.dto';
import { UnavailablePeriodResponseDto } from './dto/unavailable-period-response.dto';

@ApiTags('bookings')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('items/:itemId')
export class BookingAvailabilityController {
  constructor(private readonly availability: BookingAvailabilityService) {}

  @ApiOkResponse({ type: ItemAvailabilityResponseDto })
  @Get('availability')
  async check(
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Query() query: CreateUnavailablePeriodDto,
  ): Promise<ApiResponse<ItemAvailabilityResponseDto>> {
    return ok(await this.availability.check(itemId, query));
  }

  @ApiOkResponse({ type: [UnavailablePeriodResponseDto] })
  @Get('unavailable-periods')
  async listOwn(
    @CurrentUser() user: AuthUser,
    @Param('itemId', ParseUUIDPipe) itemId: string,
  ): Promise<ApiResponse<UnavailablePeriodResponseDto[]>> {
    return ok(await this.availability.listOwn(user.id, itemId));
  }

  @ApiCreatedResponse({ type: UnavailablePeriodResponseDto })
  @Post('unavailable-periods')
  async create(
    @CurrentUser() user: AuthUser,
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Body() dto: CreateUnavailablePeriodDto,
  ): Promise<ApiResponse<UnavailablePeriodResponseDto>> {
    return ok(await this.availability.create(user.id, itemId, dto));
  }

  @ApiNoContentResponse()
  @Delete('unavailable-periods/:periodId')
  async remove(
    @CurrentUser() user: AuthUser,
    @Param('itemId', ParseUUIDPipe) itemId: string,
    @Param('periodId', ParseUUIDPipe) periodId: string,
  ): Promise<ApiResponse<null>> {
    await this.availability.remove(user.id, itemId, periodId);
    return ok(null);
  }
}
