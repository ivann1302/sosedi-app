import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiConflictResponse,
  ApiCookieAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { AdminCapability } from '@prisma/client';
import type { AuthenticatedRequest, AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ok, type ApiResponse } from '../common/http/api-response';
import { AdminCapabilities } from './admin-capabilities.decorator';
import { getAdminAuditContext } from './admin-audit-context';
import { AdminSessionGuard } from './admin-session.guard';
import { ADMIN_SESSION_COOKIE } from './admin-session.service';
import {
  AdminService,
  type AdminItemResponse,
  type AdminUserResponse,
} from './admin.service';
import { BlockUserDto } from './dto/block-user.dto';
import { RejectItemDto } from './dto/reject-item.dto';

@ApiTags('admin')
@ApiCookieAuth(ADMIN_SESSION_COOKIE)
@UseGuards(AdminSessionGuard)
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @ApiOperation({ summary: 'Список пользователей для администратора' })
  @AdminCapabilities(AdminCapability.MODERATION)
  @Get('users')
  async listUsers(): Promise<ApiResponse<AdminUserResponse[]>> {
    return ok(await this.admin.listUsers());
  }

  @ApiOperation({ summary: 'Карточка пользователя для администратора' })
  @AdminCapabilities(AdminCapability.MODERATION)
  @ApiParam({ name: 'id', format: 'uuid' })
  @Get('users/:id')
  async getUser(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<AdminUserResponse>> {
    return ok(await this.admin.getUser(id));
  }

  @ApiOperation({ summary: 'Заблокировать пользователя и отозвать его сессии' })
  @AdminCapabilities(AdminCapability.MODERATION)
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiConflictResponse({
    description:
      'Пользователь уже заблокирован или администратор блокирует себя',
  })
  @Patch('users/:id/block')
  async blockUser(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: BlockUserDto,
  ): Promise<ApiResponse<AdminUserResponse>> {
    return ok(
      await this.admin.blockUser(
        user.id,
        id,
        dto,
        getAdminAuditContext(request),
      ),
    );
  }

  @ApiOperation({ summary: 'Объявления на модерации' })
  @AdminCapabilities(AdminCapability.MODERATION)
  @Get('items/pending')
  async listPendingItems(): Promise<ApiResponse<AdminItemResponse[]>> {
    return ok(await this.admin.listPendingItems());
  }

  @ApiOperation({ summary: 'Одобрить объявление' })
  @AdminCapabilities(AdminCapability.MODERATION)
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiConflictResponse({
    description: 'Объявление не находится в статусе PENDING',
  })
  @Patch('items/:id/approve')
  async approveItem(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<AdminItemResponse>> {
    return ok(
      await this.admin.approveItem(user.id, id, getAdminAuditContext(request)),
    );
  }

  @ApiOperation({ summary: 'Отклонить объявление с причиной' })
  @AdminCapabilities(AdminCapability.MODERATION)
  @ApiParam({ name: 'id', format: 'uuid' })
  @ApiConflictResponse({
    description: 'Объявление не находится в статусе PENDING',
  })
  @Patch('items/:id/reject')
  async rejectItem(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectItemDto,
  ): Promise<ApiResponse<AdminItemResponse>> {
    return ok(
      await this.admin.rejectItem(
        user.id,
        id,
        dto,
        getAdminAuditContext(request),
      ),
    );
  }
}
