import { Transform } from 'class-transformer';
import {
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

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

export class CreateToolDto {
  @IsUUID('4')
  categoryId: string;

  @Transform(trimString)
  @IsString()
  @MinLength(3)
  @MaxLength(120)
  title: string;

  @Transform(trimString)
  @IsString()
  @MinLength(10)
  @MaxLength(4000)
  description: string;

  @Transform(numberFromInput)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(1)
  @Max(1_000_000)
  pricePerDay: number;

  @Transform(nullableNumberFromInput)
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(1_000_000)
  depositAmount?: number | null;

  @Transform(trimString)
  @IsString()
  @MinLength(5)
  @MaxLength(300)
  address: string;

  @Transform(numberFromInput)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @Transform(numberFromInput)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;
}
