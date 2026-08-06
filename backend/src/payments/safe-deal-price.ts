import { BadRequestException } from '@nestjs/common';

const BASIS_POINTS_DENOMINATOR = 10_000n;
const HALF_BASIS_POINT_DENOMINATOR = BASIS_POINTS_DENOMINATOR / 2n;

export const PROVISIONAL_PLATFORM_FEE_BASIS_POINTS = 100n;

export type SafeDealPrice = {
  currency: 'RUB';
  rentalSubtotalMinor: bigint;
  borrowerTotalMinor: bigint;
  platformFeeMinor: bigint;
  ownerPayoutMinor: bigint;
};

export function calculateProvisionalSafeDealPrice(
  rentalSubtotalMinor: bigint,
): SafeDealPrice {
  if (rentalSubtotalMinor <= 0n) {
    throw new BadRequestException('Rental subtotal must be positive');
  }

  const platformFeeMinor =
    (rentalSubtotalMinor * PROVISIONAL_PLATFORM_FEE_BASIS_POINTS +
      HALF_BASIS_POINT_DENOMINATOR) /
    BASIS_POINTS_DENOMINATOR;
  const ownerPayoutMinor = rentalSubtotalMinor - platformFeeMinor;

  return {
    currency: 'RUB',
    rentalSubtotalMinor,
    borrowerTotalMinor: rentalSubtotalMinor,
    platformFeeMinor,
    ownerPayoutMinor,
  };
}
