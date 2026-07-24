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
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { AuthenticatedRequest, AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import {
  AdminService,
  type AdminToolResponse,
  type AdminUserResponse,
} from './admin.service';
import { RejectToolDto } from './dto/reject-tool.dto';

@ApiTags('admin')
@ApiBearerAuth()
@Roles(UserRole.ADMIN)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @ApiOperation({ summary: 'Список пользователей для администратора' })
  @Get('users')
  async listUsers(): Promise<ApiResponse<AdminUserResponse[]>> {
    return ok(await this.admin.listUsers());
  }

  @ApiOperation({ summary: 'Карточка пользователя для администратора' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @Get('users/:id')
  async getUser(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<AdminUserResponse>> {
    return ok(await this.admin.getUser(id));
  }

  @ApiOperation({ summary: 'Объявления на модерации' })
  @Get('tools/pending')
  async listPendingTools(): Promise<ApiResponse<AdminToolResponse[]>> {
    return ok(await this.admin.listPendingTools());
  }

  @ApiOperation({ summary: 'Одобрить объявление' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @Patch('tools/:id/approve')
  async approveTool(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<AdminToolResponse>> {
    return ok(await this.admin.approveTool(user.id, id, request.ip));
  }

  @ApiOperation({ summary: 'Отклонить объявление с причиной' })
  @ApiParam({ name: 'id', format: 'uuid' })
  @Patch('tools/:id/reject')
  async rejectTool(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RejectToolDto,
  ): Promise<ApiResponse<AdminToolResponse>> {
    return ok(await this.admin.rejectTool(user.id, id, dto, request.ip));
  }
}
