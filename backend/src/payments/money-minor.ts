import { Prisma } from '@prisma/client';

export function decimalToMinor(value: Prisma.Decimal): bigint {
  const minor = value.times(100);
  if (!minor.isInteger()) {
    throw new RangeError('Money value must have whole kopecks');
  }

  return BigInt(minor.toFixed(0));
}

export function minorToDecimal(value: bigint): Prisma.Decimal {
  return new Prisma.Decimal(value.toString()).div(100);
}

export function minorToSafeNumber(value: bigint): number {
  const result = Number(value);
  if (!Number.isSafeInteger(result)) {
    throw new RangeError('Minor-unit value exceeds the safe integer range');
  }

  return result;
}

export function assertResolutionTotal(
  depositMinor: bigint,
  refundMinor: bigint,
  releaseMinor: bigint,
): void {
  if (depositMinor < 0n || refundMinor < 0n || releaseMinor < 0n) {
    throw new RangeError('Deposit resolution amounts must be non-negative');
  }
  if (refundMinor + releaseMinor !== depositMinor) {
    throw new RangeError('Deposit resolution must equal the deposit amount');
  }
}
