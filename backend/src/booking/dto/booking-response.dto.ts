import { ApiProperty } from '@nestjs/swagger';
import { BookingStatus } from '@prisma/client';

export class BookingResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  itemId: string;

  @ApiProperty({ format: 'uuid' })
  borrowerId: string;

  @ApiProperty({ format: 'uuid' })
  lenderId: string;

  @ApiProperty({ format: 'date' })
  startDate: Date;

  @ApiProperty({ format: 'date' })
  endDate: Date;

  @ApiProperty()
  days: number;

  @ApiProperty()
  totalAmount: number;

  @ApiProperty({ enum: BookingStatus })
  status: BookingStatus;

  @ApiProperty({ format: 'date-time', nullable: true, type: String })
  expiresAt: Date | null;

  @ApiProperty({ nullable: true, type: String })
  cancellationReason: string | null;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;
}
