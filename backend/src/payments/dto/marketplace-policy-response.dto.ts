import { ApiProperty } from '@nestjs/swagger';
import { PaymentScenario } from '../payment-policy.service';

export class MarketplacePolicyDepositResponseDto {
  @ApiProperty({ example: true })
  enabled: boolean;

  @ApiProperty({ enum: ['RUB'] })
  currency: 'RUB';

  @ApiProperty({ example: 10_000_000, nullable: true })
  maximumMinor: number | null;

  @ApiProperty({ example: 'fake-deposit-2026-09-02', nullable: true })
  policyVersion: string | null;

  @ApiProperty({ example: 300, nullable: true })
  disputeWindowSeconds: number | null;
}

export class MarketplacePolicyResponseDto {
  @ApiProperty({ enum: PaymentScenario })
  paymentScenario: PaymentScenario;

  @ApiProperty({ type: MarketplacePolicyDepositResponseDto })
  deposit: MarketplacePolicyDepositResponseDto;
}
