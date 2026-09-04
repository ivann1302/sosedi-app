import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DisputeStatus, FinancialDisputeReason } from '@prisma/client';

export class DisputeEvidenceResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  sha256: string;

  @ApiProperty()
  createdAt: Date;
}

export class DisputeEvidenceDownloadResponseDto {
  @ApiProperty({ format: 'uri' })
  downloadUrl: string;

  @ApiProperty({ example: 60 })
  expiresInSeconds: number;
}

export class DisputeResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  bookingId: string;

  @ApiProperty({ format: 'uuid' })
  openedById: string;

  @ApiProperty({ enum: FinancialDisputeReason })
  reason: FinancialDisputeReason;

  @ApiPropertyOptional({ nullable: true })
  description: string | null;

  @ApiProperty({ enum: DisputeStatus })
  status: DisputeStatus;

  @ApiProperty()
  openedAt: Date;

  @ApiPropertyOptional({ nullable: true })
  resolvedAt: Date | null;

  @ApiProperty({ type: [DisputeEvidenceResponseDto] })
  evidence: DisputeEvidenceResponseDto[];
}
