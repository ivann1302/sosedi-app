import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { Request } from 'express';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { getRequestId } from '../common/http/request-id';
import { BookingService } from './booking.service';
import { BookingResponseDto } from './dto/booking-response.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { ExtendBookingDto } from './dto/extend-booking.dto';
import { ParticipantBookingResponseDto } from './dto/participant-booking-response.dto';

@ApiTags('bookings')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('bookings')
export class BookingController {
  constructor(private readonly bookings: BookingService) {}

  @ApiCreatedResponse({ type: BookingResponseDto })
  @Post()
  async create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateBookingDto,
    @Req() request: Request,
  ): Promise<ApiResponse<BookingResponseDto>> {
    return ok(await this.bookings.create(user.id, dto, getRequestId(request)));
  }

  @ApiOkResponse({ type: [ParticipantBookingResponseDto] })
  @Get()
  async list(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<ParticipantBookingResponseDto[]>> {
    return ok(await this.bookings.listForParticipant(user.id));
  }

  @ApiOkResponse({ type: ParticipantBookingResponseDto })
  @Get(':id')
  async get(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<ParticipantBookingResponseDto>> {
    return ok(await this.bookings.getForParticipant(user.id, id));
  }

  @ApiOkResponse({ type: BookingResponseDto })
  @HttpCode(HttpStatus.OK)
  @Post(':id/confirm')
  async confirm(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Req() request: Request,
  ): Promise<ApiResponse<BookingResponseDto>> {
    return ok(await this.bookings.confirm(user.id, id, getRequestId(request)));
  }

  @ApiOkResponse({ type: BookingResponseDto })
  @HttpCode(HttpStatus.OK)
  @Post(':id/cancel')
  async cancel(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Req() request: Request,
  ): Promise<ApiResponse<BookingResponseDto>> {
    return ok(
      await this.bookings.cancelPending(user.id, id, getRequestId(request)),
    );
  }

  @Post(':id/extend')
  async rejectExtension(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ExtendBookingDto,
  ): Promise<never> {
    return this.bookings.rejectExtension(user.id, id, dto);
  }
}
