import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

function numberFromInput({ value }: { value: unknown }): unknown {
  return typeof value === 'string' && value.trim() !== ''
    ? Number(value)
    : value;
}

function booleanFromInput({ value }: { value: unknown }): unknown {
  if (value === 'true') return true;
  if (value === 'false') return false;
  return value;
}

export class InboxPageQueryDto {
  @ApiPropertyOptional({ maximum: 50, minimum: 1, type: 'integer' })
  @Transform(numberFromInput)
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  cursor?: string;

  @ApiPropertyOptional({ type: 'boolean' })
  @Transform(booleanFromInput)
  @IsOptional()
  @IsBoolean()
  unreadOnly?: boolean;
}
