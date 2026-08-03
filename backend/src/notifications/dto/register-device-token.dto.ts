import { ApiProperty } from '@nestjs/swagger';
import { PushPlatform, PushTokenProvider } from '@prisma/client';
import { IsEnum, IsString, Length } from 'class-validator';

export class RegisterDeviceTokenDto {
  @ApiProperty({ enum: PushTokenProvider })
  @IsEnum(PushTokenProvider)
  provider!: PushTokenProvider;

  @ApiProperty({ enum: PushPlatform })
  @IsEnum(PushPlatform)
  platform!: PushPlatform;

  @ApiProperty({ minLength: 20, maxLength: 4096 })
  @IsString()
  @Length(20, 4096)
  token!: string;
}
