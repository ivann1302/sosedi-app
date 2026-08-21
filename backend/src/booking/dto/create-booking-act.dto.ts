import { ApiProperty } from '@nestjs/swagger';
import { BookingActStage } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  Equals,
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class HandoverReadinessDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  @Equals(true)
  isWorking: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  @Equals(true)
  isComplete: boolean;

  @ApiProperty({ example: 'Потёртость на ручке или «нет»' })
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  )
  @IsString()
  @MinLength(2)
  @MaxLength(500)
  visibleDefects: string;
}

export class CreateBookingActDto {
  @ApiProperty({ enum: BookingActStage })
  @IsEnum(BookingActStage)
  stage: BookingActStage;

  @ApiProperty({ format: 'uuid' })
  @IsUUID('4')
  intentId: string;

  @ApiProperty({ type: HandoverReadinessDto, required: false })
  @IsOptional()
  @ValidateNested()
  @Type(() => HandoverReadinessDto)
  readiness?: HandoverReadinessDto;
}
