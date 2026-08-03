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
