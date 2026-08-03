import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import {
  Equals,
  IsBoolean,
  IsDateString,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
} from 'class-validator';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class CreateBookingDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID('4')
  itemId: string;

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

  @ApiProperty({
    example: 'offer-v1',
    required: false,
    description:
      'Версия оферты, явно показанная пользователю; обязательна при открытом legal gate',
  })
  @IsOptional()
  @IsString()
  @Matches(/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/)
  offerVersion?: string;

  @ApiProperty({
    example: 'rental-rules-v1',
    required: false,
    description:
      'Версия правил аренды/отмены, явно показанная пользователю; обязательна при открытом legal gate',
  })
  @IsOptional()
  @IsString()
  @Matches(/^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$/)
  cancellationPolicyVersion?: string;

  @ApiProperty({
    example: true,
    required: false,
    description: 'Явное принятие показанной версии оферты',
  })
  @IsOptional()
  @IsBoolean()
  @Equals(true)
  offerAccepted?: boolean;

  @ApiProperty({
    example: true,
    required: false,
    description: 'Явное принятие показанной версии правил аренды/отмены',
  })
  @IsOptional()
  @IsBoolean()
  @Equals(true)
  rentalRulesAccepted?: boolean;
}
