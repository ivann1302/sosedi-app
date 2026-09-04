import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiCreatedResponse,
  ApiCookieAuth,
  ApiExtraModels,
  ApiHeader,
  ApiOkResponse,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { AdminCapability } from '@prisma/client';
import { AdminCapabilities } from '../admin/admin-capabilities.decorator';
import { AdminAnyCapability } from '../admin/admin-any-capability.decorator';
import { getAdminAuditContext } from '../admin/admin-audit-context';
import { AdminSessionGuard } from '../admin/admin-session.guard';
import { ADMIN_SESSION_COOKIE } from '../admin/admin-session.service';
import type { AuthenticatedRequest, AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ok, type ApiResponse } from '../common/http/api-response';
import { DepositService } from './deposit.service';
import { DisputeService } from './dispute.service';
import { AdminDisputeResponseDto } from './dto/admin-dispute-response.dto';
import { DepositOperationCommandResponseDto } from './dto/deposit-operation-command-response.dto';
import {
  DisputeEvidenceDownloadResponseDto,
  DisputeResponseDto,
} from './dto/dispute-response.dto';
import { ResolveDisputeDto } from './dto/resolve-dispute.dto';

const disputeListEnvelopeSchema = {
  type: 'object',
  required: ['success', 'data', 'error'],
  properties: {
    success: { type: 'boolean', example: true },
    data: {
      type: 'array',
      items: { $ref: getSchemaPath(AdminDisputeResponseDto) },
    },
    error: { type: 'object', nullable: true, example: null },
  },
};

const disputeEnvelopeSchema = {
  type: 'object',
  required: ['success', 'data', 'error'],
  properties: {
    success: { type: 'boolean', example: true },
    data: { $ref: getSchemaPath(DisputeResponseDto) },
    error: { type: 'object', nullable: true, example: null },
  },
};

const evidenceDownloadEnvelopeSchema = {
  type: 'object',
  required: ['success', 'data', 'error'],
  properties: {
    success: { type: 'boolean', example: true },
    data: { $ref: getSchemaPath(DisputeEvidenceDownloadResponseDto) },
    error: { type: 'object', nullable: true, example: null },
  },
};

const depositOperationEnvelopeSchema = {
  type: 'object',
  required: ['success', 'data', 'error'],
  properties: {
    success: { type: 'boolean', example: true },
    data: { $ref: getSchemaPath(DepositOperationCommandResponseDto) },
    error: { type: 'object', nullable: true, example: null },
  },
};

@ApiTags('admin-disputes')
@ApiCookieAuth(ADMIN_SESSION_COOKIE)
@ApiExtraModels(
  AdminDisputeResponseDto,
  DisputeResponseDto,
  DisputeEvidenceDownloadResponseDto,
  DepositOperationCommandResponseDto,
)
@UseGuards(AdminSessionGuard)
@Controller('admin')
export class AdminDisputeController {
  constructor(
    private readonly disputes: DisputeService,
    private readonly deposits: DepositService,
  ) {}

  @AdminAnyCapability(AdminCapability.SUPPORT, AdminCapability.DISPUTE)
  @ApiOkResponse({ schema: disputeListEnvelopeSchema })
  @Get('disputes')
  async list(): Promise<ApiResponse<AdminDisputeResponseDto[]>> {
    return ok(await this.disputes.listForAdmin());
  }

  @AdminAnyCapability(AdminCapability.SUPPORT, AdminCapability.DISPUTE)
  @ApiOkResponse({ schema: evidenceDownloadEnvelopeSchema })
  @Get('disputes/:id/evidence/:evidenceId/download-url')
  async downloadEvidence(
    @Param('id', ParseUUIDPipe) disputeId: string,
    @Param('evidenceId', ParseUUIDPipe) evidenceId: string,
  ): Promise<ApiResponse<DisputeEvidenceDownloadResponseDto>> {
    return ok(
      await this.disputes.getEvidenceDownloadUrlForAdmin(disputeId, evidenceId),
    );
  }

  @AdminCapabilities(AdminCapability.DISPUTE, AdminCapability.FINANCE)
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiCreatedResponse({ schema: disputeEnvelopeSchema })
  @Post('disputes/:id/resolve')
  async resolve(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) disputeId: string,
    @Body() dto: ResolveDisputeDto,
    @Headers('idempotency-key') idempotencyKey?: string,
  ): Promise<ApiResponse<DisputeResponseDto>> {
    return ok(
      await this.disputes.resolveDispute(
        user.id,
        disputeId,
        dto,
        idempotencyKey ?? '',
        getAdminAuditContext(request),
      ),
    );
  }

  @AdminCapabilities(AdminCapability.DISPUTE, AdminCapability.FINANCE)
  @ApiHeader({ name: 'Idempotency-Key', required: true })
  @ApiCreatedResponse({ schema: depositOperationEnvelopeSchema })
  @Post('deposit-operations/:id/retry')
  async retry(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) operationId: string,
    @Headers('idempotency-key') idempotencyKey?: string,
  ): Promise<ApiResponse<DepositOperationCommandResponseDto>> {
    return ok(
      await this.deposits.retryFailedOperation(
        user.id,
        operationId,
        idempotencyKey ?? '',
        getAdminAuditContext(request),
      ),
    );
  }
}
