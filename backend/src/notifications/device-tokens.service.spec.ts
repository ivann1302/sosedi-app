import { Prisma, PushPlatform, PushTokenProvider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DeviceTokensService } from './device-tokens.service';

const installationId = '11111111-1111-4111-8111-111111111111';
const request = {
  provider: PushTokenProvider.FCM,
  platform: PushPlatform.ANDROID,
  token: 'device-token-value',
};
const response = {
  id: 'token-1',
  installationId,
  provider: PushTokenProvider.FCM,
  platform: PushPlatform.ANDROID,
  updatedAt: new Date('2026-07-29T12:00:00.000Z'),
};

function prismaError(code: string): Prisma.PrismaClientKnownRequestError {
  return new Prisma.PrismaClientKnownRequestError('test error', {
    code,
    clientVersion: 'test',
  });
}

describe('DeviceTokensService', () => {
  it('retries a serializable write conflict and returns the token', async () => {
    const transaction = jest
      .fn()
      .mockRejectedValueOnce(prismaError('P2034'))
      .mockResolvedValueOnce(response);
    const service = new DeviceTokensService({
      $transaction: transaction,
    } as unknown as PrismaService);

    await expect(
      service.register('user-1', installationId, request),
    ).resolves.toEqual(response);
    expect(transaction).toHaveBeenCalledTimes(2);
  });

  it('stops after three serializable write conflicts', async () => {
    const error = prismaError('P2034');
    const transaction = jest.fn().mockRejectedValue(error);
    const service = new DeviceTokensService({
      $transaction: transaction,
    } as unknown as PrismaService);

    await expect(
      service.register('user-1', installationId, request),
    ).rejects.toBe(error);
    expect(transaction).toHaveBeenCalledTimes(3);
  });

  it('does not retry a non-retryable Prisma error', async () => {
    const error = prismaError('P2002');
    const transaction = jest.fn().mockRejectedValue(error);
    const service = new DeviceTokensService({
      $transaction: transaction,
    } as unknown as PrismaService);

    await expect(
      service.register('user-1', installationId, request),
    ).rejects.toBe(error);
    expect(transaction).toHaveBeenCalledTimes(1);
  });
});
