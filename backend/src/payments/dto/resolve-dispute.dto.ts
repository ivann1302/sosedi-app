import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsInt,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

const MAX_SAFE_INTEGER = Number.MAX_SAFE_INTEGER;

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class ResolveDisputeDto {
  @ApiProperty({ minimum: 0, maximum: MAX_SAFE_INTEGER })
  @IsInt()
  @Min(0)
  @Max(MAX_SAFE_INTEGER)
  refundToBorrowerMinor: number;

  @ApiProperty({ minimum: 0, maximum: MAX_SAFE_INTEGER })
  @IsInt()
  @Min(0)
  @Max(MAX_SAFE_INTEGER)
  releaseToLenderMinor: number;

  @ApiProperty({ minLength: 10, maxLength: 1000 })
  @Transform(trimString)
  @IsString()
  @MinLength(10)
  @MaxLength(1000)
  reason: string;
}
