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
import { PrivateFileDownloadResponse } from '../upload/upload.types';
import { BookingActService } from './booking-act.service';
import { BookingActResponseDto } from './dto/booking-act-response.dto';
import { CreateBookingActDto } from './dto/create-booking-act.dto';

@ApiTags('bookings')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('bookings/:bookingId')
export class BookingActController {
  constructor(private readonly acts: BookingActService) {}

  @ApiOkResponse({ type: [BookingActResponseDto] })
  @Get('acts')
  async list(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
  ): Promise<ApiResponse<BookingActResponseDto[]>> {
    return ok(await this.acts.list(user.id, bookingId));
  }

  @ApiCreatedResponse({ type: BookingActResponseDto })
  @Post('acts')
  async create(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Body() dto: CreateBookingActDto,
  ): Promise<ApiResponse<BookingActResponseDto>> {
    return ok(await this.acts.create(user.id, bookingId, dto));
  }

  @ApiOkResponse({ type: BookingActResponseDto })
  @HttpCode(HttpStatus.OK)
  @Post('acts/:actId/confirm')
  async confirm(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Param('actId', ParseUUIDPipe) actId: string,
    @Req() request: Request,
  ): Promise<ApiResponse<BookingActResponseDto>> {
    return ok(
      await this.acts.confirm(user.id, bookingId, actId, getRequestId(request)),
    );
  }

  @ApiOkResponse({ description: 'Короткий private evidence download URL' })
  @Get('evidence/:evidenceId/download-url')
  async getEvidenceDownload(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Param('evidenceId', ParseUUIDPipe) evidenceId: string,
  ): Promise<ApiResponse<PrivateFileDownloadResponse>> {
    return ok(
      await this.acts.getEvidenceDownload(user.id, bookingId, evidenceId),
    );
  }
}
