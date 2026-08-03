import {
  PushDeliveryOutcome,
  type PushMessage,
  type PushProvider,
} from './push-provider';
import { PushTokenProvider } from '@prisma/client';

class FakePushProvider implements PushProvider {
  readonly messages: PushMessage[] = [];

  send(
    _provider: PushTokenProvider,
    message: PushMessage,
  ): Promise<PushDeliveryOutcome> {
    this.messages.push(message);
    return Promise.resolve(PushDeliveryOutcome.DELIVERED);
  }
}

describe('PushProvider', () => {
  it('accepts only a token and opaque eventId in its message contract', async () => {
    const provider = new FakePushProvider();
    const message: PushMessage = {
      token: 'test-device-token',
      eventId: '9df957f9-b014-4547-a083-cab9b9892351',
    };

    await expect(provider.send(PushTokenProvider.FCM, message)).resolves.toBe(
      PushDeliveryOutcome.DELIVERED,
    );
    expect(provider.messages).toEqual([message]);
    expect(Object.keys(provider.messages[0])).toEqual(['token', 'eventId']);
  });
});
