import { ApiProperty } from '@nestjs/swagger';
import { ReportReason, ReportTargetType } from '@prisma/client';
import { IsEnum, IsString, IsUUID, Length } from 'class-validator';

export class CreateReportDto {
  @ApiProperty({ enum: ReportTargetType, enumName: 'ReportTargetType' })
  @IsEnum(ReportTargetType)
  targetType!: ReportTargetType;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  targetId!: string;

  @ApiProperty({ enum: ReportReason, enumName: 'ReportReason' })
  @IsEnum(ReportReason)
  reason!: ReportReason;

  @ApiProperty({ minLength: 20, maxLength: 1000 })
  @IsString()
  @Length(20, 1000)
  description!: string;
}
