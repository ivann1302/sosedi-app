import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma, PushPlatform, PushTokenProvider } from '@prisma/client';
import { isUUID } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import { DeviceTokenResponseDto } from './dto/device-token-response.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

export type DeleteDeviceTokenResponse = {
  id: string;
  removed: boolean;
};

const SERIALIZABLE_RETRY_ATTEMPTS = 3;

@Injectable()
export class DeviceTokensService {
  constructor(private readonly prisma: PrismaService) {}

  register(
    userId: string,
    installationId: string,
    dto: RegisterDeviceTokenDto,
  ): Promise<DeviceTokenResponseDto> {
    if (!isUUID(installationId, '4')) {
      throw new BadRequestException('X-Installation-Id должен быть UUID v4');
    }
    if (
      dto.provider === PushTokenProvider.RUSTORE &&
      dto.platform !== PushPlatform.ANDROID
    ) {
      throw new BadRequestException(
        'RuStore Push поддерживается только на Android',
      );
    }

    return this.registerWithRetry(userId, installationId, dto);
  }

  private async registerWithRetry(
    userId: string,
    installationId: string,
    dto: RegisterDeviceTokenDto,
  ): Promise<DeviceTokenResponseDto> {
    for (
      let attempt = 1;
      attempt <= SERIALIZABLE_RETRY_ATTEMPTS;
      attempt += 1
    ) {
      try {
        return await this.prisma.$transaction(
          async (tx) => {
            await tx.devicePushToken.deleteMany({
              where: {
                provider: dto.provider,
                token: dto.token,
                NOT: { userId, installationId },
              },
            });
            return tx.devicePushToken.upsert({
              where: {
                userId_installationId_provider: {
                  userId,
                  installationId,
                  provider: dto.provider,
                },
              },
              create: {
                userId,
                installationId,
                provider: dto.provider,
                platform: dto.platform,
                token: dto.token,
              },
              update: {
                platform: dto.platform,
                token: dto.token,
              },
              select: DEVICE_TOKEN_SELECT,
            });
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
      } catch (error) {
        if (
          !(error instanceof Prisma.PrismaClientKnownRequestError) ||
          error.code !== 'P2034' ||
          attempt === SERIALIZABLE_RETRY_ATTEMPTS
        ) {
          throw error;
        }
      }
    }

    throw new Error('Unreachable device token retry state');
  }

  async remove(userId: string, id: string): Promise<DeleteDeviceTokenResponse> {
    const result = await this.prisma.devicePushToken.deleteMany({
      where: { id, userId },
    });
    return { id, removed: result.count === 1 };
  }
}

const DEVICE_TOKEN_SELECT = {
  id: true,
  installationId: true,
  provider: true,
  platform: true,
  updatedAt: true,
} as const satisfies Prisma.DevicePushTokenSelect;
