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
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { ConfirmAvatarUploadDto } from './dto/confirm-avatar-upload.dto';
import { ConfirmItemPhotoUploadDto } from './dto/confirm-item-photo-upload.dto';
import { RequestUploadUrlDto } from './dto/request-upload-url.dto';
import {
  PresignedUploadResponse,
  AvatarUploadResponse,
  ItemPhotoUploadResponse,
  PrivateFileDownloadResponse,
} from './upload.types';
import { UploadService } from './upload.service';

@ApiTags('uploads')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('uploads')
export class UploadController {
  constructor(private readonly upload: UploadService) {}

  @Post('presigned-url')
  @ApiForbiddenResponse({
    description:
      'Purpose KYC_DOCUMENT запрещён до принятия LOCAL_KYC ADR; при PROVIDER_MANAGED endpoint для KYC не добавляется',
  })
  @ApiNotFoundResponse({
    description: 'Объявление не существует или не принадлежит actor',
  })
  async requestUploadUrl(
    @CurrentUser() user: AuthUser,
    @Body() dto: RequestUploadUrlDto,
  ): Promise<ApiResponse<PresignedUploadResponse>> {
    return ok(await this.upload.requestUploadUrl(user.id, dto));
  }

  @Post('item-photos/confirm')
  @ApiBadRequestResponse({
    description:
      'Intent истёк либо object отсутствует или не совпадает по bucket/key, размеру, MIME или magic bytes',
  })
  @ApiNotFoundResponse({
    description: 'Объявление не существует или не принадлежит actor',
  })
  async confirmItemPhotoUpload(
    @CurrentUser() user: AuthUser,
    @Body() dto: ConfirmItemPhotoUploadDto,
  ): Promise<ApiResponse<ItemPhotoUploadResponse>> {
    return ok(await this.upload.confirmItemPhotoUpload(user.id, dto));
  }

  @Post('avatars/confirm')
  @ApiBadRequestResponse({
    description:
      'Intent истёк либо object отсутствует или не совпадает по bucket/key, размеру, MIME или magic bytes',
  })
  async confirmAvatarUpload(
    @CurrentUser() user: AuthUser,
    @Body() dto: ConfirmAvatarUploadDto,
  ): Promise<ApiResponse<AvatarUploadResponse>> {
    return ok(await this.upload.confirmAvatarUpload(user.id, dto));
  }

  @Get(':intentId/download-url')
  @ApiNotFoundResponse({
    description:
      'Private-файл не существует, intent истёк или не принадлежит actor',
  })
  async getPrivateFileDownloadUrl(
    @CurrentUser() user: AuthUser,
    @Param('intentId', new ParseUUIDPipe()) intentId: string,
  ): Promise<ApiResponse<PrivateFileDownloadResponse>> {
    return ok(await this.upload.getPrivateFileDownloadUrl(user.id, intentId));
  }
}
