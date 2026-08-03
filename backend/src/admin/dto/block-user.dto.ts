import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class BlockUserDto {
  @ApiProperty({
    example: 'Подтверждённое злоупотребление сервисом',
    maxLength: 500,
  })
  @Transform(trimString)
  @IsString()
  @MinLength(5)
  @MaxLength(500)
  reason: string;
}
