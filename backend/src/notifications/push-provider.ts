import type { PushTokenProvider } from '@prisma/client';

export const PUSH_PROVIDER = Symbol('PUSH_PROVIDER');

export type PushMessage = Readonly<{
  token: string;
  eventId: string;
}>;

export enum PushDeliveryOutcome {
  DELIVERED = 'DELIVERED',
  INVALID_TOKEN = 'INVALID_TOKEN',
  RETRY = 'RETRY',
}

export interface PushProvider {
  send(
    provider: PushTokenProvider,
    message: PushMessage,
  ): Promise<PushDeliveryOutcome>;
}
