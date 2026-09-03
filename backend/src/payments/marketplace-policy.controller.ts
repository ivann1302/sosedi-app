import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { ok, type ApiResponse } from '../common/http/api-response';
import { MarketplacePolicyResponseDto } from './dto/marketplace-policy-response.dto';
import {
  PaymentPolicyService,
  type MarketplacePolicy,
} from './payment-policy.service';

@ApiTags('marketplace-policy')
@Controller('marketplace-policy')
export class MarketplacePolicyController {
  constructor(private readonly paymentPolicy: PaymentPolicyService) {}

  @ApiOkResponse({ type: MarketplacePolicyResponseDto })
  @Get()
  current(): ApiResponse<MarketplacePolicy> {
    return ok(this.paymentPolicy.current());
  }
}
