import { Injectable } from '@nestjs/common';
import { PushDeliveryOutcome, type PushProvider } from './push-provider';

@Injectable()
export class DisabledPushProvider implements PushProvider {
  send(): Promise<PushDeliveryOutcome> {
    return Promise.resolve(PushDeliveryOutcome.RETRY);
  }
}
