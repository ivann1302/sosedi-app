import { ApiProperty } from '@nestjs/swagger';

export class ItemAvailabilityResponseDto {
  @ApiProperty()
  available: boolean;
}
