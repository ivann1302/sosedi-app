import { ApiProperty } from '@nestjs/swagger';
import { ReviewAuthorRole } from '@prisma/client';

export class ParticipantReviewResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['SELF', 'COUNTERPARTY'] })
  author!: 'SELF' | 'COUNTERPARTY';

  @ApiProperty({ minimum: 1, maximum: 5 })
  rating!: number;

  @ApiProperty({ nullable: true })
  text!: string | null;

  published!: boolean;
  hidden!: boolean;
  publishAt!: Date;
  createdAt!: Date;
}

export class PublicReviewResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ReviewAuthorRole })
  authorRole!: ReviewAuthorRole;

  @ApiProperty({ minimum: 1, maximum: 5 })
  rating!: number;

  @ApiProperty({ nullable: true })
  text!: string | null;

  verifiedRental!: true;
  publishedAt!: Date;
  createdAt!: Date;
}

export class PublicReviewPageResponseDto {
  summary!: { average: number | null; count: number };
  items!: PublicReviewResponseDto[];

  @ApiProperty({ format: 'uuid', nullable: true })
  nextCursor!: string | null;
}
