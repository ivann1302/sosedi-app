import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedRequest, JwtAccessPayload } from '../auth.types';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.getBearerToken(request.headers.authorization);
    const secret = this.config.get<string>('JWT_ACCESS_SECRET');

    if (!secret) {
      throw new InternalServerErrorException('Не настроен JWT access secret');
    }

    let payload: JwtAccessPayload;
    try {
      payload = await this.jwt.verifyAsync<JwtAccessPayload>(token, { secret });
    } catch {
      throw new UnauthorizedException('Недействительный access токен');
    }

    if (payload.tokenType !== 'access') {
      throw new UnauthorizedException('Недействительный access токен');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        phone: true,
        role: true,
        isBlocked: true,
        deletedAt: true,
      },
    });

    if (!user || user.deletedAt) {
      throw new UnauthorizedException('Пользователь не найден');
    }

    if (user.isBlocked) {
      throw new ForbiddenException('Пользователь заблокирован');
    }

    request.user = {
      id: user.id,
      phone: user.phone,
      role: user.role,
    };

    return true;
  }

  private getBearerToken(header?: string): string {
    if (!header?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Требуется авторизация');
    }

    return header.slice('Bearer '.length).trim();
  }
}
