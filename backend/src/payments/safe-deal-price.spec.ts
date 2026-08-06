import { BadRequestException } from '@nestjs/common';
import { calculateProvisionalSafeDealPrice } from './safe-deal-price';

describe('calculateProvisionalSafeDealPrice', () => {
  it('deducts a provisional 1% platform fee from the owner payout', () => {
    const price = calculateProvisionalSafeDealPrice(12_345n);

    expect(price).toEqual({
      currency: 'RUB',
      rentalSubtotalMinor: 12_345n,
      borrowerTotalMinor: 12_345n,
      platformFeeMinor: 123n,
      ownerPayoutMinor: 12_222n,
    });
    expect(price.ownerPayoutMinor + price.platformFeeMinor).toBe(
      price.borrowerTotalMinor,
    );
  });

  it('rounds the fee to the nearest kopeck, with half a kopeck upward', () => {
    expect(calculateProvisionalSafeDealPrice(150n).platformFeeMinor).toBe(2n);
  });

  it('rejects a non-positive subtotal', () => {
    expect(() => calculateProvisionalSafeDealPrice(0n)).toThrow(
      BadRequestException,
    );
  });
});
