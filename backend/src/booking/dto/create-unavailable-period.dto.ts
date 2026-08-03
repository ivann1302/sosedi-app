import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import { IsDateString, Matches } from 'class-validator';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class CreateUnavailablePeriodDto {
  @ApiProperty({ example: '2026-08-01', format: 'date' })
  @Transform(trimString)
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  @IsDateString({ strict: true, strictSeparator: true })
  startDate: string;

  @ApiProperty({ example: '2026-08-03', format: 'date' })
  @Transform(trimString)
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  @IsDateString({ strict: true, strictSeparator: true })
  endDate: string;
}
