import { BookingStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  BOOKING_PENDING_TIMEOUT_REASON,
  BookingExpiryService,
} from './booking-expiry.service';

describe('BookingExpiryService', () => {
  it('idempotently cancels only expired pending bookings with a reason', async () => {
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const createOutbox = jest.fn().mockResolvedValue({ id: 'event-1' });
    const tx = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      booking: { updateMany },
      notificationOutboxEvent: { create: createOutbox },
      bookingTransitionHistory: {
        create: jest.fn().mockResolvedValue({ id: 'transition-1' }),
      },
    };
    const prisma = {
      booking: {
        findMany: jest
          .fn()
          .mockResolvedValueOnce([{ id: 'booking-1' }, { id: 'booking-2' }])
          .mockResolvedValueOnce([]),
      },
      $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
        callback(tx),
      ),
    };
    const service = new BookingExpiryService(
      prisma as unknown as PrismaService,
    );
    const now = new Date('2026-07-29T12:00:00.000Z');

    await expect(service.expirePending(now)).resolves.toBe(2);
    await expect(service.expirePending(now)).resolves.toBe(0);
    expect(updateMany).toHaveBeenCalledWith({
      where: {
        id: 'booking-1',
        status: BookingStatus.PENDING,
        expiresAt: { lte: now },
      },
      data: {
        status: BookingStatus.CANCELLED,
        cancellationReason: BOOKING_PENDING_TIMEOUT_REASON,
      },
    });
    expect(updateMany).toHaveBeenCalledTimes(2);
    expect(createOutbox).toHaveBeenCalledTimes(2);
  });
});
