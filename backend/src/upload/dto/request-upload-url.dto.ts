import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { MAX_UPLOAD_SIZE_BYTES } from '../upload.constants';
import { UploadPurpose } from '../upload.types';

export class RequestUploadUrlDto {
  @ApiProperty({ enum: UploadPurpose })
  @IsEnum(UploadPurpose)
  purpose: UploadPurpose;

  @ApiProperty({ example: 'perforator.jpg' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(180)
  fileName: string;

  @ApiProperty({ example: 'image/jpeg' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  contentType: string;

  @ApiProperty({ example: 1048576, maximum: MAX_UPLOAD_SIZE_BYTES })
  @IsInt()
  @Min(1)
  @Max(MAX_UPLOAD_SIZE_BYTES)
  sizeBytes: number;

  @ApiPropertyOptional({ description: 'Обязательно для фото инструмента' })
  @IsOptional()
  @IsUUID()
  toolId?: string;
}
