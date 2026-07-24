import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
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

  @ApiBearerAuth()
  @Roles(UserRole.ADMIN)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Post()
  async create(
    @Body() dto: CreateCategoryDto,
  ): Promise<ApiResponse<CategoryResponse>> {
    return ok(await this.categories.create(dto));
  }

  @ApiBearerAuth()
  @Roles(UserRole.ADMIN)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Patch(':id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCategoryDto,
  ): Promise<ApiResponse<CategoryResponse>> {
    return ok(await this.categories.update(id, dto));
  }

  @ApiBearerAuth()
  @Roles(UserRole.ADMIN)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Patch(':id/disable')
  async disable(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<CategoryResponse>> {
    return ok(await this.categories.disable(id));
  }
}
