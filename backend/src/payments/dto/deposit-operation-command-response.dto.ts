import { ApiProperty } from '@nestjs/swagger';
import { DepositOperationKind, DepositOperationStatus } from '@prisma/client';

export class DepositOperationCommandResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  depositId: string;

  @ApiProperty({ enum: DepositOperationKind })
  kind: DepositOperationKind;

  @ApiProperty({ minimum: 0 })
  amountMinor: number;

  @ApiProperty({ enum: DepositOperationStatus })
  status: DepositOperationStatus;

  @ApiProperty({ type: String, format: 'uuid', nullable: true })
  retryOfId: string | null;
}
