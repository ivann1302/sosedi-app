import { ApiProperty } from '@nestjs/swagger';

export class UserBlockResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({
    type: 'object',
    properties: {
      id: { type: 'string', format: 'uuid' },
      name: { type: 'string', nullable: true },
    },
  })
  blocked!: {
    id: string;
    name: string | null;
  };

  @ApiProperty()
  createdAt!: Date;
}
