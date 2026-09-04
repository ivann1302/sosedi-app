import { ConflictException } from '@nestjs/common';
import { DepositOperationKind } from '@prisma/client';
import { FakeSafeDealProvider } from './fake-safe-deal.provider';

describe('FakeSafeDealProvider', () => {
  it('returns one stable checkout operation for an identical retry', async () => {
    const provider = new FakeSafeDealProvider();
    const request = {
      idempotencyKey: 'checkout-booking-1',
      bookingId: 'booking-1',
      amountMinor: 15_000n,
      currency: 'RUB' as const,
      outcome: 'SUCCESS' as const,
    };

    const first = await provider.checkout(request);
    const retry = await provider.checkout(request);

    expect(first).toEqual(retry);
    expect(first.outcome).toBe('SUCCEEDED');
    if (first.outcome !== 'SUCCEEDED') {
      throw new Error('Expected successful fake checkout');
    }
    expect(first.providerOperationId).toMatch(/^fake_checkout_[a-f0-9]{24}$/);
  });

  it('rejects conflicting reuse of a checkout idempotency key', async () => {
    const provider = new FakeSafeDealProvider();
    await provider.checkout({
      idempotencyKey: 'checkout-booking-1',
      bookingId: 'booking-1',
      amountMinor: 15_000n,
      currency: 'RUB',
      outcome: 'SUCCESS',
    });

    await expect(
      provider.checkout({
        idempotencyKey: 'checkout-booking-1',
        bookingId: 'booking-1',
        amountMinor: 15_001n,
        currency: 'RUB',
        outcome: 'SUCCESS',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it.each([
    ['SUCCESS', { outcome: 'SUCCEEDED' }],
    ['DECLINE', { outcome: 'DECLINED', errorCode: 'FAKE_DECLINED' }],
    ['TIMEOUT', { outcome: 'TIMEOUT' }],
  ] as const)(
    'returns deterministic checkout outcome %s',
    async (outcome, expected) => {
      const provider = new FakeSafeDealProvider();

      await expect(
        provider.checkout({
          idempotencyKey: `checkout-${outcome}`,
          bookingId: 'booking-1',
          amountMinor: 15_000n,
          currency: 'RUB',
          outcome,
        }),
      ).resolves.toMatchObject(expected);
    },
  );

  it.each([
    ['SUCCESS', { outcome: 'SUCCEEDED' }],
    ['DECLINE', { outcome: 'DECLINED', errorCode: 'FAKE_DECLINED' }],
    ['TIMEOUT', { outcome: 'TIMEOUT' }],
  ] as const)(
    'returns deterministic deposit operation outcome %s',
    async (outcome, expected) => {
      const provider = new FakeSafeDealProvider();

      await expect(
        provider.executeDepositOperation({
          idempotencyKey: `deposit-${outcome}`,
          depositId: 'deposit-1',
          kind: DepositOperationKind.HOLD,
          amountMinor: 5_000n,
          currency: 'RUB',
          outcome,
        }),
      ).resolves.toMatchObject(expected);
    },
  );
});
