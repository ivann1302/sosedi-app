import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class ConfirmAvatarUploadDto {
  @ApiProperty({
    description: 'Upload intent текущего пользователя',
  })
  @IsUUID()
  intentId: string;
}
