import { Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsUUID, Max, Min } from 'class-validator';

function numberFromInput({ value }: { value: unknown }): unknown {
  return typeof value === 'string' && value.trim().length > 0
    ? Number(value)
    : value;
}

export class ListBookingMessagesQueryDto {
  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  cursor?: string;

  @ApiPropertyOptional({ default: 50, maximum: 100, minimum: 1 })
  @Transform(numberFromInput)
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}
