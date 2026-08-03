import { OmitType, PartialType } from '@nestjs/swagger';
import { CreateItemDto } from './create-item.dto';

class MutableItemFieldsDto extends OmitType(CreateItemDto, [
  'ownershipConfirmed',
  'conditionConfirmed',
  'completenessConfirmed',
  'safetyAndMarketplaceRulesAccepted',
  'listingRulesVersion',
] as const) {}

export class UpdateItemDto extends PartialType(MutableItemFieldsDto) {}
