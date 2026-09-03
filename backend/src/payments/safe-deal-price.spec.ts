import { BadRequestException } from '@nestjs/common';
import { calculateProvisionalSafeDealPrice } from './safe-deal-price';

describe('calculateProvisionalSafeDealPrice', () => {
  it('deducts a provisional 1% platform fee from the owner payout', () => {
    const price = calculateProvisionalSafeDealPrice(12_345n, 0n);

    expect(price).toEqual({
      currency: 'RUB',
      rentalSubtotalMinor: 12_345n,
      depositMinor: 0n,
      borrowerTotalMinor: 12_345n,
      platformFeeMinor: 123n,
      ownerPayoutMinor: 12_222n,
    });
    expect(price.ownerPayoutMinor + price.platformFeeMinor).toBe(
      price.borrowerTotalMinor,
    );
  });

  it('keeps the deposit outside the platform fee and normal owner payout', () => {
    const price = calculateProvisionalSafeDealPrice(10_000n, 5_000n);

    expect(price).toEqual({
      currency: 'RUB',
      rentalSubtotalMinor: 10_000n,
      depositMinor: 5_000n,
      borrowerTotalMinor: 15_000n,
      platformFeeMinor: 100n,
      ownerPayoutMinor: 9_900n,
    });
    expect(price.ownerPayoutMinor + price.platformFeeMinor).toBe(
      price.rentalSubtotalMinor,
    );
  });

  it('rounds the fee to the nearest kopeck, with half a kopeck upward', () => {
    expect(calculateProvisionalSafeDealPrice(150n, 0n).platformFeeMinor).toBe(
      2n,
    );
  });

  it('rejects a non-positive subtotal', () => {
    expect(() => calculateProvisionalSafeDealPrice(0n, 0n)).toThrow(
      BadRequestException,
    );
  });

  it('rejects a negative deposit', () => {
    expect(() => calculateProvisionalSafeDealPrice(1_000n, -1n)).toThrow(
      BadRequestException,
    );
  });
});
