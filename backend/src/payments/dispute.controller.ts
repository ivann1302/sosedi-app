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
import type { PrivateFileDownloadResponse } from '../upload/upload.types';
import { DisputeService } from './dispute.service';
import { AddDisputeEvidenceDto } from './dto/add-dispute-evidence.dto';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import {
  DisputeEvidenceResponseDto,
  DisputeResponseDto,
} from './dto/dispute-response.dto';

@ApiTags('disputes')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('bookings/:bookingId')
export class DisputeController {
  constructor(private readonly disputes: DisputeService) {}

  @Post('disputes')
  @ApiCreatedResponse({ type: DisputeResponseDto })
  async open(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Body() dto: CreateDisputeDto,
  ): Promise<ApiResponse<DisputeResponseDto>> {
    return ok(await this.disputes.openDispute(user.id, bookingId, dto));
  }

  @Get('dispute')
  @ApiOkResponse({ type: DisputeResponseDto })
  async get(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
  ): Promise<ApiResponse<DisputeResponseDto>> {
    return ok(await this.disputes.getDispute(user.id, bookingId));
  }

  @Post('disputes/:disputeId/evidence')
  @ApiCreatedResponse({ type: DisputeEvidenceResponseDto })
  async addEvidence(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Param('disputeId', ParseUUIDPipe) disputeId: string,
    @Body() dto: AddDisputeEvidenceDto,
  ): Promise<ApiResponse<DisputeEvidenceResponseDto>> {
    return ok(
      await this.disputes.addEvidence(user.id, bookingId, disputeId, dto),
    );
  }

  @Get('disputes/:disputeId/evidence/:evidenceId/download-url')
  async downloadEvidence(
    @CurrentUser() user: AuthUser,
    @Param('bookingId', ParseUUIDPipe) bookingId: string,
    @Param('disputeId', ParseUUIDPipe) disputeId: string,
    @Param('evidenceId', ParseUUIDPipe) evidenceId: string,
  ): Promise<ApiResponse<PrivateFileDownloadResponse>> {
    return ok(
      await this.disputes.getEvidenceDownloadUrl(
        user.id,
        bookingId,
        disputeId,
        evidenceId,
      ),
    );
  }
}
