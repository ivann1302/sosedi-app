import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type BookingMessageAuthor = 'SELF' | 'COUNTERPARTY' | 'SYSTEM';

export class BookingMessageResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ format: 'uuid' })
  bookingId!: string;

  @ApiProperty({ enum: ['SELF', 'COUNTERPARTY', 'SYSTEM'] })
  author!: BookingMessageAuthor;

  @ApiPropertyOptional({ format: 'uuid', nullable: true })
  clientMessageId!: string | null;

  @ApiProperty()
  body!: string;

  @ApiProperty()
  createdAt!: Date;
}

export class BookingMessagePageResponseDto {
  @ApiProperty({ type: [BookingMessageResponseDto] })
  items!: BookingMessageResponseDto[];

  @ApiPropertyOptional({ format: 'uuid', nullable: true })
  nextCursor!: string | null;
}

export class BookingMessageReadResponseDto {
  @ApiProperty()
  readAt!: Date;

  @ApiProperty()
  updatedCount!: number;
}
