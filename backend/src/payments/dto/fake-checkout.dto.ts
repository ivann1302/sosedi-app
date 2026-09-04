import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';

export enum FakeCheckoutOutcome {
  SUCCESS = 'SUCCESS',
  DECLINE = 'DECLINE',
  TIMEOUT = 'TIMEOUT',
}

export class FakeCheckoutDto {
  @ApiProperty({ enum: FakeCheckoutOutcome })
  @IsEnum(FakeCheckoutOutcome)
  outcome: FakeCheckoutOutcome;
}
