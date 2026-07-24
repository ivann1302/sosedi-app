import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ok } from '../common/http/api-response';
import type { ApiResponse } from '../common/http/api-response';
import type { AuthUser } from './auth.types';
import {
  AuthService,
  type AuthTokensResponse,
  type AuthUserResponse,
  type LogoutResponse,
  type OtpRequestResponse,
} from './auth.service';
import { CurrentUser } from './decorators/current-user.decorator';
import { LogoutDto } from './dto/logout.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('otp/request')
  async requestOtp(
    @Body() dto: RequestOtpDto,
  ): Promise<ApiResponse<OtpRequestResponse>> {
    return ok(await this.auth.requestOtp(dto.phone));
  }

  @Post('otp/verify')
  async verifyOtp(
    @Body() dto: VerifyOtpDto,
  ): Promise<ApiResponse<AuthTokensResponse>> {
    return ok(await this.auth.verifyOtp(dto.phone, dto.code));
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
}
