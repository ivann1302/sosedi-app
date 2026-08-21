import {
  BadRequestException,
  ConflictException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BookingStatus, ItemStatus, Prisma } from '@prisma/client';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { PrismaService } from '../prisma/prisma.service';
import {
  BOOKING_COMPETING_CANCELLATION_REASON,
  BOOKING_MAX_ACTIVE_PENDING,
  BOOKING_MAX_COMPETING_PENDING,
  BOOKING_PENDING_TTL_MS,
  BookingService,
} from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';

function acceptedRequest(
  overrides: Partial<CreateBookingDto> = {},
): CreateBookingDto {
  return {
    itemId: '11111111-1111-4111-8111-111111111111',
    startDate: '2026-08-01',
    endDate: '2026-08-03',
    offerVersion: '2026-08-01.1',
    cancellationPolicyVersion: '2026-08-01.1',
    offerAccepted: true,
    rentalRulesAccepted: true,
    ...overrides,
  };
}

function createService({
  ownerId = 'lender-1',
  hasConflict = false,
  hasCalendarConflict = false,
  hasInteractionBlock = false,
  activePendingCount = 0,
  competingPendingCount = 0,
  depositAmount = null,
  legalTermsVersion = '2026-08-01.1',
}: {
  ownerId?: string;
  hasConflict?: boolean;
  hasCalendarConflict?: boolean;
  hasInteractionBlock?: boolean;
  activePendingCount?: number;
  competingPendingCount?: number;
  depositAmount?: Prisma.Decimal | null;
  legalTermsVersion?: string | null;
} = {}) {
  const create = jest.fn(
    ({
      data,
    }: {
      data: {
        itemId: string;
        borrowerId: string;
        lenderId: string;
        startDate: Date;
        endDate: Date;
        totalAmount: Prisma.Decimal;
        status: BookingStatus;
        expiresAt: Date;
        termsSnapshot: Prisma.InputJsonValue;
      };
    }) =>
      Promise.resolve({
        id: 'booking-1',
        ...data,
        disputeOpenedAt: null,
        cancellationReason: null,
        createdAt: new Date('2026-07-29T10:00:00.000Z'),
        updatedAt: new Date('2026-07-29T10:00:00.000Z'),
      }),
  );
  const tx = {
    $executeRaw: jest.fn(() => Promise.resolve(1)),
    item: {
      findFirst: jest.fn(() =>
        Promise.resolve({
          id: 'item-1',
          ownerId,
          title: 'Проектор',
          pricePerDay: new Prisma.Decimal(450),
          depositAmount,
          status: ItemStatus.APPROVED,
          publicArea: 'Центральный округ',
          address: 'Москва, приватный адрес',
          latitude: 55.75,
          longitude: 37.61,
          listingRulesVersion: '2026-07-28',
          updatedAt: new Date('2026-07-29T09:00:00.000Z'),
          owner: { name: 'Владелец' },
        }),
      ),
    },
    itemUnavailablePeriod: {
      findFirst: jest.fn(() =>
        Promise.resolve(
          hasCalendarConflict ? { id: 'unavailable-period-1' } : null,
        ),
      ),
    },
    userBlock: {
      findFirst: jest.fn(() =>
        Promise.resolve(
          hasInteractionBlock ? { id: 'interaction-block-1' } : null,
        ),
      ),
    },
    booking: {
      count: jest.fn(({ where }: { where: { itemId?: string } }) =>
        Promise.resolve(
          where.itemId ? competingPendingCount : activePendingCount,
        ),
      ),
      findUnique: jest.fn(() => Promise.resolve(null)),
      findFirst: jest.fn(() =>
        Promise.resolve(hasConflict ? { id: 'booking-existing' } : null),
      ),
      create,
    },
    bookingMessage: {
      create: jest.fn(() => Promise.resolve({ id: 'message-1' })),
      createMany: jest.fn(() => Promise.resolve({ count: 1 })),
    },
    notificationOutboxEvent: {
      create: jest.fn(() => Promise.resolve({ id: 'event-1' })),
    },
    bookingTransitionHistory: {
      create: jest.fn(() => Promise.resolve({ id: 'transition-1' })),
    },
  };
  const prisma = {
    $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
      callback(tx),
    ),
  };
  const config = new ConfigService(
    legalTermsVersion
      ? {
          MARKETPLACE_OFFER_VERSION: legalTermsVersion,
          MARKETPLACE_CANCELLATION_POLICY_VERSION: legalTermsVersion,
        }
      : {},
  );

  return {
    service: new BookingService(prisma as unknown as PrismaService, config),
    create,
    transaction: prisma.$transaction,
  };
}

describe('BookingService', () => {
  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(new Date('2026-07-29T12:00:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('takes lender and inclusive price total from backend', async () => {
    const { service, create } = createService();

    const result = await service.create('borrower-1', acceptedRequest());

    expect(result).toMatchObject({
      lenderId: 'lender-1',
      borrowerId: 'borrower-1',
      days: 3,
      totalAmount: 1350,
      status: BookingStatus.PENDING,
    });
    expect(create.mock.calls[0]?.[0].data).toMatchObject({
      lenderId: 'lender-1',
      totalAmount: new Prisma.Decimal(1350),
      status: BookingStatus.PENDING,
      termsSnapshot: {
        itemTitle: 'Проектор',
        pricePerDay: 450,
        days: 3,
        rentalSubtotal: 1350,
        platformFee: 0,
        ownerPayout: 1350,
        total: 1350,
        currency: 'RUB',
        paymentScenario: 'PAY_ON_HANDOVER',
        offerVersion: '2026-08-01.1',
        cancellationPolicyVersion: '2026-08-01.1',
        acceptance: {
          actorId: 'borrower-1',
          method: 'BOOKING_SUBMIT_CHECKBOX',
          offerVersion: '2026-08-01.1',
          cancellationPolicyVersion: '2026-08-01.1',
        },
      },
    });
    expect(create.mock.calls[0]?.[0].data.expiresAt).toEqual(
      new Date('2026-07-30T00:00:00.000Z'),
    );
    expect(BOOKING_PENDING_TTL_MS).toBe(12 * 60 * 60 * 1000);
    const termsSnapshot = create.mock.calls[0]?.[0].data.termsSnapshot;
    expect(termsSnapshot).toHaveProperty('acceptance.acceptedAt');
  });

  it('rejects missing or stale explicit marketplace terms acceptance before DB', async () => {
    const { service, transaction } = createService();

    await expect(
      service.create('borrower-1', {
        itemId: '11111111-1111-4111-8111-111111111111',
        startDate: '2026-08-01',
        endDate: '2026-08-01',
      }),
    ).rejects.toMatchObject<ConflictException>({
      response: {
        code: 'BOOKING_TERMS_ACCEPTANCE_REQUIRED',
        message: 'Подтвердите актуальные условия аренды',
      },
    });
    await expect(
      service.create(
        'borrower-1',
        acceptedRequest({ offerVersion: 'old-offer-v1' }),
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(transaction).not.toHaveBeenCalled();
  });

  it.each([null, 'draft-2026-08-01'])(
    'keeps booking creation closed for unavailable terms version %s',
    async (legalTermsVersion) => {
      const { service, transaction } = createService({
        legalTermsVersion,
      });

      await expect(
        service.create('borrower-1', {
          itemId: '11111111-1111-4111-8111-111111111111',
          startDate: '2026-08-01',
          endDate: '2026-08-01',
        }),
      ).rejects.toMatchObject<ServiceUnavailableException>({
        response: {
          code: 'BOOKING_LEGAL_GATE_CLOSED',
          message: 'Бронирование временно недоступно',
        },
      });
      expect(transaction).not.toHaveBeenCalled();
    },
  );

  it('rejects self-booking', async () => {
    const { service } = createService({ ownerId: 'borrower-1' });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects a legacy non-zero deposit before creating a booking', async () => {
    const { service, create } = createService({
      depositAmount: new Prisma.Decimal(1000),
    });

    await expect(
      service.create('borrower-1', acceptedRequest()),
    ).rejects.toMatchObject<ConflictException>({
      response: {
        code: 'ITEM_DEPOSIT_NOT_SUPPORTED',
        message: 'Бронирование с залогом пока недоступно',
      },
    });
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects an overlapping active reservation under the item lock', async () => {
    const { service, create } = createService({ hasConflict: true });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects a new booking when either participant blocked the other', async () => {
    const { service, create } = createService({
      hasInteractionBlock: true,
    });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects an owner-blocked calendar period under the item lock', async () => {
    const { service, create } = createService({ hasCalendarConflict: true });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(create).not.toHaveBeenCalled();
  });

  it('limits active pending bookings per borrower', async () => {
    const { service, create } = createService({
      activePendingCount: BOOKING_MAX_ACTIVE_PENDING,
    });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(TooManyRequestsException);
    expect(create).not.toHaveBeenCalled();
  });

  it('limits live overlapping requests per item and period', async () => {
    const { service, create } = createService({
      competingPendingCount: BOOKING_MAX_COMPETING_PENDING,
    });

    await expect(
      service.create('borrower-1', acceptedRequest({ endDate: '2026-08-01' })),
    ).rejects.toBeInstanceOf(TooManyRequestsException);
    expect(create).not.toHaveBeenCalled();
  });

  it('confirms one request and cancels overlapping pending competitors', async () => {
    const pending = {
      id: 'booking-1',
      itemId: 'item-1',
      borrowerId: 'borrower-1',
      lenderId: 'lender-1',
      startDate: new Date('2026-08-01T00:00:00.000Z'),
      endDate: new Date('2026-08-03T00:00:00.000Z'),
      totalAmount: new Prisma.Decimal(1350),
      status: BookingStatus.PENDING,
      expiresAt: new Date('2026-08-01T00:00:00.000Z'),
      cancellationReason: null,
      disputeOpenedAt: null,
      createdAt: new Date('2026-07-29T10:00:00.000Z'),
      updatedAt: new Date('2026-07-29T10:00:00.000Z'),
    };
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const createMany = jest.fn().mockResolvedValue({ count: 2 });
    const createSystemMessages = jest.fn().mockResolvedValue({ count: 2 });
    const tx = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      itemUnavailablePeriod: {
        findFirst: jest.fn().mockResolvedValue(null),
      },
      booking: {
        findFirst: jest.fn(({ where }: { where: { status?: unknown } }) =>
          Promise.resolve(where.status ? null : pending),
        ),
        findMany: jest.fn().mockResolvedValue([{ id: 'booking-2' }]),
        update: jest.fn().mockResolvedValue({
          ...pending,
          status: BookingStatus.CONFIRMED,
          expiresAt: null,
        }),
        updateMany,
      },
      bookingMessage: { createMany: createSystemMessages },
      notificationOutboxEvent: { createMany },
      bookingTransitionHistory: {
        createMany: jest.fn().mockResolvedValue({ count: 2 }),
      },
    };
    const prisma = {
      $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
        callback(tx),
      ),
    };
    const service = new BookingService(
      prisma as unknown as PrismaService,
      new ConfigService(),
    );

    await expect(
      service.confirm('lender-1', 'booking-1'),
    ).resolves.toMatchObject({
      status: BookingStatus.CONFIRMED,
      days: 3,
      totalAmount: 1350,
    });
    expect(updateMany).toHaveBeenCalledWith({
      where: {
        id: { in: ['booking-2'] },
        status: BookingStatus.PENDING,
      },
      data: {
        status: BookingStatus.CANCELLED,
        cancellationReason: BOOKING_COMPETING_CANCELLATION_REASON,
        expiresAt: null,
      },
    });
    expect(createMany).toHaveBeenCalledTimes(1);
    expect(createSystemMessages).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({ bookingId: 'booking-1' }),
        expect.objectContaining({ bookingId: 'booking-2' }),
      ],
    });
    expect(createMany).toHaveBeenCalledWith({
      data: [
        {
          bookingId: 'booking-1',
          eventType: 'BOOKING_CONFIRMED',
          deduplicationKey: 'booking:booking-1:BOOKING_CONFIRMED',
        },
        {
          bookingId: 'booking-2',
          eventType: 'BOOKING_COMPETING_CANCELLED',
          deduplicationKey: 'booking:booking-2:BOOKING_COMPETING_CANCELLED',
        },
      ],
      skipDuplicates: true,
    });
  });

  it.each([
    { booking: null, error: NotFoundException },
    {
      booking: {
        id: 'booking-1',
        itemId: 'item-1',
        status: BookingStatus.CONFIRMED,
        expiresAt: null,
      },
      error: ConflictException,
    },
  ])(
    'rejects an invalid confirmation actor or state',
    async ({ booking, error }) => {
      const tx = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        booking: { findFirst: jest.fn().mockResolvedValue(booking) },
      };
      const prisma = {
        $transaction: jest.fn(
          <T>(callback: (client: typeof tx) => Promise<T>) => callback(tx),
        ),
      };
      const service = new BookingService(
        prisma as unknown as PrismaService,
        new ConfigService(),
      );

      await expect(
        service.confirm('lender-1', 'booking-1'),
      ).rejects.toBeInstanceOf(error);
    },
  );
});
