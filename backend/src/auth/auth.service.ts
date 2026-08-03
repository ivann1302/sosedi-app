import {
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { KycStatus, User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import type Redis from 'ioredis';
import { createHash, randomInt, randomUUID } from 'node:crypto';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { MetricsService } from '../observability/metrics.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import {
  JwtRefreshPayload,
  JwtUserStepUpPayload,
  type UserStepUpPurpose,
} from './auth.types';
import { normalizeRussianPhone, parseDurationToSeconds } from './auth.util';
import { SmsService } from './sms.service';

const OTP_TTL_SECONDS = 5 * 60;
const OTP_RATE_LIMIT = 3;
const OTP_DEVICE_RATE_LIMIT = 6;
const OTP_IP_RATE_LIMIT = 60;
const OTP_GLOBAL_RATE_LIMIT = 1_000;
const OTP_RATE_WINDOW_SECONDS = 10 * 60;
const OTP_GLOBAL_RATE_WINDOW_SECONDS = 24 * 60 * 60;
const OTP_FAIL_LIMIT = 5;
const OTP_BLOCK_SECONDS = 30 * 60;
const USER_STEP_UP_TTL_SECONDS = 5 * 60;

const INCR_WITH_EXPIRE_SCRIPT = `
  local value = redis.call('INCR', KEYS[1])
  if value == 1 then
    redis.call('EXPIRE', KEYS[1], ARGV[1])
  end
  return value
`;

type AuthUserModel = Pick<
  User,
  | 'id'
  | 'phone'
  | 'name'
  | 'role'
  | 'adminCapabilities'
  | 'kycStatus'
  | 'isBlocked'
  | 'sessionVersion'
  | 'deletedAt'
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

export type OtpRequestContext = {
  installationId: string;
  ipAddress: string;
};

export type LogoutResponse = {
  loggedOut: true;
};

type RefreshSessionRecord = {
  userId: string;
  sessionId: string;
  currentJti: string;
  installationId: string;
  createdAt: string;
  lastSeenAt: string;
};

export type UserSessionResponse = {
  sessionId: string;
  installationId: string;
  createdAt: Date;
  lastSeenAt: Date;
  isCurrent: boolean;
};

export type UserStepUpResponse = {
  stepUpToken: string;
  expiresInSeconds: number;
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
    private readonly metrics: MetricsService,
  ) {
    this.redis = this.redisService.getClient();
  }

  async requestOtp(
    rawPhone: string,
    context: OtpRequestContext,
  ): Promise<OtpRequestResponse> {
    const phone = normalizeRussianPhone(rawPhone);

    await this.ensureOtpNotBlocked(phone);

    const [sendCount, deviceCount, ipCount] = await Promise.all([
      this.incrWithExpire(this.otpSendKey(phone), OTP_RATE_WINDOW_SECONDS),
      this.incrWithExpire(
        this.otpDeviceSendKey(context.installationId),
        OTP_RATE_WINDOW_SECONDS,
      ),
      this.incrWithExpire(
        this.otpIpSendKey(context.ipAddress),
        OTP_RATE_WINDOW_SECONDS,
      ),
    ]);
    if (sendCount > OTP_RATE_LIMIT) {
      throw new TooManyRequestsException(
        'Можно запросить не больше 3 кодов за 10 минут',
      );
    }
    if (
      deviceCount >
        this.getPositiveIntegerConfig(
          'OTP_DEVICE_RATE_LIMIT',
          OTP_DEVICE_RATE_LIMIT,
        ) ||
      ipCount >
        this.getPositiveIntegerConfig('OTP_IP_RATE_LIMIT', OTP_IP_RATE_LIMIT)
    ) {
      throw new TooManyRequestsException(
        'Слишком много запросов OTP. Повторите позже',
      );
    }
    const globalCount = await this.incrWithExpire(
      this.otpGlobalSendKey(),
      OTP_GLOBAL_RATE_WINDOW_SECONDS,
    );
    if (
      globalCount >
      this.getPositiveIntegerConfig(
        'OTP_GLOBAL_RATE_LIMIT',
        OTP_GLOBAL_RATE_LIMIT,
      )
    ) {
      this.metrics.recordOperation('otp_global_limit', 'failure');
      throw new TooManyRequestsException(
        'Временно невозможно отправить код. Повторите позже',
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
    try {
      await this.sms.sendOtp(phone, code);
    } catch (error) {
      await this.consumeOtpCode(phone, codeHash);
      throw error;
    }

    return {
      phone,
      expiresInSeconds: OTP_TTL_SECONDS,
    };
  }

  async verifyOtp(
    rawPhone: string,
    code: string,
    installationId: string,
  ): Promise<AuthTokensResponse> {
    const phone = normalizeRussianPhone(rawPhone);

    await this.verifyAndConsumeOtp(phone, code);

    const user = await this.prisma.user.upsert({
      where: { phone },
      update: {},
      create: { phone },
      select: this.authUserSelect(),
    });

    this.ensureUserCanLogin(user);

    return this.issueTokens(user, { installationId });
  }

  requestUserStepUpOtp(
    phone: string,
    context: OtpRequestContext,
  ): Promise<OtpRequestResponse> {
    return this.requestOtp(phone, context);
  }

  async verifyUserStepUpOtp(
    userId: string,
    phone: string,
    code: string,
    purpose: UserStepUpPurpose,
  ): Promise<UserStepUpResponse> {
    await this.verifyAndConsumeOtp(phone, code);
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        phone: true,
        sessionVersion: true,
        isBlocked: true,
        deletedAt: true,
      },
    });
    if (!user || user.phone !== phone || user.deletedAt || user.isBlocked) {
      throw new UnauthorizedException('Пользователь недоступен');
    }

    const jti = randomUUID();
    const stepUpToken = await this.jwt.signAsync(
      {
        sub: user.id,
        tokenType: 'user-step-up',
        purpose,
        sessionVersion: user.sessionVersion,
        jti,
      },
      {
        secret: this.getRequiredConfig('JWT_ACCESS_SECRET'),
        expiresIn: USER_STEP_UP_TTL_SECONDS,
      },
    );
    await this.redis.set(
      this.userStepUpKey(jti),
      JSON.stringify({
        userId: user.id,
        purpose,
        sessionVersion: user.sessionVersion,
      }),
      'EX',
      USER_STEP_UP_TTL_SECONDS,
    );

    return { stepUpToken, expiresInSeconds: USER_STEP_UP_TTL_SECONDS };
  }

  async consumeUserStepUpToken(
    token: string,
    userId: string,
    purpose: UserStepUpPurpose,
  ): Promise<void> {
    let payload: JwtUserStepUpPayload;
    try {
      payload = await this.jwt.verifyAsync<JwtUserStepUpPayload>(token, {
        secret: this.getRequiredConfig('JWT_ACCESS_SECRET'),
        algorithms: ['HS256'],
      });
    } catch {
      throw this.stepUpRequired();
    }
    if (
      payload.tokenType !== 'user-step-up' ||
      payload.purpose !== purpose ||
      payload.sub !== userId ||
      !payload.jti ||
      !Number.isInteger(payload.sessionVersion)
    ) {
      throw this.stepUpRequired();
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        sessionVersion: true,
        isBlocked: true,
        deletedAt: true,
      },
    });
    const stored = await this.redis.getdel(this.userStepUpKey(payload.jti));
    if (
      !user ||
      user.isBlocked ||
      user.deletedAt ||
      user.sessionVersion !== payload.sessionVersion ||
      stored !==
        JSON.stringify({
          userId,
          purpose,
          sessionVersion: payload.sessionVersion,
        })
    ) {
      throw this.stepUpRequired();
    }
  }

  async refresh(refreshToken: string): Promise<AuthTokensResponse> {
    const payload = await this.verifyRefreshToken(refreshToken);
    const refreshKey = this.refreshTokenKey(payload.jti);
    const storedSession = this.parseRefreshSession(
      await this.redis.getdel(refreshKey),
    );

    if (storedSession?.userId !== payload.sub) {
      await this.revokeSession(payload.sub, payload.sid);
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

    if (payload.sessionVersion !== user.sessionVersion) {
      throw new UnauthorizedException('Сессия отозвана');
    }

    this.ensureUserCanLogin(user);

    return this.issueTokens(user, {
      installationId: storedSession.installationId,
      sessionId: storedSession.sessionId,
      createdAt: storedSession.createdAt,
    });
  }

  async logout(refreshToken: string): Promise<LogoutResponse> {
    let payload: JwtRefreshPayload;
    try {
      payload = await this.verifyRefreshToken(refreshToken);
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        return { loggedOut: true };
      }

      throw error;
    }

    const refreshKey = this.refreshTokenKey(payload.jti);
    const session = this.parseRefreshSession(await this.redis.get(refreshKey));
    await this.redis.del(refreshKey);
    if (session) {
      await Promise.all([
        this.redis.del(this.sessionKey(session.userId, session.sessionId)),
        this.redis.srem(
          this.userSessionsKey(session.userId),
          session.sessionId,
        ),
      ]);
    }
    return { loggedOut: true };
  }

  async listSessions(
    userId: string,
    currentInstallationId: string,
  ): Promise<UserSessionResponse[]> {
    const sessionIds = await this.redis.smembers(this.userSessionsKey(userId));
    const sessions: UserSessionResponse[] = [];

    for (const sessionId of sessionIds) {
      const session = this.parseRefreshSession(
        await this.redis.get(this.sessionKey(userId, sessionId)),
      );
      if (!session || session.userId !== userId) {
        await this.redis.srem(this.userSessionsKey(userId), sessionId);
        continue;
      }
      sessions.push({
        sessionId: session.sessionId,
        installationId: session.installationId,
        createdAt: new Date(session.createdAt),
        lastSeenAt: new Date(session.lastSeenAt),
        isCurrent: session.installationId === currentInstallationId,
      });
    }

    return sessions.sort(
      (left, right) => right.lastSeenAt.getTime() - left.lastSeenAt.getTime(),
    );
  }

  async revokeSession(
    userId: string,
    sessionId: string,
  ): Promise<LogoutResponse> {
    const sessionKey = this.sessionKey(userId, sessionId);
    const session = this.parseRefreshSession(await this.redis.get(sessionKey));
    if (!session || session.userId !== userId) {
      return { loggedOut: true };
    }

    await Promise.all([
      this.redis.del(this.refreshTokenKey(session.currentJti)),
      this.redis.del(sessionKey),
      this.redis.srem(this.userSessionsKey(userId), sessionId),
    ]);
    return { loggedOut: true };
  }

  async revokeAllSessions(userId: string): Promise<LogoutResponse> {
    const sessionIds = await this.redis.smembers(this.userSessionsKey(userId));
    const refreshKeys: string[] = [];
    for (const sessionId of sessionIds) {
      const session = this.parseRefreshSession(
        await this.redis.get(this.sessionKey(userId, sessionId)),
      );
      if (session?.userId === userId) {
        refreshKeys.push(this.refreshTokenKey(session.currentJti));
      }
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { sessionVersion: { increment: 1 } },
    });
    await this.redis.del(
      ...refreshKeys,
      ...sessionIds.map((sessionId) => this.sessionKey(userId, sessionId)),
      this.userSessionsKey(userId),
    );
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
    const provider = this.config.get<string>('SMS_PROVIDER') ?? 'console';
    const apiKey = this.config.get<string>('SMS_API_KEY');
    const devOtpCode = this.config.get<string>('DEV_SMS_OTP_CODE');
    if (
      process.env.NODE_ENV !== 'production' &&
      devOtpCode !== undefined &&
      (provider === 'console' || !apiKey || apiKey === 'change_me')
    ) {
      if (!/^\d{6}$/.test(devOtpCode)) {
        throw new InternalServerErrorException(
          'DEV_SMS_OTP_CODE должен содержать ровно 6 цифр',
        );
      }
      return devOtpCode;
    }

    return randomInt(100000, 1000000).toString();
  }

  private async issueTokens(
    user: AuthUserModel,
    context: {
      installationId: string;
      sessionId?: string;
      createdAt?: string;
    },
  ): Promise<AuthTokensResponse> {
    const accessSecret = this.getRequiredConfig('JWT_ACCESS_SECRET');
    const refreshSecret = this.getRequiredConfig('JWT_REFRESH_SECRET');
    const accessExpiresIn =
      this.config.get<string>('JWT_ACCESS_EXPIRES_IN') ?? '15m';
    const refreshExpiresIn =
      this.config.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '30d';
    const accessTtlSeconds = parseDurationToSeconds(accessExpiresIn);
    const refreshTtlSeconds = parseDurationToSeconds(refreshExpiresIn);
    const refreshJti = randomUUID();
    const sessionId = context.sessionId ?? randomUUID();
    const now = new Date().toISOString();
    const payload = {
      sub: user.id,
      phone: user.phone,
      role: user.role,
      sessionVersion: user.sessionVersion,
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
          sid: sessionId,
        },
        { secret: refreshSecret, expiresIn: refreshTtlSeconds },
      ),
    ]);

    const session: RefreshSessionRecord = {
      userId: user.id,
      sessionId,
      currentJti: refreshJti,
      installationId: context.installationId,
      createdAt: context.createdAt ?? now,
      lastSeenAt: now,
    };
    const serializedSession = JSON.stringify(session);
    await Promise.all([
      this.redis.set(
        this.refreshTokenKey(refreshJti),
        serializedSession,
        'EX',
        refreshTtlSeconds,
      ),
      this.redis.set(
        this.sessionKey(user.id, sessionId),
        serializedSession,
        'EX',
        refreshTtlSeconds,
      ),
      this.redis.sadd(this.userSessionsKey(user.id), sessionId),
    ]);
    await this.redis.expire(this.userSessionsKey(user.id), refreshTtlSeconds);

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

      if (
        payload.tokenType !== 'refresh' ||
        !payload.jti ||
        !payload.sid ||
        !Number.isInteger(payload.sessionVersion) ||
        payload.sessionVersion < 0
      ) {
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

  private async consumeOtpCode(
    phone: string,
    expectedHash: string,
  ): Promise<boolean> {
    const result = await this.redis.eval(
      `
        if redis.call('GET', KEYS[1]) == ARGV[1] then
          return redis.call('DEL', KEYS[1])
        end
        return 0
      `,
      1,
      this.otpCodeKey(phone),
      expectedHash,
    );

    return Number(result) === 1;
  }

  private async verifyAndConsumeOtp(
    phone: string,
    code: string,
  ): Promise<void> {
    await this.ensureOtpNotBlocked(phone);

    const codeHash = await this.redis.get(this.otpCodeKey(phone));
    if (!codeHash || !(await bcrypt.compare(code, codeHash))) {
      return this.registerOtpFailure(phone);
    }

    if (!(await this.consumeOtpCode(phone, codeHash))) {
      throw new UnauthorizedException('Неверный код');
    }

    await this.redis.del(this.otpFailKey(phone));
  }

  private async incrWithExpire(
    key: string,
    ttlSeconds: number,
  ): Promise<number> {
    const value = await this.redis.eval(
      INCR_WITH_EXPIRE_SCRIPT,
      1,
      key,
      ttlSeconds.toString(),
    );

    return Number(value);
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

  private getPositiveIntegerConfig(name: string, fallback: number): number {
    const rawValue = this.config.get<string>(name);
    if (rawValue === undefined) {
      return fallback;
    }

    const value = Number(rawValue);
    if (!Number.isSafeInteger(value) || value < 1) {
      throw new InternalServerErrorException(
        `${name} должен быть положительным целым числом`,
      );
    }
    return value;
  }

  private authUserSelect() {
    return {
      id: true,
      phone: true,
      name: true,
      role: true,
      adminCapabilities: true,
      kycStatus: true,
      isBlocked: true,
      sessionVersion: true,
      deletedAt: true,
    } as const;
  }

  private otpCodeKey(phone: string): string {
    return `auth:otp:code:${phone}`;
  }

  private otpSendKey(phone: string): string {
    return `auth:otp:send:${phone}`;
  }

  private otpDeviceSendKey(installationId: string): string {
    return `auth:otp:send:device:${this.hashRateLimitSubject(installationId)}`;
  }

  private otpIpSendKey(ipAddress: string): string {
    return `auth:otp:send:ip:${this.hashRateLimitSubject(ipAddress)}`;
  }

  private otpGlobalSendKey(): string {
    return 'auth:otp:send:global';
  }

  private hashRateLimitSubject(value: string): string {
    return createHash('sha256').update(value).digest('hex');
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

  private userSessionsKey(userId: string): string {
    return `auth:sessions:${userId}`;
  }

  private sessionKey(userId: string, sessionId: string): string {
    return `auth:session:${userId}:${sessionId}`;
  }

  private userStepUpKey(jti: string): string {
    return `auth:user-step-up:${jti}`;
  }

  private stepUpRequired(): UnauthorizedException {
    return new UnauthorizedException({
      code: 'STEP_UP_REQUIRED',
      message: 'Требуется повторное подтверждение по SMS',
    });
  }

  private parseRefreshSession(raw: string | null): RefreshSessionRecord | null {
    if (!raw) {
      return null;
    }
    try {
      const value = JSON.parse(raw) as Partial<RefreshSessionRecord>;
      if (
        typeof value.userId !== 'string' ||
        typeof value.sessionId !== 'string' ||
        typeof value.currentJti !== 'string' ||
        typeof value.installationId !== 'string' ||
        typeof value.createdAt !== 'string' ||
        typeof value.lastSeenAt !== 'string'
      ) {
        return null;
      }
      return value as RefreshSessionRecord;
    } catch {
      return null;
    }
  }
}
