import {
  Body,
  Controller,
  Delete,
  Get,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiCookieAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { Response } from 'express';
import type { AuthenticatedRequest, AuthUser } from '../auth/auth.types';
import type { AdminAuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ok, type ApiResponse } from '../common/http/api-response';
import { getAdminAuditContext } from './admin-audit-context';
import { AdminSessionGuard } from './admin-session.guard';
import {
  AdminMfaService,
  type TotpConfirmResponse,
  type TotpSetupResponse,
} from './admin-mfa.service';
import {
  ADMIN_CSRF_COOKIE,
  ADMIN_SESSION_COOKIE,
  AdminSessionService,
} from './admin-session.service';
import { AdminStepUpDto } from './dto/admin-step-up.dto';
import { ConfirmAdminTotpDto } from './dto/confirm-admin-totp.dto';

@ApiTags('admin-session')
@Controller('admin/session')
export class AdminSessionController {
  constructor(
    private readonly sessions: AdminSessionService,
    private readonly mfa: AdminMfaService,
  ) {}

  @Roles(UserRole.ADMIN)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiBearerAuth()
  @Post('totp/setup')
  async setupTotp(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
  ): Promise<ApiResponse<TotpSetupResponse>> {
    return ok(
      await this.mfa.beginTotpSetup(
        user.id,
        user.phone,
        getAdminAuditContext(request),
      ),
    );
  }

  @Roles(UserRole.ADMIN)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiBearerAuth()
  @Post('totp/confirm')
  async confirmTotp(
    @CurrentUser() user: AuthUser,
    @Req() request: AuthenticatedRequest,
    @Body() dto: ConfirmAdminTotpDto,
  ): Promise<ApiResponse<TotpConfirmResponse>> {
    return ok(
      await this.mfa.confirmTotpSetup(
        user.id,
        dto.code,
        getAdminAuditContext(request),
      ),
    );
  }

  @Roles(UserRole.ADMIN)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @ApiBearerAuth()
  @Post('step-up')
  async stepUp(
    @CurrentUser() user: AuthUser,
    @Body() dto: AdminStepUpDto,
    @Req() request: AuthenticatedRequest,
    @Res({ passthrough: true }) response: Response,
  ): Promise<ApiResponse<{ expiresInSeconds: number }>> {
    const session = await this.sessions.stepUp(
      user.id,
      dto.code,
      getAdminAuditContext(request),
    );
    const cookieOptions = {
      secure: true,
      sameSite: 'strict' as const,
      path: '/',
      maxAge: session.expiresInSeconds * 1000,
    };
    response.cookie(ADMIN_SESSION_COOKIE, session.sessionId, {
      ...cookieOptions,
      httpOnly: true,
    });
    response.cookie(ADMIN_CSRF_COOKIE, session.csrfToken, {
      ...cookieOptions,
      httpOnly: false,
    });
    return ok({ expiresInSeconds: session.expiresInSeconds });
  }

  @UseGuards(AdminSessionGuard)
  @ApiCookieAuth(ADMIN_SESSION_COOKIE)
  @Get()
  async current(
    @CurrentUser() user: AdminAuthUser,
    @Req() request: AuthenticatedRequest,
  ): Promise<
    ApiResponse<{
      userId: string;
      capabilities: string[];
      expiresInSeconds: number;
    }>
  > {
    if (!request.adminSessionId) {
      throw new Error('Admin session id was not set by guard');
    }
    return ok({
      userId: user.id,
      capabilities: user.adminCapabilities,
      expiresInSeconds: await this.sessions.remainingSeconds(
        request.adminSessionId,
      ),
    });
  }

  @UseGuards(AdminSessionGuard)
  @ApiCookieAuth(ADMIN_SESSION_COOKIE)
  @Delete()
  async revoke(
    @CurrentUser() user: AdminAuthUser,
    @Req() request: AuthenticatedRequest,
    @Res({ passthrough: true }) response: Response,
  ): Promise<ApiResponse<{ revoked: true }>> {
    if (!request.adminSessionId) {
      throw new Error('Admin session id was not set by guard');
    }
    response.clearCookie(ADMIN_SESSION_COOKIE, {
      secure: true,
      httpOnly: true,
      sameSite: 'strict',
      path: '/',
    });
    response.clearCookie(ADMIN_CSRF_COOKIE, {
      secure: true,
      httpOnly: false,
      sameSite: 'strict',
      path: '/',
    });
    return ok(
      await this.sessions.revoke(
        request.adminSessionId,
        user.id,
        getAdminAuditContext(request),
      ),
    );
  }
}
