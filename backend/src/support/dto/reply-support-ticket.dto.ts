import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length } from 'class-validator';

export class ReplySupportTicketDto {
  @ApiProperty({ minLength: 2, maxLength: 2000 })
  @IsString()
  @Length(2, 2000)
  message!: string;
}
