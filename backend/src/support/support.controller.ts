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
import { UploadService } from '../upload/upload.service';
import type { PrivateFileDownloadResponse } from '../upload/upload.types';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { SupportMessageResponseDto } from './dto/support-message-response.dto';
import { SupportTicketResponseDto } from './dto/support-ticket-response.dto';
import { SupportService } from './support.service';

@ApiTags('support')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('support/tickets')
export class SupportController {
  constructor(
    private readonly support: SupportService,
    private readonly upload: UploadService,
  ) {}

  @ApiCreatedResponse({ type: SupportTicketResponseDto })
  @Post()
  async create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateSupportTicketDto,
  ): Promise<ApiResponse<SupportTicketResponseDto>> {
    return ok(await this.support.create(user.id, dto));
  }

  @ApiOkResponse({ type: [SupportTicketResponseDto] })
  @Get()
  async listMine(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<SupportTicketResponseDto[]>> {
    return ok(await this.support.listMine(user.id));
  }

  @ApiOkResponse({ type: [SupportMessageResponseDto] })
  @Get(':id/messages')
  async listMessages(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<SupportMessageResponseDto[]>> {
    return ok(await this.support.listMessages(user.id, id, false));
  }

  @ApiCreatedResponse({ type: SupportMessageResponseDto })
  @Post(':id/messages')
  async createMessage(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CreateSupportMessageDto,
  ): Promise<ApiResponse<SupportMessageResponseDto>> {
    return ok(await this.support.createMessage(user.id, id, dto, false));
  }

  @ApiOkResponse({ description: 'Короткая private download URL' })
  @Get(':id/attachments/:attachmentId/download-url')
  async getAttachmentDownloadUrl(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('attachmentId', ParseUUIDPipe) attachmentId: string,
  ): Promise<ApiResponse<PrivateFileDownloadResponse>> {
    return ok(
      await this.upload.getSupportAttachmentDownloadUrl(
        user.id,
        id,
        attachmentId,
        false,
      ),
    );
  }
}
