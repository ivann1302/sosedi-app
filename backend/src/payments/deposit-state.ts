export type DepositStatusValue =
  | 'PENDING'
  | 'HELD'
  | 'DISPUTED'
  | 'RESOLVING'
  | 'RESOLVED'
  | 'CANCELLED';

const ALLOWED_TRANSITIONS: Readonly<
  Record<DepositStatusValue, readonly DepositStatusValue[]>
> = {
  PENDING: ['HELD', 'CANCELLED'],
  HELD: ['DISPUTED', 'RESOLVING'],
  DISPUTED: ['RESOLVING'],
  RESOLVING: ['RESOLVED'],
  RESOLVED: [],
  CANCELLED: [],
};

export function assertDepositTransition(
  current: DepositStatusValue,
  next: DepositStatusValue,
): void {
  if (!ALLOWED_TRANSITIONS[current].includes(next)) {
    throw new Error(`Illegal deposit transition: ${current} -> ${next}`);
  }
}
