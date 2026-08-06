import { ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BookingAvailabilityService } from './booking-availability.service';

function createService({
  ownsItem = true,
  bookingConflict = false,
  calendarConflict = false,
}: {
  ownsItem?: boolean;
  bookingConflict?: boolean;
  calendarConflict?: boolean;
} = {}) {
  const create = jest.fn(({ data }: { data: Record<string, unknown> }) =>
    Promise.resolve({
      id: 'period-1',
      ...data,
      createdAt: new Date('2026-07-29T10:00:00.000Z'),
    }),
  );
  const tx = {
    $executeRaw: jest.fn(() => Promise.resolve(1)),
    item: {
      findFirst: jest.fn(() =>
        Promise.resolve(ownsItem ? { id: 'item-1' } : null),
      ),
    },
    booking: {
      findFirst: jest.fn(() =>
        Promise.resolve(bookingConflict ? { id: 'booking-1' } : null),
      ),
    },
    itemUnavailablePeriod: {
      findFirst: jest.fn(() =>
        Promise.resolve(calendarConflict ? { id: 'period-1' } : null),
      ),
      create,
      deleteMany: jest.fn(() => Promise.resolve({ count: 1 })),
    },
  };
  const prisma = {
    item: tx.item,
    booking: tx.booking,
    itemUnavailablePeriod: {
      findMany: jest.fn(() => Promise.resolve([])),
      findFirst: tx.itemUnavailablePeriod.findFirst,
    },
    $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
      callback(tx),
    ),
  };

  return {
    service: new BookingAvailabilityService(prisma as unknown as PrismaService),
    create,
    lock: tx.$executeRaw,
  };
}

describe('BookingAvailabilityService', () => {
  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(new Date('2026-07-29T12:00:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('creates an owner period under the item lock', async () => {
    const { service, create, lock } = createService();

    const result = await service.create('owner-1', 'item-1', {
      startDate: '2026-08-01',
      endDate: '2026-08-03',
    });

    expect(result.id).toBe('period-1');
    expect(lock).toHaveBeenCalledTimes(1);
    expect(create).toHaveBeenCalledWith({
      data: expect.objectContaining({ itemId: 'item-1' }) as object,
    });
  });

  it('does not change the calendar over a reserved booking', async () => {
    const { service, create } = createService({ bookingConflict: true });

    await expect(
      service.create('owner-1', 'item-1', {
        startDate: '2026-08-01',
        endDate: '2026-08-03',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(create).not.toHaveBeenCalled();
  });

  it('does not reveal an item owned by another actor', async () => {
    const { service, create } = createService({ ownsItem: false });

    await expect(
      service.create('other-owner', 'item-1', {
        startDate: '2026-08-01',
        endDate: '2026-08-03',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(create).not.toHaveBeenCalled();
  });

  it.each([
    ['free dates', false, false, true],
    ['reserved booking', true, false, false],
    ['owner period', false, true, false],
  ])(
    'returns only public availability for %s',
    async (_, bookingConflict, calendarConflict, available) => {
      const { service } = createService({
        bookingConflict,
        calendarConflict,
      });

      await expect(
        service.check('item-1', {
          startDate: '2026-08-01',
          endDate: '2026-08-03',
        }),
      ).resolves.toEqual({ available });
    },
  );
});
