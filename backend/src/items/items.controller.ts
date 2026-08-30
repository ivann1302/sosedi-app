import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiExtraModels,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiParam,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { Request } from 'express';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { getRequestId } from '../common/http/request-id';
import { CreateItemDto } from './dto/create-item.dto';
import { ListItemsQueryDto } from './dto/list-items-query.dto';
import {
  FavoriteMutationResponseDto,
  PrivateItemResponseDto,
  PublicItemResponseDto,
} from './dto/item-response.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { ItemsService } from './items.service';

@ApiTags('items')
@ApiExtraModels(PublicItemResponseDto, PrivateItemResponseDto)
@Controller('items')
export class ItemsController {
  constructor(private readonly items: ItemsService) {}

  @ApiOkResponse({
    description: 'Публичные объявления без точного адреса и координат',
    schema: {
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: {
          type: 'array',
          items: { $ref: getSchemaPath(PublicItemResponseDto) },
        },
        error: { type: 'object', nullable: true, example: null },
      },
    },
  })
  @Get()
  async list(
    @Query() query: ListItemsQueryDto,
  ): Promise<ApiResponse<PublicItemResponseDto[]>> {
    return ok(await this.items.listPublic(query));
  }

  @ApiOkResponse({
    description: 'Районы из доступных публичных объявлений',
    schema: {
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: { type: 'array', items: { type: 'string' } },
        error: { type: 'object', nullable: true, example: null },
      },
    },
  })
  @Get('areas')
  async listAreas(): Promise<ApiResponse<string[]>> {
    return ok(await this.items.listPublicAreas());
  }

  @ApiOkResponse({ type: [PublicItemResponseDto] })
  @ApiBearerAuth()
  @Roles(UserRole.USER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Get('favorites')
  async listFavorites(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<PublicItemResponseDto[]>> {
    return ok(await this.items.listFavorites(user.id));
  }

  @ApiOkResponse({
    description:
      'Все собственные объявления actor, включая непубличные статусы',
    type: [PrivateItemResponseDto],
  })
  @ApiBearerAuth()
  @Roles(UserRole.USER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Get('mine')
  async listOwn(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<PrivateItemResponseDto[]>> {
    return ok(await this.items.listOwn(user.id));
  }

  @ApiOkResponse({
    description: 'Публичная карточка без точного адреса и координат',
    schema: {
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: { $ref: getSchemaPath(PublicItemResponseDto) },
        error: { type: 'object', nullable: true, example: null },
      },
    },
  })
  @ApiParam({ format: 'uuid', name: 'id' })
  @Get(':id')
  async get(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<PublicItemResponseDto>> {
    return ok(await this.items.getPublicById(id));
  }

  @ApiOkResponse({ type: FavoriteMutationResponseDto })
  @ApiBearerAuth()
  @Roles(UserRole.USER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Put(':id/favorite')
  async addFavorite(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<FavoriteMutationResponseDto>> {
    return ok(await this.items.addFavorite(user.id, id));
  }

  @ApiOkResponse({ type: FavoriteMutationResponseDto })
  @ApiBearerAuth()
  @Roles(UserRole.USER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Delete(':id/favorite')
  async removeFavorite(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<FavoriteMutationResponseDto>> {
    return ok(await this.items.removeFavorite(user.id, id));
  }

  @ApiCreatedResponse({
    description: 'Приватная карточка созданного объявления для владельца',
    schema: {
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: { $ref: getSchemaPath(PrivateItemResponseDto) },
        error: { type: 'object', nullable: true, example: null },
      },
    },
  })
  @ApiBearerAuth()
  @Roles(UserRole.USER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Post()
  async create(
    @CurrentUser() user: AuthUser,
    @Body() dto: CreateItemDto,
    @Req() request: Request,
  ): Promise<ApiResponse<PrivateItemResponseDto>> {
    return ok(await this.items.create(user.id, dto, getRequestId(request)));
  }

  @ApiOkResponse({
    description: 'Приватная карточка скрытого объявления для владельца',
    schema: {
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: { $ref: getSchemaPath(PrivateItemResponseDto) },
        error: { type: 'object', nullable: true, example: null },
      },
    },
  })
  @ApiParam({ format: 'uuid', name: 'id' })
  @ApiNotFoundResponse({
    description: 'Объявление не существует или не принадлежит actor',
  })
  @ApiBearerAuth()
  @Roles(UserRole.USER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Patch(':id/hide')
  async hide(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<PrivateItemResponseDto>> {
    return ok(await this.items.hideOwn(user.id, id));
  }

  @ApiOkResponse({
    description: 'Приватная карточка обновлённого объявления для владельца',
    schema: {
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: { $ref: getSchemaPath(PrivateItemResponseDto) },
        error: { type: 'object', nullable: true, example: null },
      },
    },
  })
  @ApiParam({ format: 'uuid', name: 'id' })
  @ApiNotFoundResponse({
    description: 'Объявление не существует или не принадлежит actor',
  })
  @ApiBearerAuth()
  @Roles(UserRole.USER)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Patch(':id')
  async update(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateItemDto,
  ): Promise<ApiResponse<PrivateItemResponseDto>> {
    return ok(await this.items.updateOwn(user.id, id, dto));
  }
}
