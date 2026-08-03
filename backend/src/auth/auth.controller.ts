import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { ok } from '../common/http/api-response';
import type { ApiResponse } from '../common/http/api-response';
import { getClientIp } from '../common/http/client-ip';
import type { AuthUser } from './auth.types';
import {
  AuthService,
  type AuthTokensResponse,
  type AuthUserResponse,
  type LogoutResponse,
  type OtpRequestResponse,
  type UserStepUpResponse,
  type UserSessionResponse,
} from './auth.service';
import { CurrentUser } from './decorators/current-user.decorator';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { VerifyUserStepUpOtpDto } from './dto/verify-user-step-up-otp.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

const UUID_V4_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('otp/request')
  @ApiHeader({
    name: 'X-Installation-Id',
    description: 'Стабильный UUID v4 установки приложения',
    required: true,
  })
  async requestOtp(
    @Body() dto: RequestOtpDto,
    @Req() request: Request,
  ): Promise<ApiResponse<OtpRequestResponse>> {
    const installationId = this.parseInstallationId(
      request.headers['x-installation-id'],
    );
    return ok(
      await this.auth.requestOtp(dto.phone, {
        installationId,
        ipAddress: getClientIp(request),
      }),
    );
  }

  private parseInstallationId(value: string | string[] | undefined): string {
    if (typeof value !== 'string' || !UUID_V4_PATTERN.test(value)) {
      throw new BadRequestException(
        'X-Installation-Id должен быть UUID v4 установки приложения',
      );
    }
    return value.toLowerCase();
  }

  @Post('otp/verify')
  async verifyOtp(
    @Body() dto: VerifyOtpDto,
    @Req() request: Request,
  ): Promise<ApiResponse<AuthTokensResponse>> {
    return ok(
      await this.auth.verifyOtp(
        dto.phone,
        dto.code,
        this.parseInstallationId(request.headers['x-installation-id']),
      ),
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('step-up/data-export/otp/request')
  async requestDataExportStepUp(
    @CurrentUser() user: AuthUser,
    @Req() request: Request,
  ): Promise<ApiResponse<OtpRequestResponse>> {
    return ok(
      await this.auth.requestUserStepUpOtp(user.phone, {
        installationId: this.parseInstallationId(
          request.headers['x-installation-id'],
        ),
        ipAddress: getClientIp(request),
      }),
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('step-up/data-export/otp/verify')
  async verifyDataExportStepUp(
    @CurrentUser() user: AuthUser,
    @Body() dto: VerifyUserStepUpOtpDto,
  ): Promise<ApiResponse<UserStepUpResponse>> {
    return ok(
      await this.auth.verifyUserStepUpOtp(
        user.id,
        user.phone,
        dto.code,
        'DATA_EXPORT',
      ),
    );
  }

  @Post('refresh')
  async refresh(
    @Body() dto: RefreshTokenDto,
  ): Promise<ApiResponse<AuthTokensResponse>> {
    return ok(await this.auth.refresh(dto.refreshToken));
  }

  @Post('logout')
  async logout(@Body() dto: LogoutDto): Promise<ApiResponse<LogoutResponse>> {
    return ok(await this.auth.logout(dto.refreshToken));
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async me(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<AuthUserResponse>> {
    return ok(await this.auth.getMe(user.id));
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('sessions')
  async sessions(
    @CurrentUser() user: AuthUser,
    @Req() request: Request,
  ): Promise<ApiResponse<UserSessionResponse[]>> {
    return ok(
      await this.auth.listSessions(
        user.id,
        this.parseInstallationId(request.headers['x-installation-id']),
      ),
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete('sessions/:sessionId')
  async revokeSession(
    @CurrentUser() user: AuthUser,
    @Param('sessionId', new ParseUUIDPipe()) sessionId: string,
  ): Promise<ApiResponse<LogoutResponse>> {
    return ok(await this.auth.revokeSession(user.id, sessionId));
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete('sessions')
  async revokeAllSessions(
    @CurrentUser() user: AuthUser,
  ): Promise<ApiResponse<LogoutResponse>> {
    return ok(await this.auth.revokeAllSessions(user.id));
  }
}
