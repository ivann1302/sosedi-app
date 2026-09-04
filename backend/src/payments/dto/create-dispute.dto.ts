import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FinancialDisputeReason } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class CreateDisputeDto {
  @ApiProperty({ enum: FinancialDisputeReason })
  @IsEnum(FinancialDisputeReason)
  reason: FinancialDisputeReason;

  @ApiPropertyOptional({ maxLength: 1000 })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(1000)
  description?: string;
}
