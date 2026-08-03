import { PushDeliveryStatus, PushTokenProvider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PushDeliveryProcessor } from './push-delivery.processor';
import {
  PushDeliveryOutcome,
  type PushMessage,
  type PushProvider,
} from './push-provider';

class FakePushProvider implements PushProvider {
  readonly send = jest.fn<
    Promise<PushDeliveryOutcome>,
    [PushTokenProvider, PushMessage]
  >();
}

describe('PushDeliveryProcessor', () => {
  const now = new Date('2026-07-29T12:00:00.000Z');

  function createProcessor(outcome: PushDeliveryOutcome) {
    const pushProvider = new FakePushProvider();
    pushProvider.send.mockResolvedValue(outcome);
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const deleteMany = jest.fn().mockResolvedValue({ count: 1 });
    const findMany = jest.fn().mockResolvedValue([{ id: 'delivery-1' }]);
    const prisma = {
      pushDelivery: {
        findMany,
        updateMany,
        findUnique: jest.fn().mockResolvedValue({
          id: 'delivery-1',
          eventId: '9df957f9-b014-4547-a083-cab9b9892351',
          attempts: 0,
          token: {
            id: 'token-1',
            provider: PushTokenProvider.FCM,
            token: 'device-token',
          },
        }),
      },
      devicePushToken: { deleteMany },
    };
    return {
      processor: new PushDeliveryProcessor(
        prisma as unknown as PrismaService,
        pushProvider,
      ),
      pushProvider,
      updateMany,
      deleteMany,
      findMany,
    };
  }

  it('delivers only token and opaque eventId then marks the task delivered', async () => {
    const { processor, pushProvider, updateMany } = createProcessor(
      PushDeliveryOutcome.DELIVERED,
    );

    await expect(processor.processPending(now)).resolves.toBe(1);
    expect(pushProvider.send).toHaveBeenCalledWith(PushTokenProvider.FCM, {
      token: 'device-token',
      eventId: '9df957f9-b014-4547-a083-cab9b9892351',
    });
    expect(updateMany).toHaveBeenLastCalledWith({
      where: {
        id: 'delivery-1',
        status: PushDeliveryStatus.PROCESSING,
      },
      data: expect.objectContaining({
        status: PushDeliveryStatus.DELIVERED,
        deliveredAt: now,
        lastErrorCode: null,
      }) as object,
    });
  });

  it('deletes an invalid token so later events cannot target it', async () => {
    const { processor, deleteMany } = createProcessor(
      PushDeliveryOutcome.INVALID_TOKEN,
    );

    await expect(processor.processPending(now)).resolves.toBe(1);
    expect(deleteMany).toHaveBeenCalledWith({
      where: { id: 'token-1', token: 'device-token' },
    });
  });

  it('retries a transient provider failure with bounded backoff', async () => {
    const { processor, updateMany } = createProcessor(
      PushDeliveryOutcome.RETRY,
    );

    await expect(processor.processPending(now)).resolves.toBe(1);
    expect(updateMany).toHaveBeenLastCalledWith({
      where: {
        id: 'delivery-1',
        status: PushDeliveryStatus.PROCESSING,
      },
      data: expect.objectContaining({
        status: PushDeliveryStatus.RETRY,
        attempts: { increment: 1 },
        nextAttemptAt: new Date('2026-07-29T12:00:30.000Z'),
        lastErrorCode: 'PROVIDER_RETRY',
      }) as object,
    });
  });

  it('retries a thrown provider outage once and does not redeliver after recovery', async () => {
    const { processor, pushProvider, updateMany, findMany } = createProcessor(
      PushDeliveryOutcome.DELIVERED,
    );
    pushProvider.send.mockRejectedValueOnce(
      new Error('provider topology details'),
    );

    await expect(processor.processPending(now)).resolves.toBe(1);
    expect(updateMany).toHaveBeenLastCalledWith({
      where: {
        id: 'delivery-1',
        status: PushDeliveryStatus.PROCESSING,
      },
      data: expect.objectContaining({
        status: PushDeliveryStatus.RETRY,
        attempts: { increment: 1 },
        nextAttemptAt: new Date('2026-07-29T12:00:30.000Z'),
        lastErrorCode: 'PROVIDER_ERROR',
      }) as object,
    });

    const recoveredAt = new Date('2026-07-29T12:00:30.000Z');
    await expect(processor.processPending(recoveredAt)).resolves.toBe(1);
    expect(pushProvider.send).toHaveBeenCalledTimes(2);
    expect(updateMany).toHaveBeenLastCalledWith({
      where: {
        id: 'delivery-1',
        status: PushDeliveryStatus.PROCESSING,
      },
      data: expect.objectContaining({
        status: PushDeliveryStatus.DELIVERED,
        deliveredAt: recoveredAt,
        lastErrorCode: null,
      }) as object,
    });

    findMany.mockResolvedValue([]);
    await expect(
      processor.processPending(new Date('2026-07-29T12:01:00.000Z')),
    ).resolves.toBe(0);
    expect(pushProvider.send).toHaveBeenCalledTimes(2);
  });
});
