import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength } from 'class-validator';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class RejectToolDto {
  @ApiProperty({
    example: 'Фото не показывает состояние инструмента',
    maxLength: 500,
  })
  @Transform(trimString)
  @IsString()
  @MinLength(5)
  @MaxLength(500)
  reason: string;
}
