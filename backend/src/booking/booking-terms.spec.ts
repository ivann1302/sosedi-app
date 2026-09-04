import { Prisma } from '@prisma/client';
import {
  readBoundBookingTermsSnapshot,
  readBookingTermsSnapshot,
  type BookingTermsSnapshot,
  toSnapshotJson,
} from './booking-terms';

const validSnapshot: BookingTermsSnapshot = {
  itemTitle: 'Проектор',
  lenderId: 'lender-1',
  lenderDisplayName: 'Иван',
  pricePerDay: 450,
  days: 3,
  rentalSubtotal: 1350,
  depositAmount: null,
  platformFee: 0,
  ownerPayout: 1350,
  total: 1350,
  currency: 'RUB',
  paymentScenario: 'PAY_ON_HANDOVER',
  moneyMinor: {
    pricePerDay: 45_000,
    rentalSubtotal: 135_000,
    deposit: 0,
    platformFee: 0,
    ownerPayout: 135_000,
    total: 135_000,
  },
  depositTerms: null,
  handover: {
    area: 'Центральный округ',
    address: 'Москва, приватный адрес',
    latitude: 55.75,
    longitude: 37.61,
  },
  listingVersion: '2026-07-28:2026-07-29T09:00:00.000Z',
  offerVersion: null,
  cancellationPolicyVersion: null,
  acceptance: null,
};

describe('Booking terms snapshot', () => {
  it('reads a complete internally consistent immutable snapshot', () => {
    expect(readBookingTermsSnapshot(toSnapshotJson(validSnapshot))).toEqual(
      validSnapshot,
    );
  });

  it('keeps reading a valid legacy offline snapshot without exact fields', () => {
    const legacy = { ...validSnapshot } as Partial<BookingTermsSnapshot>;
    delete legacy.moneyMinor;
    delete legacy.depositTerms;

    expect(
      readBookingTermsSnapshot(legacy as Prisma.InputJsonValue),
    ).toMatchObject({
      paymentScenario: 'PAY_ON_HANDOVER',
      moneyMinor: validSnapshot.moneyMinor,
      depositTerms: null,
    });
  });

  it('reads exact minor units from a new offline snapshot', () => {
    const exactOffline = {
      ...validSnapshot,
      moneyMinor: {
        pricePerDay: 45_000,
        rentalSubtotal: 135_000,
        deposit: 0,
        platformFee: 0,
        ownerPayout: 135_000,
        total: 135_000,
      },
      depositTerms: null,
    } as Prisma.InputJsonValue;

    expect(readBookingTermsSnapshot(exactOffline)).toMatchObject({
      moneyMinor: {
        pricePerDay: 45_000,
        rentalSubtotal: 135_000,
        deposit: 0,
        platformFee: 0,
        ownerPayout: 135_000,
        total: 135_000,
      },
      depositTerms: null,
    });
  });

  it('reads an internally consistent fake Safe Deal snapshot', () => {
    const fakeSafeDeal = {
      ...validSnapshot,
      depositAmount: 50,
      platformFee: 13.5,
      ownerPayout: 1336.5,
      total: 1400,
      paymentScenario: 'FAKE_SAFE_DEAL',
      moneyMinor: {
        pricePerDay: 45_000,
        rentalSubtotal: 135_000,
        deposit: 5_000,
        platformFee: 1_350,
        ownerPayout: 133_650,
        total: 140_000,
      },
      depositTerms: {
        policyVersion: 'fake-deposit-v1',
        disputeWindowSeconds: 86_400,
      },
    } as Prisma.InputJsonValue;

    expect(readBookingTermsSnapshot(fakeSafeDeal)).toMatchObject({
      paymentScenario: 'FAKE_SAFE_DEAL',
      moneyMinor: {
        deposit: 5_000,
        platformFee: 1_350,
        ownerPayout: 133_650,
        total: 140_000,
      },
      depositTerms: {
        policyVersion: 'fake-deposit-v1',
        disputeWindowSeconds: 86_400,
      },
    });
  });

  it.each([
    {
      name: 'missing exact minor fields',
      override: { moneyMinor: undefined },
    },
    {
      name: 'minor total that excludes the deposit',
      override: {
        moneyMinor: {
          pricePerDay: 45_000,
          rentalSubtotal: 135_000,
          deposit: 5_000,
          platformFee: 1_350,
          ownerPayout: 133_650,
          total: 135_000,
        },
      },
    },
    {
      name: 'missing terms for a positive deposit',
      override: { depositTerms: null },
    },
  ])('rejects fake Safe Deal with $name', ({ override }) => {
    const fakeSafeDeal = {
      ...validSnapshot,
      depositAmount: 50,
      platformFee: 13.5,
      ownerPayout: 1336.5,
      total: 1400,
      paymentScenario: 'FAKE_SAFE_DEAL',
      moneyMinor: {
        pricePerDay: 45_000,
        rentalSubtotal: 135_000,
        deposit: 5_000,
        platformFee: 1_350,
        ownerPayout: 133_650,
        total: 140_000,
      },
      depositTerms: {
        policyVersion: 'fake-deposit-v1',
        disputeWindowSeconds: 86_400,
      },
      ...override,
    } as Prisma.InputJsonValue;

    expect(readBookingTermsSnapshot(fakeSafeDeal)).toBeNull();
  });

  it('retains immutable borrower acceptance for approved document versions', () => {
    const accepted = {
      ...validSnapshot,
      offerVersion: 'offer-v1',
      cancellationPolicyVersion: 'rental-rules-v1',
      acceptance: {
        actorId: 'borrower-1',
        acceptedAt: '2026-07-30T03:50:00.000Z',
        method: 'BOOKING_SUBMIT_CHECKBOX',
        offerVersion: 'offer-v1',
        cancellationPolicyVersion: 'rental-rules-v1',
      },
    } as Prisma.InputJsonValue;

    expect(readBookingTermsSnapshot(accepted)).toMatchObject({
      acceptance: {
        actorId: 'borrower-1',
        acceptedAt: '2026-07-30T03:50:00.000Z',
        method: 'BOOKING_SUBMIT_CHECKBOX',
        offerVersion: 'offer-v1',
        cancellationPolicyVersion: 'rental-rules-v1',
      },
    });
  });

  it('binds an accepted snapshot to the immutable booking record', () => {
    const accepted = {
      ...validSnapshot,
      offerVersion: 'offer-v1',
      cancellationPolicyVersion: 'rental-rules-v1',
      acceptance: {
        actorId: 'borrower-1',
        acceptedAt: '2026-07-30T03:50:00.000Z',
        method: 'BOOKING_SUBMIT_CHECKBOX',
        offerVersion: 'offer-v1',
        cancellationPolicyVersion: 'rental-rules-v1',
      },
    } as Prisma.InputJsonValue;
    const binding = {
      borrowerId: 'borrower-1',
      lenderId: 'lender-1',
      days: 3,
      totalAmount: 1350,
    };

    expect(readBoundBookingTermsSnapshot(accepted, binding)).not.toBeNull();
    for (const mismatch of [
      { ...binding, borrowerId: 'other-borrower' },
      { ...binding, lenderId: 'other-lender' },
      { ...binding, days: 2 },
      { ...binding, totalAmount: 1349 },
    ]) {
      expect(readBoundBookingTermsSnapshot(accepted, mismatch)).toBeNull();
    }
  });

  it.each([
    { name: 'partial payload', value: { itemTitle: 'Проектор' } },
    {
      name: 'unsupported currency',
      value: { ...validSnapshot, currency: 'USD' },
    },
    {
      name: 'invalid handover coordinates',
      value: {
        ...validSnapshot,
        handover: { ...validSnapshot.handover, latitude: 91 },
      },
    },
    {
      name: 'inconsistent total',
      value: { ...validSnapshot, total: 1349 },
    },
    {
      name: 'non-zero platform fee',
      value: { ...validSnapshot, platformFee: 10 },
    },
  ])('rejects $name', ({ value }) => {
    expect(readBookingTermsSnapshot(value as Prisma.InputJsonValue)).toBeNull();
  });
});
