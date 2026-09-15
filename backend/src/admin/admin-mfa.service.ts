import {
  ConflictException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import {
  createCipheriv,
  createDecipheriv,
  createHash,
  randomBytes,
} from 'node:crypto';
import type Redis from 'ioredis';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import type { AdminAuditContext } from './admin-audit-context';
import { buildTotpUri, generateTotpSecret, verifyTotpCode } from './admin-totp';

const MFA_SETUP_TTL_SECONDS = 10 * 60;
const MFA_ATTEMPT_TTL_SECONDS = 5 * 60;
const MAX_MFA_ATTEMPTS = 5;
const RECOVERY_CODE_COUNT = 10;

export type TotpSetupResponse = {
  secret: string;
  otpauthUri: string;
  expiresInSeconds: number;
};

export type TotpConfirmResponse = {
  recoveryCodes: string[];
};

@Injectable()
export class AdminMfaService {
  private readonly redis: Redis;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly config: ConfigService,
  ) {
    this.redis = this.redisService.getClient();
  }

  async beginTotpSetup(
    userId: string,
    phone: string,
    context: AdminAuditContext,
  ): Promise<TotpSetupResponse> {
    const existing = await this.prisma.adminMfaCredential.findUnique({
      where: { userId },
      select: { userId: true },
    });
    if (existing) {
      throw new ConflictException('TOTP уже подключён');
    }

    const secret = generateTotpSecret();
    await this.redis.set(
      this.setupKey(userId),
      this.encrypt(secret),
      'EX',
      MFA_SETUP_TTL_SECONDS,
    );
    try {
      await this.prisma.adminAuditLog.create({
        data: {
          adminId: userId,
          action: 'ADMIN_MFA_SETUP_STARTED',
          entityType: 'User',
          entityId: userId,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          before: { pendingMfaSetup: false },
          after: { pendingMfaSetup: true },
        },
      });
    } catch (error) {
      await this.redis.del(this.setupKey(userId));
      throw error;
    }

    return {
      secret,
      otpauthUri: buildTotpUri('Всё рядом', phone, secret),
      expiresInSeconds: MFA_SETUP_TTL_SECONDS,
    };
  }

  async confirmTotpSetup(
    userId: string,
    code: string,
    context: AdminAuditContext,
  ): Promise<TotpConfirmResponse> {
    const encryptedSecret = await this.redis.get(this.setupKey(userId));
    if (!encryptedSecret) {
      throw new UnauthorizedException(
        'Настройка TOTP истекла, начните её заново',
      );
    }

    const secret = this.decrypt(encryptedSecret);
    const result = verifyTotpCode(secret, code);
    if (!result.valid) {
      throw new UnauthorizedException('Неверный код TOTP');
    }

    const recoveryCodes = this.generateRecoveryCodes();
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.adminMfaCredential.create({
          data: {
            userId,
            totpSecretEncrypted: this.encrypt(secret),
            lastTotpStep: result.timeStep,
          },
        });
        await tx.adminRecoveryCode.createMany({
          data: recoveryCodes.map((recoveryCode) => ({
            userId,
            codeHash: this.hashRecoveryCode(recoveryCode),
          })),
        });
        await tx.adminAuditLog.create({
          data: {
            adminId: userId,
            action: 'ADMIN_MFA_ENABLED',
            entityType: 'User',
            entityId: userId,
            requestId: context.requestId,
            ipAddress: context.ipAddress,
            deviceId: context.deviceId,
            before: { mfaEnabled: false },
            after: { mfaEnabled: true },
            metadata: {
              method: 'TOTP',
              recoveryCodeCount: RECOVERY_CODE_COUNT,
            },
          },
        });
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('TOTP уже подключён');
      }
      throw error;
    }

    await this.redis.del(this.setupKey(userId));
    return { recoveryCodes };
  }

  async verifyStepUp(
    userId: string,
    rawCode: string,
    context: AdminAuditContext,
  ): Promise<void> {
    await this.registerAttempt(userId);
    const code = rawCode.toUpperCase();

    if (/^\d{6}$/.test(code)) {
      await this.verifyTotp(userId, code);
    } else {
      await this.consumeRecoveryCode(userId, code, context);
    }

    await this.redis.del(this.attemptKey(userId));
  }

  private async verifyTotp(userId: string, code: string): Promise<void> {
    const credential = await this.prisma.adminMfaCredential.findUnique({
      where: { userId },
    });
    if (!credential) {
      throw new UnauthorizedException('Сначала подключите TOTP');
    }

    const result = verifyTotpCode(
      this.decrypt(credential.totpSecretEncrypted),
      code,
      credential.lastTotpStep,
    );
    if (!result.valid) {
      throw new UnauthorizedException(
        'Неверный или уже использованный код MFA',
      );
    }

    const updated = await this.prisma.adminMfaCredential.updateMany({
      where: {
        userId,
        lastTotpStep: { lt: result.timeStep },
      },
      data: { lastTotpStep: result.timeStep },
    });
    if (updated.count !== 1) {
      throw new UnauthorizedException('Код MFA уже использован');
    }
  }

  private async consumeRecoveryCode(
    userId: string,
    recoveryCode: string,
    context: AdminAuditContext,
  ): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const consumed = await tx.adminRecoveryCode.updateMany({
        where: {
          userId,
          codeHash: this.hashRecoveryCode(recoveryCode),
          usedAt: null,
        },
        data: { usedAt: new Date() },
      });
      if (consumed.count !== 1) {
        throw new UnauthorizedException(
          'Неверный или уже использованный recovery code',
        );
      }

      const remaining = await tx.adminRecoveryCode.count({
        where: { userId, usedAt: null },
      });
      await tx.adminAuditLog.create({
        data: {
          adminId: userId,
          action: 'ADMIN_RECOVERY_CODE_USED',
          entityType: 'User',
          entityId: userId,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          before: { remaining: remaining + 1 },
          after: { remaining },
          metadata: { remaining },
        },
      });
    });
  }

  private async registerAttempt(userId: string): Promise<void> {
    const key = this.attemptKey(userId);
    const attempts = await this.redis.incr(key);
    if (attempts === 1) {
      await this.redis.expire(key, MFA_ATTEMPT_TTL_SECONDS);
    }
    if (attempts > MAX_MFA_ATTEMPTS) {
      throw new TooManyRequestsException(
        'Слишком много попыток MFA, повторите позже',
      );
    }
  }

  private generateRecoveryCodes(): string[] {
    return Array.from({ length: RECOVERY_CODE_COUNT }, () =>
      randomBytes(10)
        .toString('hex')
        .toUpperCase()
        .match(/.{1,4}/g)!
        .join('-'),
    );
  }

  private hashRecoveryCode(code: string): string {
    return createHash('sha256').update(code.toUpperCase()).digest('hex');
  }

  private encrypt(value: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey(), iv);
    const ciphertext = Buffer.concat([
      cipher.update(value, 'utf8'),
      cipher.final(),
    ]);
    return [
      'v1',
      iv.toString('base64url'),
      cipher.getAuthTag().toString('base64url'),
      ciphertext.toString('base64url'),
    ].join('.');
  }

  private decrypt(value: string): string {
    const [version, iv, authTag, ciphertext] = value.split('.');
    if (version !== 'v1' || !iv || !authTag || !ciphertext) {
      throw new InternalServerErrorException('Повреждена конфигурация MFA');
    }

    try {
      const decipher = createDecipheriv(
        'aes-256-gcm',
        this.encryptionKey(),
        Buffer.from(iv, 'base64url'),
      );
      decipher.setAuthTag(Buffer.from(authTag, 'base64url'));
      return Buffer.concat([
        decipher.update(Buffer.from(ciphertext, 'base64url')),
        decipher.final(),
      ]).toString('utf8');
    } catch {
      throw new InternalServerErrorException('Не удалось расшифровать MFA');
    }
  }

  private encryptionKey(): Buffer {
    const value = this.config.get<string>('ADMIN_MFA_ENCRYPTION_KEY');
    if (!value || value.startsWith('change_me')) {
      throw new InternalServerErrorException(
        'ADMIN_MFA_ENCRYPTION_KEY должен быть отдельным 32-byte base64 ключом',
      );
    }
    const key = Buffer.from(value, 'base64');
    if (key.length !== 32) {
      throw new InternalServerErrorException(
        'ADMIN_MFA_ENCRYPTION_KEY должен быть отдельным 32-byte base64 ключом',
      );
    }
    return key;
  }

  private setupKey(userId: string): string {
    return `auth:admin-mfa-setup:${userId}`;
  }

  private attemptKey(userId: string): string {
    return `auth:admin-mfa-attempt:${userId}`;
  }
}
