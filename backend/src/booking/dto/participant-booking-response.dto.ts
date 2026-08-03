import { ApiProperty } from '@nestjs/swagger';
import { BookingStatus } from '@prisma/client';

export class BookingTermsResponseDto {
  @ApiProperty()
  itemTitle: string;

  @ApiProperty({ nullable: true, type: String })
  lenderDisplayName: string | null;

  @ApiProperty()
  pricePerDay: number;

  @ApiProperty()
  days: number;

  @ApiProperty()
  rentalSubtotal: number;

  @ApiProperty({ nullable: true, type: Number })
  depositAmount: number | null;

  @ApiProperty()
  platformFee: number;

  @ApiProperty()
  ownerPayout: number;

  @ApiProperty()
  total: number;

  @ApiProperty({ enum: ['RUB'] })
  currency: 'RUB';

  @ApiProperty({ enum: ['PAY_ON_HANDOVER'] })
  paymentScenario: 'PAY_ON_HANDOVER';

  @ApiProperty()
  listingVersion: string;

  @ApiProperty({ nullable: true, type: String })
  offerVersion: string | null;

  @ApiProperty({ nullable: true, type: String })
  cancellationPolicyVersion: string | null;
}

export class BookingHandoverResponseDto {
  @ApiProperty()
  area: string;

  @ApiProperty()
  address: string;

  @ApiProperty()
  latitude: number;

  @ApiProperty()
  longitude: number;
}

export class ParticipantBookingResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  itemId: string;

  @ApiProperty({ enum: ['BORROWER', 'LENDER'] })
  actorRole: 'BORROWER' | 'LENDER';

  @ApiProperty({ format: 'date' })
  startDate: Date;

  @ApiProperty({ format: 'date' })
  endDate: Date;

  @ApiProperty({ enum: BookingStatus })
  status: BookingStatus;

  @ApiProperty({ format: 'date-time', nullable: true, type: String })
  expiresAt: Date | null;

  @ApiProperty({ nullable: true, type: String })
  cancellationReason: string | null;

  @ApiProperty({ nullable: true, type: BookingTermsResponseDto })
  terms: BookingTermsResponseDto | null;

  @ApiProperty({ nullable: true, type: BookingHandoverResponseDto })
  handover: BookingHandoverResponseDto | null;

  @ApiProperty({ nullable: true, type: String })
  counterpartyContact: string | null;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;
}
