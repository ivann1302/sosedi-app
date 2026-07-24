import { Transform } from 'class-transformer';
import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

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

  @Transform(emptyStringToNull)
  @IsOptional()
  @IsUrl({ require_protocol: true }, { message: 'Аватар должен быть URL' })
  @MaxLength(500)
  avatarUrl?: string | null;
}
