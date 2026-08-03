import { Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Matches,
  Max,
  Min,
} from 'class-validator';

export enum ItemListSort {
  NEWEST = 'newest',
  DISTANCE = 'distance',
  PRICE_ASC = 'price_asc',
  PRICE_DESC = 'price_desc',
}

function numberFromInput({ value }: { value: unknown }): unknown {
  if (typeof value !== 'string') {
    return value;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? Number(trimmed) : value;
}

function trimmedStringFromInput({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class ListItemsQueryDto {
  @ApiPropertyOptional({ maxLength: 100 })
  @Transform(trimmedStringFromInput)
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  categoryId?: string;

  @ApiPropertyOptional({ minimum: 0 })
  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  minPrice?: number;

  @ApiPropertyOptional({ minimum: 0 })
  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  maxPrice?: number;

  @ApiPropertyOptional({ example: '2026-08-01', format: 'date' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Дата начала аренды должна быть в формате YYYY-MM-DD',
  })
  @IsDateString({ strict: true, strictSeparator: true })
  availableFrom?: string;

  @ApiPropertyOptional({ example: '2026-08-03', format: 'date' })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Дата окончания аренды должна быть в формате YYYY-MM-DD',
  })
  @IsDateString({ strict: true, strictSeparator: true })
  availableTo?: string;

  @ApiPropertyOptional({ maximum: 90, minimum: -90 })
  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @ApiPropertyOptional({ maximum: 180, minimum: -180 })
  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @ApiPropertyOptional({ maximum: 50, minimum: 0.1 })
  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(50)
  radiusKm?: number;

  @ApiPropertyOptional({ enum: ItemListSort })
  @IsOptional()
  @IsEnum(ItemListSort)
  sort?: ItemListSort;

  @ApiPropertyOptional({ maximum: 50, minimum: 1, type: 'integer' })
  @Transform(numberFromInput)
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @ApiPropertyOptional({ minimum: 0, type: 'integer' })
  @Transform(numberFromInput)
  @IsOptional()
  @IsInt()
  @Min(0)
  offset?: number;
}
