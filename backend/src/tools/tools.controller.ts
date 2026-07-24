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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { CreateToolDto } from './dto/create-tool.dto';
import { ListToolsQueryDto } from './dto/list-tools-query.dto';
import { UpdateToolDto } from './dto/update-tool.dto';
import { ToolsService, type ToolResponse } from './tools.service';

@ApiTags('tools')
@Controller('tools')
export class ToolsController {
  constructor(private readonly tools: ToolsService) {}

  @Get()
  async list(
    @Query() query: ListToolsQueryDto,
  ): Promise<ApiResponse<ToolResponse[]>> {
    return ok(await this.tools.listPublic(query));
  }

  @Get(':id')
  async get(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<ToolResponse>> {
    return ok(await this.tools.getPublicById(id));
  }

  @ApiBearerAuth()
  @Roles(UserRole.RENTER, UserRole.OWNER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Post()
  async create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateToolDto,
  ): Promise<ApiResponse<ToolResponse>> {
    return ok(await this.tools.create(user.id, dto));
  }

  @ApiBearerAuth()
  @Roles(UserRole.OWNER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Patch(':id/hide')
  async hide(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<ToolResponse>> {
    return ok(await this.tools.hideOwn(user.id, id));
  }

  @ApiBearerAuth()
  @Roles(UserRole.OWNER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Patch(':id')
  async update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateToolDto,
  ): Promise<ApiResponse<ToolResponse>> {
    return ok(await this.tools.updateOwn(user.id, id, dto));
  }
}
