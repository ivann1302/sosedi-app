import { ApiProperty } from '@nestjs/swagger';

export class SupportAttachmentResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  sha256!: string;

  @ApiProperty()
  createdAt!: Date;
}

export class SupportMessageResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['USER', 'SUPPORT'] })
  authorRole!: 'USER' | 'SUPPORT';

  @ApiProperty()
  body!: string;

  @ApiProperty({ type: [SupportAttachmentResponseDto] })
  attachments!: SupportAttachmentResponseDto[];

  @ApiProperty()
  createdAt!: Date;
}
