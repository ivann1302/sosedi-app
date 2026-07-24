import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsUUID,
  Matches,
  Max,
  Min,
} from 'class-validator';

export enum ToolListSort {
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

export class ListToolsQueryDto {
  @IsOptional()
  @IsUUID('4')
  categoryId?: string;

  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  minPrice?: number;

  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  maxPrice?: number;

  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Дата начала аренды должна быть в формате YYYY-MM-DD',
  })
  @IsDateString({ strict: true, strictSeparator: true })
  availableFrom?: string;

  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Дата окончания аренды должна быть в формате YYYY-MM-DD',
  })
  @IsDateString({ strict: true, strictSeparator: true })
  availableTo?: string;

  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @Transform(numberFromInput)
  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(50)
  radiusKm?: number;

  @IsOptional()
  @IsEnum(ToolListSort)
  sort?: ToolListSort;

  @Transform(numberFromInput)
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @Transform(numberFromInput)
  @IsOptional()
  @IsInt()
  @Min(0)
  offset?: number;
}
