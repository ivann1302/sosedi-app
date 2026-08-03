import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminCapability } from '@prisma/client';
import { AuthenticatedRequest } from '../auth/auth.types';
import { ADMIN_CAPABILITIES_KEY } from './admin-capabilities.decorator';
import {
  ADMIN_SESSION_COOKIE,
  AdminSessionService,
} from './admin-session.service';

@Injectable()
export class AdminSessionGuard implements CanActivate {
  constructor(
    private readonly sessions: AdminSessionService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const sessionId = this.getSessionId(request.headers.cookie);
    const csrfToken = this.getCsrfToken(request);
    const session = await this.sessions.authenticate(sessionId, csrfToken);
    const required = this.reflector.getAllAndOverride<AdminCapability[]>(
      ADMIN_CAPABILITIES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (
      required?.some(
        (capability) => !session.user.adminCapabilities.includes(capability),
      )
    ) {
      throw new ForbiddenException('Недостаточно административных полномочий');
    }

    request.user = session.user;
    request.adminSessionId = session.sessionId;
    return true;
  }

  private getSessionId(cookieHeader?: string): string {
    const sessionId = this.getCookie(cookieHeader, ADMIN_SESSION_COOKIE);
    if (!sessionId) {
      throw new UnauthorizedException('Требуется admin-сессия');
    }
    return sessionId;
  }

  private getCsrfToken(request: AuthenticatedRequest): string | undefined {
    if (['GET', 'HEAD', 'OPTIONS'].includes(request.method.toUpperCase())) {
      return undefined;
    }

    const value = request.headers['x-csrf-token'];
    if (typeof value !== 'string' || value.length === 0) {
      throw new ForbiddenException('Требуется CSRF token');
    }
    return value;
  }

  private getCookie(header: string | undefined, name: string): string | null {
    for (const part of header?.split(';') ?? []) {
      const separator = part.indexOf('=');
      if (separator < 0 || part.slice(0, separator).trim() !== name) {
        continue;
      }
      return part.slice(separator + 1).trim() || null;
    }
    return null;
  }
}
