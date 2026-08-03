import { BadRequestException, ConflictException } from '@nestjs/common';
import { FakePaymentProvider } from './fake-payment.provider';

describe('FakePaymentProvider', () => {
  it('returns the same payment for an identical idempotent retry', () => {
    const provider = new FakePaymentProvider();
    const request = {
      idempotencyKey: 'booking-1-attempt-1',
      bookingId: 'booking-1',
      amountMinor: 12_345n,
      currency: 'RUB' as const,
    };

    const first = provider.createPayment(request);
    const retry = provider.createPayment(request);

    expect(retry).toBe(first);
    expect(first).toMatchObject({
      amountMinor: 12_345n,
      currency: 'RUB',
      status: 'PENDING',
    });
  });

  it('rejects reuse of an idempotency key with different parameters', () => {
    const provider = new FakePaymentProvider();
    provider.createPayment({
      idempotencyKey: 'attempt-1',
      bookingId: 'booking-1',
      amountMinor: 10_000n,
      currency: 'RUB',
    });

    expect(() =>
      provider.createPayment({
        idempotencyKey: 'attempt-1',
        bookingId: 'booking-1',
        amountMinor: 10_001n,
        currency: 'RUB',
      }),
    ).toThrow(ConflictException);
  });

  it('rejects zero or negative amounts', () => {
    const provider = new FakePaymentProvider();

    expect(() =>
      provider.createPayment({
        idempotencyKey: 'attempt-1',
        bookingId: 'booking-1',
        amountMinor: 0n,
        currency: 'RUB',
      }),
    ).toThrow(BadRequestException);
  });
});
