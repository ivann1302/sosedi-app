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

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(2000)
  description?: string;
}
