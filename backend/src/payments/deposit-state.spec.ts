import { assertDepositTransition } from './deposit-state';

describe('assertDepositTransition', () => {
  it.each([
    ['PENDING', 'HELD'],
    ['PENDING', 'CANCELLED'],
    ['HELD', 'DISPUTED'],
    ['HELD', 'RESOLVING'],
    ['DISPUTED', 'RESOLVING'],
    ['RESOLVING', 'RESOLVED'],
  ] as const)('allows %s -> %s', (current, next) => {
    expect(() => assertDepositTransition(current, next)).not.toThrow();
  });

  it.each([
    ['PENDING', 'RESOLVED'],
    ['RESOLVED', 'HELD'],
    ['CANCELLED', 'PENDING'],
  ] as const)('rejects %s -> %s', (current, next) => {
    expect(() => assertDepositTransition(current, next)).toThrow(
      `Illegal deposit transition: ${current} -> ${next}`,
    );
  });
});
