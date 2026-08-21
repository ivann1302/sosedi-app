import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
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
import { CreateReviewDto } from './dto/create-review.dto';
import { ParticipantReviewResponseDto } from './dto/review-response.dto';
import { ReviewsService } from './reviews.service';

@ApiTags('booking-reviews')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('bookings/:bookingId/reviews')
export class BookingReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @ApiCreatedResponse({ type: ParticipantReviewResponseDto })
  @Post()
  async create(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Body() dto: CreateReviewDto,
  ): Promise<ApiResponse<ParticipantReviewResponseDto>> {
    return ok(await this.reviews.create(user.id, bookingId, dto));
  }

  @ApiOkResponse({ type: [ParticipantReviewResponseDto] })
  @Get()
  async list(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
  ): Promise<ApiResponse<ParticipantReviewResponseDto[]>> {
    return ok(await this.reviews.listForBooking(user.id, bookingId));
  }
}
