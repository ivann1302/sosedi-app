import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { ConfirmToolPhotoUploadDto } from './dto/confirm-tool-photo-upload.dto';
import { RequestUploadUrlDto } from './dto/request-upload-url.dto';
import {
  PresignedUploadResponse,
  ToolPhotoUploadResponse,
} from './upload.types';
import { UploadService } from './upload.service';

@ApiTags('uploads')
@ApiBearerAuth()
@Roles(UserRole.RENTER, UserRole.OWNER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('uploads')
export class UploadController {
  constructor(private readonly upload: UploadService) {}

  @Post('presigned-url')
  async requestUploadUrl(
    @CurrentUser() user: AuthUser,
    @Body() dto: RequestUploadUrlDto,
  ): Promise<ApiResponse<PresignedUploadResponse>> {
    return ok(await this.upload.requestUploadUrl(user.id, dto));
  }

  @Post('tool-photos/confirm')
  async confirmToolPhotoUpload(
    @CurrentUser() user: AuthUser,
    @Body() dto: ConfirmToolPhotoUploadDto,
  ): Promise<ApiResponse<ToolPhotoUploadResponse>> {
    return ok(await this.upload.confirmToolPhotoUpload(user.id, dto));
  }
}
