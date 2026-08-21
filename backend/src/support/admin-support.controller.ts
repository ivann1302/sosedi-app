import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiCookieAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AdminCapability } from '@prisma/client';
import { AdminCapabilities } from '../admin/admin-capabilities.decorator';
import { getAdminAuditContext } from '../admin/admin-audit-context';
import { AdminSessionGuard } from '../admin/admin-session.guard';
import { ADMIN_SESSION_COOKIE } from '../admin/admin-session.service';
import type { AuthenticatedRequest, AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ok, type ApiResponse } from '../common/http/api-response';
import { UploadService } from '../upload/upload.service';
import {
  type PresignedUploadResponse,
  type PrivateFileDownloadResponse,
  UploadPurpose,
} from '../upload/upload.types';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { ReplySupportTicketDto } from './dto/reply-support-ticket.dto';
import { RequestSupportAttachmentUploadDto } from './dto/request-support-attachment-upload.dto';
import { SupportMessageResponseDto } from './dto/support-message-response.dto';
import { SupportTicketResponseDto } from './dto/support-ticket-response.dto';
import {
  type AdminBookingChatMessageResponse,
  SupportService,
  type AdminSupportTicketResponse,
} from './support.service';

@ApiTags('admin-support')
@ApiCookieAuth(ADMIN_SESSION_COOKIE)
@AdminCapabilities(AdminCapability.SUPPORT)
@UseGuards(AdminSessionGuard)
@Controller('admin/support/tickets')
export class AdminSupportController {
  constructor(
    private readonly support: SupportService,
    private readonly upload: UploadService,
  ) {}

  @ApiOkResponse({ type: [SupportTicketResponseDto] })
  @Get()
  async list(): Promise<ApiResponse<AdminSupportTicketResponse[]>> {
    return ok(await this.support.listForAdmin());
  }

  @ApiOkResponse({ description: 'Аудируемый booking-chat обращения' })
  @Get(':id/booking-chat')
  async listBookingChat(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<AdminBookingChatMessageResponse[]>> {
    return ok(
      await this.support.listBookingChatForAdmin(
        user.id,
        id,
        getAdminAuditContext(request),
      ),
    );
  }

  @ApiOkResponse({ type: [SupportMessageResponseDto] })
  @Get(':id/messages')
  async listMessages(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<SupportMessageResponseDto[]>> {
    return ok(await this.support.listMessages(user.id, id, true));
  }

  @ApiCreatedResponse({ type: SupportMessageResponseDto })
  @Post(':id/messages')
  async createMessage(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateSupportMessageDto,
  ): Promise<ApiResponse<SupportMessageResponseDto>> {
    return ok(
      await this.support.createMessage(
        user.id,
        id,
        dto,
        true,
        getAdminAuditContext(request),
      ),
    );
  }

  @ApiCreatedResponse({ description: 'Private support upload intent' })
  @Post(':id/attachments/presigned-url')
  async requestAttachmentUpload(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RequestSupportAttachmentUploadDto,
  ): Promise<ApiResponse<PresignedUploadResponse>> {
    return ok(
      await this.upload.requestAdminSupportAttachmentUploadUrl(user.id, {
        ...dto,
        purpose: UploadPurpose.SUPPORT_ATTACHMENT,
        supportTicketId: id,
      }),
    );
  }

  @ApiOkResponse({ description: 'Короткая private download URL' })
  @Get(':id/attachments/:attachmentId/download-url')
  async getAttachmentDownloadUrl(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('attachmentId', ParseUUIDPipe) attachmentId: string,
  ): Promise<ApiResponse<PrivateFileDownloadResponse>> {
    return ok(
      await this.upload.getSupportAttachmentDownloadUrl(
        user.id,
        id,
        attachmentId,
        true,
        getAdminAuditContext(request),
      ),
    );
  }

  @ApiOkResponse({ type: SupportTicketResponseDto })
  @Patch(':id/assign-self')
  async assignSelf(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<AdminSupportTicketResponse>> {
    return ok(
      await this.support.assignToSelf(
        user.id,
        id,
        getAdminAuditContext(request),
      ),
    );
  }

  @ApiOkResponse({ type: SupportTicketResponseDto })
  @Patch(':id/reply')
  async reply(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReplySupportTicketDto,
  ): Promise<ApiResponse<AdminSupportTicketResponse>> {
    return ok(
      await this.support.replyAsAdmin(
        user.id,
        id,
        dto,
        getAdminAuditContext(request),
      ),
    );
  }

  @ApiOkResponse({ type: SupportTicketResponseDto })
  @Patch(':id/close')
  async close(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<AdminSupportTicketResponse>> {
    return ok(
      await this.support.closeAsAdmin(
        user.id,
        id,
        getAdminAuditContext(request),
      ),
    );
  }
}
