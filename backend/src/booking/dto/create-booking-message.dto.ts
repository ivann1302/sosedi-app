import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsUUID, Length } from 'class-validator';

function trimmedString({ value }: { value: unknown }): unknown {
  return typeof value === 'string' ? value.trim() : value;
}

export class CreateBookingMessageDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID('4')
  clientMessageId!: string;

  @ApiProperty({ maxLength: 2000, minLength: 1 })
  @Transform(trimmedString)
  @IsString()
  @Length(1, 2000)
  body!: string;
}
