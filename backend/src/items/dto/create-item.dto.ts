import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ItemCondition } from '@prisma/client';
import {
  Equals,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { ITEM_LISTING_RULES_VERSION } from '../items.constants';

function trimString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

function numberFromInput({ value }: { value: unknown }): unknown {
  if (typeof value !== 'string') {
    return value;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? Number(trimmed) : value;
}

function nullableNumberFromInput({ value }: { value: unknown }): unknown {
  if (typeof value !== 'string') {
    return value;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? Number(trimmed) : null;
}

export class CreateItemDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID('4')
  categoryId: string;

  @ApiProperty({ maxLength: 120, minLength: 3 })
  @Transform(trimString)
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  title: string;

  @ApiProperty({ maxLength: 4000, minLength: 10 })
  @Transform(trimString)
  @IsString()
  @MinLength(10)
  @MaxLength(4000)
  description: string;

  @ApiProperty({ enum: ItemCondition })
  @IsEnum(ItemCondition)
  condition: ItemCondition;

  @ApiProperty({ maxLength: 1000, minLength: 3 })
  @Transform(trimString)
  @IsString()
  @MinLength(3)
  @MaxLength(1000)
  completeness: string;

  @ApiProperty({ maxLength: 1000, minLength: 3 })
  @Transform(trimString)
  @IsString()
  @MinLength(3)
  @MaxLength(1000)
  handoverTerms: string;

  @ApiProperty({ maximum: 1_000_000, minimum: 1 })
  @Transform(numberFromInput)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(1_000_000)
  pricePerDay: number;

  @ApiPropertyOptional({
    description:
      'Залог не поддерживается до отдельного утверждения: допустим только 0',
    enum: [0],
    example: 0,
    maximum: 0,
    minimum: 0,
    nullable: true,
    type: Number,
  })
  @Transform(nullableNumberFromInput)
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Equals(0)
  depositAmount?: number | null;

  @ApiPropertyOptional({
    description:
      'Точный залог в копейках; доступность определяет серверная policy',
    example: 50_000,
    maximum: 3_000_000_000,
    minimum: 0,
    nullable: true,
    type: 'integer',
  })
  @Transform(nullableNumberFromInput)
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(3_000_000_000)
  depositAmountMinor?: number | null;

  @ApiProperty({
    description: 'Публичный район или округ без улицы, дома и pickup-адреса',
    maxLength: 120,
    minLength: 2,
  })
  @Transform(trimString)
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  publicArea: string;

  @ApiProperty({
    description: 'Приватный pickup-адрес; публичный API его не возвращает',
    maxLength: 300,
    minLength: 5,
  })
  @Transform(trimString)
  @IsString()
  @MinLength(5)
  @MaxLength(300)
  address: string;

  @ApiProperty({ maximum: 90, minimum: -90 })
  @Transform(numberFromInput)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @ApiProperty({ maximum: 180, minimum: -180 })
  @Transform(numberFromInput)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @ApiProperty({
    description: 'Пользователь подтверждает право распоряжаться вещью',
    example: true,
  })
  @IsBoolean()
  @Equals(true)
  ownershipConfirmed: boolean;

  @ApiProperty({
    description:
      'Пользователь подтверждает исправность и точность указанного состояния',
    example: true,
  })
  @IsBoolean()
  @Equals(true)
  conditionConfirmed: boolean;

  @ApiProperty({
    description: 'Пользователь подтверждает точность указанной комплектации',
    example: true,
  })
  @IsBoolean()
  @Equals(true)
  completenessConfirmed: boolean;

  @ApiProperty({
    description:
      'Пользователь принимает применимые safety-правила категории и правила площадки',
    example: true,
  })
  @IsBoolean()
  @Equals(true)
  safetyAndMarketplaceRulesAccepted: boolean;

  @ApiProperty({
    description: 'Актуальная версия правил публикации объявления',
    enum: [ITEM_LISTING_RULES_VERSION],
  })
  @Equals(ITEM_LISTING_RULES_VERSION)
  @IsString()
  listingRulesVersion: string;
}
