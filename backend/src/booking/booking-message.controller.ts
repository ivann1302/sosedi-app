import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
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
import { UserBlockResponseDto } from '../users/dto/user-block-response.dto';
import { BookingMessageService } from './booking-message.service';
import {
  BookingMessagePageResponseDto,
  BookingMessageReadResponseDto,
  BookingMessageResponseDto,
} from './dto/booking-message-response.dto';
import { CreateBookingMessageDto } from './dto/create-booking-message.dto';
import { ListBookingMessagesQueryDto } from './dto/list-booking-messages-query.dto';

@ApiTags('booking-chat')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('bookings/:bookingId/messages')
export class BookingMessageController {
  constructor(private readonly messages: BookingMessageService) {}

  @ApiOkResponse({ type: BookingMessagePageResponseDto })
  @Get()
  async list(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Query() query: ListBookingMessagesQueryDto,
  ): Promise<ApiResponse<BookingMessagePageResponseDto>> {
    return ok(await this.messages.list(user.id, bookingId, query));
  }

  @ApiOkResponse({ type: BookingMessageReadResponseDto })
  @Patch('read')
  async markRead(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
  ): Promise<ApiResponse<BookingMessageReadResponseDto>> {
    return ok(await this.messages.markRead(user.id, bookingId));
  }

  @ApiCreatedResponse({ type: UserBlockResponseDto })
  @Post('block-counterparty')
  async blockCounterparty(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
  ): Promise<ApiResponse<UserBlockResponseDto>> {
    return ok(await this.messages.blockCounterparty(user.id, bookingId));
  }

  @ApiCreatedResponse({ type: BookingMessageResponseDto })
  @Post()
  async send(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Body() dto: CreateBookingMessageDto,
  ): Promise<ApiResponse<BookingMessageResponseDto>> {
    return ok(await this.messages.send(user.id, bookingId, dto));
  }
}
