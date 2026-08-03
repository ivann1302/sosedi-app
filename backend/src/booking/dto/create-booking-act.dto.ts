import { ApiProperty } from '@nestjs/swagger';
import { BookingActStage } from '@prisma/client';
import { IsEnum, IsUUID } from 'class-validator';

export class CreateBookingActDto {
  @ApiProperty({ enum: BookingActStage })
  @IsEnum(BookingActStage)
  stage: BookingActStage;

  @ApiProperty({ format: 'uuid' })
  @IsUUID('4')
  intentId: string;
}
