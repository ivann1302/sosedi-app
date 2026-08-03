import { ApiProperty } from '@nestjs/swagger';
import { PushPlatform, PushTokenProvider } from '@prisma/client';

export class DeviceTokenResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  installationId!: string;

  @ApiProperty({ enum: PushTokenProvider })
  provider!: PushTokenProvider;

  @ApiProperty({ enum: PushPlatform })
  platform!: PushPlatform;

  @ApiProperty()
  updatedAt!: Date;
}
