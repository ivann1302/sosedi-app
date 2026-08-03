import { ApiProperty } from '@nestjs/swagger';
import { BookingIssueReason } from '@prisma/client';
import { IsEnum, IsOptional, IsString, IsUUID, Length } from 'class-validator';

export class CreateSupportTicketDto {
  @ApiProperty({ format: 'uuid', required: false })
  @IsOptional()
  @IsUUID('4')
  bookingId?: string;

  @ApiProperty({
    enum: BookingIssueReason,
    enumName: 'BookingIssueReason',
    required: false,
  })
  @IsOptional()
  @IsEnum(BookingIssueReason)
  bookingIssueReason?: BookingIssueReason;

  @ApiProperty({
    example: 'Вопрос по передаче вещи',
    minLength: 3,
    maxLength: 120,
  })
  @IsString()
  @Length(3, 120)
  subject!: string;

  @ApiProperty({
    example: 'Не получается связаться со второй стороной.',
    minLength: 10,
    maxLength: 2000,
  })
  @IsString()
  @Length(10, 2000)
  message!: string;
}
