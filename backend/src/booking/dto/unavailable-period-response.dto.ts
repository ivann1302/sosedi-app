import { ApiProperty } from '@nestjs/swagger';

export class UnavailablePeriodResponseDto {
  @ApiProperty({ format: 'uuid' })
  id: string;

  @ApiProperty({ format: 'uuid' })
  itemId: string;

  @ApiProperty({ format: 'date' })
  startDate: Date;

  @ApiProperty({ format: 'date' })
  endDate: Date;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;
}
