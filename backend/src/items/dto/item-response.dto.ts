import { ApiProperty } from '@nestjs/swagger';
import { ItemCondition, ItemStatus } from '@prisma/client';

export enum DistanceBucket {
  UNDER_1_KM = 'UNDER_1_KM',
  FROM_1_TO_3_KM = 'FROM_1_TO_3_KM',
  FROM_3_TO_5_KM = 'FROM_3_TO_5_KM',
  FROM_5_TO_10_KM = 'FROM_5_TO_10_KM',
  FROM_10_TO_25_KM = 'FROM_10_TO_25_KM',
  FROM_25_TO_50_KM = 'FROM_25_TO_50_KM',
  OVER_50_KM = 'OVER_50_KM',
}

export enum PublicLocationPrecision {
  SPARSE = 'SPARSE',
}

export class ItemCategoryResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  slug: string;

  @ApiProperty({ nullable: true, type: String })
  iconName: string | null;

  @ApiProperty()
  safetyNotice: string;
}

export class ItemOwnerSummaryResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ nullable: true, type: String })
  name: string | null;

  @ApiProperty({ nullable: true, type: String })
  city: string | null;

  @ApiProperty({ nullable: true, type: String })
  avatarUrl: string | null;
}

export class PublicItemPhotoResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ nullable: true, type: String })
  thumbnailUrl: string | null;

  @ApiProperty({ nullable: true, type: String })
  previewUrl: string | null;

  @ApiProperty()
  sortOrder: number;

  @ApiProperty()
  isCover: boolean;

  @ApiProperty({ format: 'date-time', type: String })
  createdAt: Date;
}

export class PrivateItemPhotoResponseDto extends PublicItemPhotoResponseDto {
  @ApiProperty({ nullable: true, type: String })
  originalUrl: string | null;
}

export class ApproximateLocationResponseDto {
  @ApiProperty({ example: 55.75 })
  latitude: number;

  @ApiProperty({ example: 37.65 })
  longitude: number;

  @ApiProperty({ enum: PublicLocationPrecision })
  precision: PublicLocationPrecision;
}

class ItemResponseBaseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  description: string;

  @ApiProperty({ enum: ItemCondition })
  condition: ItemCondition;

  @ApiProperty()
  completeness: string;

  @ApiProperty()
  handoverTerms: string;

  @ApiProperty()
  pricePerDay: number;

  @ApiProperty({ nullable: true, type: Number })
  depositAmount: number | null;

  @ApiProperty({ type: ItemCategoryResponseDto })
  category: ItemCategoryResponseDto;

  @ApiProperty({ type: ItemOwnerSummaryResponseDto })
  owner: ItemOwnerSummaryResponseDto;

  @ApiProperty({ format: 'date-time', type: String })
  createdAt: Date;

  @ApiProperty({ format: 'date-time', type: String })
  updatedAt: Date;
}

export class PublicItemResponseDto extends ItemResponseBaseDto {
  @ApiProperty({
    description: 'Проверенный модерацией район или округ без pickup-адреса',
  })
  area: string;

  @ApiProperty({ type: ApproximateLocationResponseDto })
  approximateLocation: ApproximateLocationResponseDto;

  @ApiProperty({ enum: DistanceBucket, nullable: true })
  distanceBucket: DistanceBucket | null;

  @ApiProperty({ type: [PublicItemPhotoResponseDto] })
  photos: PublicItemPhotoResponseDto[];
}

export class PrivateItemResponseDto extends ItemResponseBaseDto {
  @ApiProperty({ enum: ItemStatus })
  status: ItemStatus;

  @ApiProperty({ nullable: true, type: String })
  rejectReason: string | null;

  @ApiProperty()
  publicArea: string;

  @ApiProperty()
  address: string;

  @ApiProperty()
  latitude: number;

  @ApiProperty()
  longitude: number;

  @ApiProperty({ type: [PrivateItemPhotoResponseDto] })
  photos: PrivateItemPhotoResponseDto[];
}
