import { ApiProperty } from '@nestjs/swagger';
import {
  DepositOperationKind,
  DepositOperationStatus,
  DepositStatus,
  DisputeStatus,
  FinancialDisputeReason,
} from '@prisma/client';
import { DisputeEvidenceResponseDto } from './dispute-response.dto';

export class AdminFailedDepositOperationResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ enum: DepositOperationKind })
  kind: DepositOperationKind;

  @ApiProperty({ minimum: 0 })
  amountMinor: number;

  @ApiProperty({ enum: [DepositOperationStatus.FAILED] })
  status: 'FAILED';

  @ApiProperty({ type: String, nullable: true })
  errorCode: string | null;

  @ApiProperty({ minimum: 0 })
  attempts: number;

  @ApiProperty({ type: String, format: 'uuid', nullable: true })
  retryOfId: string | null;

  @ApiProperty({ type: String, format: 'uuid', nullable: true })
  retryId: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty({ type: Date, nullable: true })
  completedAt: Date | null;
}

export class AdminDisputeResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  bookingId: string;

  @ApiProperty({ enum: FinancialDisputeReason })
  reason: FinancialDisputeReason;

  @ApiProperty({ type: String, nullable: true })
  description: string | null;

  @ApiProperty({ enum: DisputeStatus })
  status: DisputeStatus;

  @ApiProperty({ minimum: 0 })
  refundToBorrowerMinor: number;

  @ApiProperty({ minimum: 0 })
  releaseToLenderMinor: number;

  @ApiProperty({ minimum: 0 })
  depositAmountMinor: number;

  @ApiProperty({ enum: DepositStatus })
  depositStatus: DepositStatus;

  @ApiProperty({ type: Date, nullable: true })
  disputeWindowEndsAt: Date | null;

  @ApiProperty()
  openedAt: Date;

  @ApiProperty({ type: Date, nullable: true })
  resolvedAt: Date | null;

  @ApiProperty({ type: [DisputeEvidenceResponseDto] })
  evidence: DisputeEvidenceResponseDto[];

  @ApiProperty({ type: [AdminFailedDepositOperationResponseDto] })
  failedOperations: AdminFailedDepositOperationResponseDto[];
}
