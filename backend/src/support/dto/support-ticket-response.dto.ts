import { ApiProperty } from '@nestjs/swagger';
import {
  BookingIssueReason,
  SupportTicketStatus,
  SupportTicketType,
} from '@prisma/client';

export class SupportTicketResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: SupportTicketType, enumName: 'SupportTicketType' })
  type!: SupportTicketType;

  @ApiProperty({ format: 'uuid', nullable: true })
  bookingId!: string | null;

  @ApiProperty({
    enum: BookingIssueReason,
    enumName: 'BookingIssueReason',
    nullable: true,
  })
  bookingIssueReason!: BookingIssueReason | null;

  @ApiProperty()
  subject!: string;

  @ApiProperty()
  message!: string;

  @ApiProperty({ enum: SupportTicketStatus, enumName: 'SupportTicketStatus' })
  status!: SupportTicketStatus;

  @ApiProperty({ nullable: true })
  adminResponse!: string | null;

  @ApiProperty({ nullable: true })
  respondedAt!: Date | null;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;
}
