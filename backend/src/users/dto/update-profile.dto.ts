import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength } from 'class-validator';

function emptyStringToNull({ value }: { value: unknown }): unknown {
  if (typeof value !== 'string') {
    return value;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export class UpdateProfileDto {
  @Transform(emptyStringToNull)
  @IsOptional()
  @IsString()
  @MaxLength(80)
  name?: string | null;

  @Transform(emptyStringToNull)
  @IsOptional()
  @IsString()
  @MaxLength(80)
  city?: string | null;
}
