import {
  Body,
  Controller,
  Delete,
  Headers,
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
import {
  DeleteDeviceTokenResponse,
  DeviceTokensService,
} from './device-tokens.service';
import { DeviceTokenResponseDto } from './dto/device-token-response.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@ApiTags('device-tokens')
@ApiBearerAuth()
@Roles(UserRole.USER)
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('device-tokens')
export class DeviceTokensController {
  constructor(private readonly tokens: DeviceTokensService) {}

  @ApiCreatedResponse({ type: DeviceTokenResponseDto })
  @Post()
  async register(
    @CurrentUser() user: AuthUser,
    @Headers('x-installation-id') installationId: string,
    @Body() dto: RegisterDeviceTokenDto,
  ): Promise<ApiResponse<DeviceTokenResponseDto>> {
    return ok(await this.tokens.register(user.id, installationId, dto));
  }

  @ApiOkResponse({ description: 'Идемпотентное удаление self-bound token' })
  @Delete(':id')
  async remove(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ApiResponse<DeleteDeviceTokenResponse>> {
    return ok(await this.tokens.remove(user.id, id));
  }
}
