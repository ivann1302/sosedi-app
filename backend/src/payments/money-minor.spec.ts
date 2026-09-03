import { Prisma } from '@prisma/client';
import {
  assertResolutionTotal,
  decimalToMinor,
  minorToDecimal,
  minorToSafeNumber,
} from './money-minor';

describe('minor-unit money helpers', () => {
  it('converts Decimal 10.01 to 1001 kopecks and back exactly', () => {
    expect(decimalToMinor(new Prisma.Decimal('10.01'))).toBe(1001n);
    expect(minorToDecimal(1001n).toString()).toBe('10.01');
  });

  it('rejects a Decimal containing a fractional kopeck', () => {
    expect(() => decimalToMinor(new Prisma.Decimal('10.001'))).toThrow(
      'Money value must have whole kopecks',
    );
  });

  it('rejects a minor-unit value that is unsafe in JSON numbers', () => {
    expect(() =>
      minorToSafeNumber(BigInt(Number.MAX_SAFE_INTEGER) + 1n),
    ).toThrow('Minor-unit value exceeds the safe integer range');
  });

  it('requires refund and lender release to equal the original deposit', () => {
    expect(() => assertResolutionTotal(5_000n, 2_000n, 3_000n)).not.toThrow();
    expect(() => assertResolutionTotal(5_000n, 2_000n, 2_999n)).toThrow(
      'Deposit resolution must equal the deposit amount',
    );
  });

  it('rejects negative resolution amounts', () => {
    expect(() => assertResolutionTotal(5_000n, -1n, 5_001n)).toThrow(
      'Deposit resolution amounts must be non-negative',
    );
  });
});
