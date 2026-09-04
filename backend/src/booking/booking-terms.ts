import { Prisma } from '@prisma/client';

export type BookingMoneyMinor = {
  pricePerDay: number;
  rentalSubtotal: number;
  deposit: number;
  platformFee: number;
  ownerPayout: number;
  total: number;
};

export type DepositTerms = {
  policyVersion: string;
  disputeWindowSeconds: number;
} | null;

export type BookingTermsSnapshot = {
  itemTitle: string;
  lenderId: string;
  lenderDisplayName: string | null;
  pricePerDay: number;
  days: number;
  rentalSubtotal: number;
  depositAmount: number | null;
  platformFee: number;
  ownerPayout: number;
  total: number;
  currency: 'RUB';
  paymentScenario: 'PAY_ON_HANDOVER' | 'FAKE_SAFE_DEAL';
  moneyMinor: BookingMoneyMinor;
  depositTerms: DepositTerms;
  handover: {
    area: string;
    address: string;
    latitude: number;
    longitude: number;
  };
  listingVersion: string;
  offerVersion: string | null;
  cancellationPolicyVersion: string | null;
  acceptance: {
    actorId: string;
    acceptedAt: string;
    method: 'BOOKING_SUBMIT_CHECKBOX';
    offerVersion: string;
    cancellationPolicyVersion: string;
  } | null;
};

export function toSnapshotJson(
  snapshot: BookingTermsSnapshot,
): Prisma.InputJsonValue {
  return snapshot;
}

export function readBookingTermsSnapshot(
  value: Prisma.JsonValue | null,
): BookingTermsSnapshot | null {
  if (!isJsonRecord(value) || !isJsonRecord(value.handover)) {
    return null;
  }
  const handover = value.handover;
  const acceptance = isJsonRecord(value.acceptance) ? value.acceptance : null;
  const pricePerDay = minorUnits(value.pricePerDay);
  const rentalSubtotal = minorUnits(value.rentalSubtotal);
  const depositAmount =
    value.depositAmount === null ? 0 : minorUnits(value.depositAmount);
  const platformFee = minorUnits(value.platformFee);
  const ownerPayout = minorUnits(value.ownerPayout);
  const total = minorUnits(value.total);
  const paymentScenario =
    value.paymentScenario === 'PAY_ON_HANDOVER' ||
    value.paymentScenario === 'FAKE_SAFE_DEAL'
      ? value.paymentScenario
      : null;
  const isOffline = paymentScenario === 'PAY_ON_HANDOVER';
  const suppliedMoney = isJsonRecord(value.moneyMinor)
    ? readMoneyMinor(value.moneyMinor)
    : null;
  const moneyMinor =
    suppliedMoney ??
    (isOffline &&
    pricePerDay !== null &&
    rentalSubtotal !== null &&
    depositAmount !== null &&
    platformFee !== null &&
    ownerPayout !== null &&
    total !== null
      ? {
          pricePerDay,
          rentalSubtotal,
          deposit: depositAmount,
          platformFee,
          ownerPayout,
          total,
        }
      : null);
  const depositTerms =
    value.depositTerms === undefined && isOffline
      ? null
      : readDepositTerms(value.depositTerms);
  if (
    !isNonEmptyString(value.itemTitle) ||
    !isNonEmptyString(value.lenderId) ||
    !isNullableString(value.lenderDisplayName) ||
    pricePerDay === null ||
    typeof value.days !== 'number' ||
    !Number.isInteger(value.days) ||
    value.days < 1 ||
    rentalSubtotal === null ||
    depositAmount === null ||
    moneyMinor === null ||
    depositTerms === undefined ||
    ownerPayout === null ||
    total === null ||
    value.currency !== 'RUB' ||
    paymentScenario === null ||
    !isNonEmptyString(handover.area) ||
    !isNonEmptyString(handover.address) ||
    !isCoordinate(handover.latitude, -90, 90) ||
    !isCoordinate(handover.longitude, -180, 180) ||
    !isNonEmptyString(value.listingVersion) ||
    !isNullableVersion(value.offerVersion) ||
    !isNullableVersion(value.cancellationPolicyVersion) ||
    !validAcceptance(
      acceptance,
      value.offerVersion,
      value.cancellationPolicyVersion,
    ) ||
    !Number.isSafeInteger(moneyMinor.pricePerDay * value.days) ||
    moneyMinor.rentalSubtotal !== moneyMinor.pricePerDay * value.days ||
    moneyMinor.ownerPayout + moneyMinor.platformFee !==
      moneyMinor.rentalSubtotal ||
    moneyMinor.total !== moneyMinor.rentalSubtotal + moneyMinor.deposit ||
    pricePerDay !== moneyMinor.pricePerDay ||
    rentalSubtotal !== moneyMinor.rentalSubtotal ||
    depositAmount !== moneyMinor.deposit ||
    platformFee !== moneyMinor.platformFee ||
    ownerPayout !== moneyMinor.ownerPayout ||
    total !== moneyMinor.total ||
    (isOffline &&
      (moneyMinor.deposit !== 0 ||
        moneyMinor.platformFee !== 0 ||
        moneyMinor.ownerPayout !== moneyMinor.rentalSubtotal ||
        depositTerms !== null)) ||
    (!isOffline && moneyMinor.deposit > 0 !== (depositTerms !== null))
  ) {
    return null;
  }

  return {
    itemTitle: value.itemTitle,
    lenderId: value.lenderId,
    lenderDisplayName: value.lenderDisplayName,
    pricePerDay: value.pricePerDay as number,
    days: value.days,
    rentalSubtotal: value.rentalSubtotal as number,
    depositAmount: value.depositAmount as number | null,
    platformFee: value.platformFee as number,
    ownerPayout: value.ownerPayout as number,
    total: value.total as number,
    currency: 'RUB',
    paymentScenario,
    moneyMinor,
    depositTerms,
    handover: {
      area: handover.area,
      address: handover.address,
      latitude: handover.latitude,
      longitude: handover.longitude,
    },
    listingVersion: value.listingVersion,
    offerVersion: value.offerVersion,
    cancellationPolicyVersion: value.cancellationPolicyVersion,
    acceptance: acceptance
      ? {
          actorId: acceptance.actorId as string,
          acceptedAt: acceptance.acceptedAt as string,
          method: 'BOOKING_SUBMIT_CHECKBOX',
          offerVersion: acceptance.offerVersion as string,
          cancellationPolicyVersion:
            acceptance.cancellationPolicyVersion as string,
        }
      : null,
  };
}

export function readBoundBookingTermsSnapshot(
  value: Prisma.JsonValue | null,
  binding: {
    borrowerId: string;
    lenderId: string;
    days: number;
    totalAmount: number;
  },
): BookingTermsSnapshot | null {
  const snapshot = readBookingTermsSnapshot(value);
  if (
    !snapshot ||
    snapshot.lenderId !== binding.lenderId ||
    snapshot.days !== binding.days ||
    (snapshot.acceptance !== null &&
      snapshot.acceptance.actorId !== binding.borrowerId) ||
    snapshot.moneyMinor.total !== minorUnits(binding.totalAmount)
  ) {
    return null;
  }
  return snapshot;
}

function readMoneyMinor(value: Prisma.JsonObject): BookingMoneyMinor | null {
  const pricePerDay = safeMinor(value.pricePerDay);
  const rentalSubtotal = safeMinor(value.rentalSubtotal);
  const deposit = safeMinor(value.deposit);
  const platformFee = safeMinor(value.platformFee);
  const ownerPayout = safeMinor(value.ownerPayout);
  const total = safeMinor(value.total);
  if (
    pricePerDay === null ||
    rentalSubtotal === null ||
    deposit === null ||
    platformFee === null ||
    ownerPayout === null ||
    total === null
  ) {
    return null;
  }
  return {
    pricePerDay,
    rentalSubtotal,
    deposit,
    platformFee,
    ownerPayout,
    total,
  };
}

function readDepositTerms(
  value: Prisma.JsonValue | undefined,
): DepositTerms | undefined {
  if (value === null) {
    return null;
  }
  if (
    !isJsonRecord(value) ||
    !isNonEmptyString(value.policyVersion) ||
    !isPositiveSafeInteger(value.disputeWindowSeconds)
  ) {
    return undefined;
  }
  return {
    policyVersion: value.policyVersion,
    disputeWindowSeconds: value.disputeWindowSeconds,
  };
}

function safeMinor(value: Prisma.JsonValue | undefined): number | null {
  return typeof value === 'number' && Number.isSafeInteger(value) && value >= 0
    ? value
    : null;
}

function isPositiveSafeInteger(
  value: Prisma.JsonValue | undefined,
): value is number {
  return typeof value === 'number' && Number.isSafeInteger(value) && value > 0;
}

function validAcceptance(
  acceptance: Prisma.JsonObject | null,
  offerVersion: Prisma.JsonValue | undefined,
  cancellationPolicyVersion: Prisma.JsonValue | undefined,
): boolean {
  if (offerVersion === null && cancellationPolicyVersion === null) {
    return acceptance === null;
  }
  if (
    !isNonEmptyString(offerVersion) ||
    !isNonEmptyString(cancellationPolicyVersion) ||
    !acceptance
  ) {
    return false;
  }
  return (
    isNonEmptyString(acceptance.actorId) &&
    isIsoTimestamp(acceptance.acceptedAt) &&
    acceptance.method === 'BOOKING_SUBMIT_CHECKBOX' &&
    acceptance.offerVersion === offerVersion &&
    acceptance.cancellationPolicyVersion === cancellationPolicyVersion
  );
}

function isJsonRecord(
  value: Prisma.JsonValue | null | undefined,
): value is Prisma.JsonObject {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isNonEmptyString(
  value: Prisma.JsonValue | undefined,
): value is string {
  return typeof value === 'string' && value.trim().length > 0;
}

function isNullableString(
  value: Prisma.JsonValue | undefined,
): value is string | null {
  return value === null || typeof value === 'string';
}

function isNullableVersion(
  value: Prisma.JsonValue | undefined,
): value is string | null {
  return value === null || isNonEmptyString(value);
}

function isIsoTimestamp(value: Prisma.JsonValue | undefined): value is string {
  if (typeof value !== 'string') {
    return false;
  }
  const timestamp = Date.parse(value);
  return (
    Number.isFinite(timestamp) && new Date(timestamp).toISOString() === value
  );
}

function isCoordinate(
  value: Prisma.JsonValue | undefined,
  min: number,
  max: number,
): value is number {
  return (
    typeof value === 'number' &&
    Number.isFinite(value) &&
    value >= min &&
    value <= max
  );
}

function minorUnits(value: Prisma.JsonValue | undefined): number | null {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
    return null;
  }
  const scaled = value * 100;
  const rounded = Math.round(scaled);
  return Number.isSafeInteger(rounded) && Math.abs(scaled - rounded) < 0.000001
    ? rounded
    : null;
}
