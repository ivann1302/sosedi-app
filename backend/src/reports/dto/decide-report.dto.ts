import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString, Length } from 'class-validator';

export enum ReportDecision {
  DISMISS = 'DISMISS',
  HIDE_LISTING = 'HIDE_LISTING',
  BLOCK_USER = 'BLOCK_USER',
}

export class DecideReportDto {
  @ApiProperty({ enum: ReportDecision })
  @IsEnum(ReportDecision)
  decision!: ReportDecision;

  @ApiProperty({ minLength: 10, maxLength: 500 })
  @IsString()
  @Length(10, 500)
  reason!: string;
}
