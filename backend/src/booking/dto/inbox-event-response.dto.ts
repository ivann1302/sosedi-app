import { ApiProperty } from '@nestjs/swagger';
import { BookingStatus } from '@prisma/client';

export class InboxEventResponseDto {
  @ApiProperty({ format: 'uuid' })
  eventId: string;

  @ApiProperty({ format: 'uuid', nullable: true })
  bookingId: string | null;

  @ApiProperty({ format: 'uuid', nullable: true })
  supportTicketId: string | null;

  @ApiProperty({ format: 'uuid', nullable: true })
  itemId: string | null;

  @ApiProperty()
  eventType: string;

  @ApiProperty({ format: 'date-time', nullable: true, type: String })
  readAt: Date | null;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;
}

export class InboxBookingDetailsDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  itemId: string;

  @ApiProperty({ format: 'date' })
  startDate: Date;

  @ApiProperty({ format: 'date' })
  endDate: Date;

  @ApiProperty()
  totalAmount: number;

  @ApiProperty({ enum: BookingStatus })
  status: BookingStatus;

  @ApiProperty({ format: 'date-time', nullable: true, type: String })
  expiresAt: Date | null;

  @ApiProperty({ nullable: true, type: String })
  cancellationReason: string | null;
}

export class InboxEventDetailsResponseDto extends InboxEventResponseDto {
  @ApiProperty({ type: InboxBookingDetailsDto, nullable: true })
  booking: InboxBookingDetailsDto | null;

  @ApiProperty({
    nullable: true,
    type: 'object',
    properties: {
      id: { type: 'string', format: 'uuid' },
      subject: { type: 'string' },
      status: { type: 'string' },
      updatedAt: { type: 'string', format: 'date-time' },
    },
  })
  supportTicket: {
    id: string;
    subject: string;
    status: string;
    updatedAt: Date;
  } | null;
}
