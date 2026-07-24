import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { KycStatus, User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import type Redis from 'ioredis';
import { randomInt, randomUUID } from 'node:crypto';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { JwtRefreshPayload } from './auth.types';
import { normalizeRussianPhone, parseDurationToSeconds } from './auth.util';
import { SmsService } from './sms.service';

const OTP_TTL_SECONDS = 5 * 60;
const OTP_RATE_LIMIT = 3;
const OTP_RATE_WINDOW_SECONDS = 10 * 60;
const OTP_FAIL_LIMIT = 5;
const OTP_BLOCK_SECONDS = 30 * 60;

type AuthUserModel = Pick<
  User,
  'id' | 'phone' | 'name' | 'role' | 'kycStatus' | 'isBlocked' | 'deletedAt'
>;

export type AuthUserResponse = {
  id: string;
  phone: string;
  name: string | null;
  role: UserRole;
  kycStatus: KycStatus | null;
  isBlocked: boolean;
};

export type AuthTokensResponse = {
  accessToken: string;
  refreshToken: string;
  user: AuthUserResponse;
};

export type OtpRequestResponse = {
  phone: string;
  expiresInSeconds: number;
};

export type LogoutResponse = {
  loggedOut: true;
};

@Injectable()
export class AuthService {
  private readonly redis: Redis;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly sms: SmsService,
  ) {
    this.redis = this.redisService.getClient();
  }

  async requestOtp(rawPhone: string): Promise<OtpRequestResponse> {
    const phone = normalizeRussianPhone(rawPhone);

    await this.ensureOtpNotBlocked(phone);

    const sendCount = await this.incrWithExpire(
      this.otpSendKey(phone),
      OTP_RATE_WINDOW_SECONDS,
    );
    if (sendCount > OTP_RATE_LIMIT) {
      throw new TooManyRequestsException(
        'Можно запросить не больше 3 кодов за 10 минут',
      );
    }

    const code = this.generateOtpCode();
    const codeHash = await bcrypt.hash(code, 10);

    await this.redis.set(
      this.otpCodeKey(phone),
      codeHash,
      'EX',
      OTP_TTL_SECONDS,
    );
    await this.sms.sendOtp(phone, code);

    return {
      phone,
      expiresInSeconds: OTP_TTL_SECONDS,
    };
  }

  async verifyOtp(rawPhone: string, code: string): Promise<AuthTokensResponse> {
    const phone = normalizeRussianPhone(rawPhone);

    await this.ensureOtpNotBlocked(phone);

    const codeHash = await this.redis.get(this.otpCodeKey(phone));
    if (!codeHash || !(await bcrypt.compare(code, codeHash))) {
      await this.registerOtpFailure(phone);
    }

    await this.redis.del(this.otpCodeKey(phone), this.otpFailKey(phone));

    const user = await this.prisma.user.upsert({
      where: { phone },
      update: {},
      create: { phone },
      select: this.authUserSelect(),
    });

    this.ensureUserCanLogin(user);

    return this.issueTokens(user);
  }

  async refresh(refreshToken: string): Promise<AuthTokensResponse> {
    const payload = await this.verifyRefreshToken(refreshToken);
    const refreshKey = this.refreshTokenKey(payload.jti);
    const storedUserId = await this.redis.get(refreshKey);

    if (storedUserId !== payload.sub) {
      throw new UnauthorizedException('Refresh токен отозван');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: this.authUserSelect(),
    });

    if (!user) {
      await this.redis.del(refreshKey);
      throw new UnauthorizedException('Пользователь не найден');
    }

    this.ensureUserCanLogin(user);
    await this.redis.del(refreshKey);

    return this.issueTokens(user);
  }

  async logout(refreshToken: string): Promise<LogoutResponse> {
    try {
      const payload = await this.verifyRefreshToken(refreshToken);
      await this.redis.del(this.refreshTokenKey(payload.jti));
    } catch {
      return { loggedOut: true };
    }

    return { loggedOut: true };
  }

  async getMe(userId: string): Promise<AuthUserResponse> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: this.authUserSelect(),
    });

    if (!user) {
      throw new UnauthorizedException('Пользователь не найден');
    }

    this.ensureUserCanLogin(user);
    return this.toUserResponse(user);
  }

  protected generateOtpCode(): string {
    return randomInt(100000, 1000000).toString();
  }

  private async issueTokens(user: AuthUserModel): Promise<AuthTokensResponse> {
    const accessSecret = this.getRequiredConfig('JWT_ACCESS_SECRET');
    const refreshSecret = this.getRequiredConfig('JWT_REFRESH_SECRET');
    const accessExpiresIn =
      this.config.get<string>('JWT_ACCESS_EXPIRES_IN') ?? '15m';
    const refreshExpiresIn =
      this.config.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '30d';
    const accessTtlSeconds = parseDurationToSeconds(accessExpiresIn);
    const refreshTtlSeconds = parseDurationToSeconds(refreshExpiresIn);
    const refreshJti = randomUUID();
    const payload = {
      sub: user.id,
      phone: user.phone,
      role: user.role,
    };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(
        {
          ...payload,
          tokenType: 'access',
        },
        { secret: accessSecret, expiresIn: accessTtlSeconds },
      ),
      this.jwt.signAsync(
        {
          ...payload,
          tokenType: 'refresh',
          jti: refreshJti,
        },
        { secret: refreshSecret, expiresIn: refreshTtlSeconds },
      ),
    ]);

    await this.redis.set(
      this.refreshTokenKey(refreshJti),
      user.id,
      'EX',
      refreshTtlSeconds,
    );

    return {
      accessToken,
      refreshToken,
      user: this.toUserResponse(user),
    };
  }

  private async verifyRefreshToken(
    refreshToken: string,
  ): Promise<JwtRefreshPayload> {
    const refreshSecret = this.getRequiredConfig('JWT_REFRESH_SECRET');

    try {
      const payload = await this.jwt.verifyAsync<JwtRefreshPayload>(
        refreshToken,
        {
          secret: refreshSecret,
        },
      );

      if (payload.tokenType !== 'refresh' || !payload.jti) {
        throw new UnauthorizedException('Недействительный refresh токен');
      }

      return payload;
    } catch {
      throw new UnauthorizedException('Недействительный refresh токен');
    }
  }

  private async ensureOtpNotBlocked(phone: string): Promise<void> {
    const blocked = await this.redis.get(this.otpBlockKey(phone));
    if (blocked) {
      throw new TooManyRequestsException('Ввод кода заблокирован на 30 минут');
    }
  }

  private async registerOtpFailure(phone: string): Promise<never> {
    const failCount = await this.incrWithExpire(
      this.otpFailKey(phone),
      OTP_BLOCK_SECONDS,
    );

    if (failCount >= OTP_FAIL_LIMIT) {
      await this.redis.set(
        this.otpBlockKey(phone),
        '1',
        'EX',
        OTP_BLOCK_SECONDS,
      );
      await this.redis.del(this.otpCodeKey(phone), this.otpFailKey(phone));
      throw new TooManyRequestsException(
        'Слишком много неверных кодов. Повторите через 30 минут',
      );
    }

    throw new UnauthorizedException('Неверный код');
  }

  private async incrWithExpire(
    key: string,
    ttlSeconds: number,
  ): Promise<number> {
    const value = await this.redis.incr(key);
    if (value === 1) {
      await this.redis.expire(key, ttlSeconds);
    }

    return value;
  }

  private ensureUserCanLogin(user: AuthUserModel): void {
    if (user.deletedAt) {
      throw new UnauthorizedException('Пользователь не найден');
    }

    if (user.isBlocked) {
      throw new ForbiddenException('Пользователь заблокирован');
    }
  }

  private toUserResponse(user: AuthUserModel): AuthUserResponse {
    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      role: user.role,
      kycStatus: user.kycStatus,
      isBlocked: user.isBlocked,
    };
  }

  private getRequiredConfig(name: string): string {
    const value = this.config.get<string>(name);
    if (!value) {
      throw new Error(`${name} is not configured`);
    }

    return value;
  }

  private authUserSelect() {
    return {
      id: true,
      phone: true,
      name: true,
      role: true,
      kycStatus: true,
      isBlocked: true,
      deletedAt: true,
    } as const;
  }

  private otpCodeKey(phone: string): string {
    return `auth:otp:code:${phone}`;
  }

  private otpSendKey(phone: string): string {
    return `auth:otp:send:${phone}`;
  }

  private otpFailKey(phone: string): string {
    return `auth:otp:fail:${phone}`;
  }

  private otpBlockKey(phone: string): string {
    return `auth:otp:block:${phone}`;
  }

  private refreshTokenKey(jti: string): string {
    return `auth:refresh:${jti}`;
  }
}
