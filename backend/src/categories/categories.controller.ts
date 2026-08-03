import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiCookieAuth, ApiTags } from '@nestjs/swagger';
import { AdminCapability } from '@prisma/client';
import { AdminCapabilities } from '../admin/admin-capabilities.decorator';
import { getAdminAuditContext } from '../admin/admin-audit-context';
import { AdminSessionGuard } from '../admin/admin-session.guard';
import { ADMIN_SESSION_COOKIE } from '../admin/admin-session.service';
import type { AuthenticatedRequest, AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ok, type ApiResponse } from '../common/http/api-response';
import { CategoriesService, type CategoryResponse } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@ApiTags('categories')
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categories: CategoriesService) {}

  @Get()
  async list(): Promise<ApiResponse<CategoryResponse[]>> {
    return ok(await this.categories.listActive());
  }

  @Get(':slug')
  async getBySlug(
    @Param('slug') slug: string,
  ): Promise<ApiResponse<CategoryResponse>> {
    return ok(await this.categories.getBySlug(slug));
  }

  @ApiCookieAuth(ADMIN_SESSION_COOKIE)
  @AdminCapabilities(AdminCapability.MODERATION)
  @UseGuards(AdminSessionGuard)
  @Post()
  async create(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateCategoryDto,
  ): Promise<ApiResponse<CategoryResponse>> {
    return ok(
      await this.categories.create(user.id, dto, getAdminAuditContext(request)),
    );
  }

  @ApiCookieAuth(ADMIN_SESSION_COOKIE)
  @AdminCapabilities(AdminCapability.MODERATION)
  @UseGuards(AdminSessionGuard)
  @Patch(':id')
  async update(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCategoryDto,
  ): Promise<ApiResponse<CategoryResponse>> {
    return ok(
      await this.categories.update(
        user.id,
        id,
        dto,
        getAdminAuditContext(request),
      ),
    );
  }

  @ApiCookieAuth(ADMIN_SESSION_COOKIE)
  @AdminCapabilities(AdminCapability.MODERATION)
  @UseGuards(AdminSessionGuard)
  @Patch(':id/disable')
  async disable(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<CategoryResponse>> {
    return ok(
      await this.categories.disable(user.id, id, getAdminAuditContext(request)),
    );
  }
}
