import { Controller, Get } from '@nestjs/common';
import {
  ApiExtraModels,
  ApiOkResponse,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { ok, type ApiResponse } from '../common/http/api-response';
import {
  MarketplacePolicyDepositResponseDto,
  MarketplacePolicyResponseDto,
} from './dto/marketplace-policy-response.dto';
import {
  PaymentPolicyService,
  type MarketplacePolicy,
} from './payment-policy.service';

@ApiTags('marketplace-policy')
@ApiExtraModels(
  MarketplacePolicyResponseDto,
  MarketplacePolicyDepositResponseDto,
)
@Controller('marketplace-policy')
export class MarketplacePolicyController {
  constructor(private readonly paymentPolicy: PaymentPolicyService) {}

  @ApiOkResponse({
    schema: {
      type: 'object',
      required: ['success', 'data', 'error'],
      properties: {
        success: { type: 'boolean', example: true },
        data: { $ref: getSchemaPath(MarketplacePolicyResponseDto) },
        error: { type: 'object', nullable: true, example: null },
      },
    },
  })
  @Get()
  current(): ApiResponse<MarketplacePolicy> {
    return ok(this.paymentPolicy.current());
  }
}
