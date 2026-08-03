import { ApiProperty } from '@nestjs/swagger';
import {
  BOOKING_STATUSES,
  DISPUTE_STATUSES,
  PAYMENT_STATUSES,
  PAYOUT_STATUSES,
} from './workflow-contract';

export class BookingStatusDto {
  @ApiProperty({ enum: BOOKING_STATUSES, enumName: 'BookingStatus' })
  status: (typeof BOOKING_STATUSES)[number];
}

export class PaymentStatusDto {
  @ApiProperty({ enum: PAYMENT_STATUSES, enumName: 'PaymentStatus' })
  status: (typeof PAYMENT_STATUSES)[number];
}

export class PayoutStatusDto {
  @ApiProperty({ enum: PAYOUT_STATUSES, enumName: 'PayoutStatus' })
  status: (typeof PAYOUT_STATUSES)[number];
}

export class DisputeStatusDto {
  @ApiProperty({ enum: DISPUTE_STATUSES, enumName: 'DisputeStatus' })
  status: (typeof DISPUTE_STATUSES)[number];
}
