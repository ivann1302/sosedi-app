import { ApiProperty } from '@nestjs/swagger';
import { BookingActStage } from '@prisma/client';

export class BookingEvidenceResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty()
  sha256: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;
}

export class BookingReadinessResponseDto {
  @ApiProperty({ example: true })
  isWorking: boolean;

  @ApiProperty({ example: true })
  isComplete: boolean;

  @ApiProperty()
  visibleDefects: string;

  @ApiProperty({ format: 'date-time' })
  declaredAt: Date;

  @ApiProperty({ enum: ['LENDER_SELF_DECLARATION'] })
  declaration: 'LENDER_SELF_DECLARATION';
}

export class BookingActResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  bookingId: string;

  @ApiProperty({ format: 'uuid' })
  authorId: string;

  @ApiProperty({ enum: BookingActStage })
  stage: BookingActStage;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;

  @ApiProperty({ format: 'uuid', nullable: true, type: String })
  confirmedById: string | null;

  @ApiProperty({ format: 'date-time', nullable: true, type: String })
  confirmedAt: Date | null;

  @ApiProperty({ type: [BookingEvidenceResponseDto] })
  evidence: BookingEvidenceResponseDto[];

  @ApiProperty({
    type: BookingReadinessResponseDto,
    nullable: true,
    required: false,
  })
  readiness: BookingReadinessResponseDto | null;
}
