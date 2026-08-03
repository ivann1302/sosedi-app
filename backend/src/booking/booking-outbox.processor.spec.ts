import { PrismaService } from '../prisma/prisma.service';
import { BookingOutboxProcessor } from './booking-outbox.processor';

describe('BookingOutboxProcessor', () => {
  it('creates recipient inbox rows once and marks the event processed', async () => {
    const createMany = jest.fn().mockResolvedValue({ count: 2 });
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const findFirst = jest
      .fn()
      .mockResolvedValueOnce({
        id: 'event-1',
        bookingId: 'booking-1',
        supportTicketId: null,
        recipientId: null,
        itemId: null,
        eventType: 'BOOKING_CONFIRMED',
        createdAt: new Date('2026-07-29T10:00:00.000Z'),
        booking: { borrowerId: 'borrower-1', lenderId: 'lender-1' },
        supportTicket: null,
      })
      .mockResolvedValueOnce(null);
    const tx = {
      notificationOutboxEvent: { findFirst, updateMany },
      inboxEvent: { createMany },
      devicePushToken: {
        findMany: jest
          .fn()
          .mockResolvedValue([{ id: 'token-1' }, { id: 'token-2' }]),
      },
      pushDelivery: { createMany: jest.fn().mockResolvedValue({ count: 2 }) },
    };
    const prisma = {
      notificationOutboxEvent: {
        findMany: jest
          .fn()
          .mockResolvedValue([{ id: 'event-1' }, { id: 'event-1' }]),
      },
      $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
        callback(tx),
      ),
    };
    const processor = new BookingOutboxProcessor(
      prisma as unknown as PrismaService,
    );

    await expect(processor.processPending()).resolves.toBe(1);
    expect(createMany).toHaveBeenCalledTimes(1);
    expect(createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({ recipientId: 'borrower-1' }) as object,
        expect.objectContaining({ recipientId: 'lender-1' }) as object,
      ],
      skipDuplicates: true,
    });
    expect(updateMany).toHaveBeenCalledTimes(1);
    expect(tx.pushDelivery.createMany).toHaveBeenCalledWith({
      data: [
        { eventId: 'event-1', tokenId: 'token-1' },
        { eventId: 'event-1', tokenId: 'token-2' },
      ],
      skipDuplicates: true,
    });
  });

  it('delivers a support event only to the ticket author', async () => {
    const createMany = jest.fn().mockResolvedValue({ count: 1 });
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const createPushDeliveries = jest.fn().mockResolvedValue({ count: 1 });
    const tx = {
      notificationOutboxEvent: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'event-2',
          bookingId: null,
          supportTicketId: 'ticket-1',
          recipientId: null,
          itemId: null,
          eventType: 'SUPPORT_REPLIED',
          createdAt: new Date('2026-07-29T10:00:00.000Z'),
          booking: null,
          supportTicket: { userId: 'author-1' },
        }),
        updateMany,
      },
      inboxEvent: { createMany },
      devicePushToken: {
        findMany: jest.fn().mockResolvedValue([{ id: 'support-token-1' }]),
      },
      pushDelivery: { createMany: createPushDeliveries },
    };
    const prisma = {
      notificationOutboxEvent: {
        findMany: jest.fn().mockResolvedValue([{ id: 'event-2' }]),
      },
      $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
        callback(tx),
      ),
    };
    const processor = new BookingOutboxProcessor(
      prisma as unknown as PrismaService,
    );

    await expect(processor.processPending()).resolves.toBe(1);
    expect(createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({
          recipientId: 'author-1',
          bookingId: null,
          supportTicketId: 'ticket-1',
        }) as object,
      ],
      skipDuplicates: true,
    });
    expect(createPushDeliveries).toHaveBeenCalledWith({
      data: [{ eventId: 'event-2', tokenId: 'support-token-1' }],
      skipDuplicates: true,
    });
  });

  it('delivers a direct domain event only to its explicit recipient', async () => {
    const createMany = jest.fn().mockResolvedValue({ count: 1 });
    const createPushDeliveries = jest.fn().mockResolvedValue({ count: 1 });
    const tx = {
      notificationOutboxEvent: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'event-3',
          bookingId: null,
          supportTicketId: null,
          recipientId: 'owner-1',
          itemId: 'item-1',
          eventType: 'ITEM_APPROVED',
          createdAt: new Date('2026-07-29T10:00:00.000Z'),
          booking: null,
          supportTicket: null,
        }),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      inboxEvent: { createMany },
      devicePushToken: {
        findMany: jest.fn().mockResolvedValue([{ id: 'owner-token-1' }]),
      },
      pushDelivery: { createMany: createPushDeliveries },
    };
    const prisma = {
      notificationOutboxEvent: {
        findMany: jest.fn().mockResolvedValue([{ id: 'event-3' }]),
      },
      $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
        callback(tx),
      ),
    };
    const processor = new BookingOutboxProcessor(
      prisma as unknown as PrismaService,
    );

    await expect(processor.processPending()).resolves.toBe(1);
    expect(createMany).toHaveBeenCalledWith({
      data: [
        expect.objectContaining({
          recipientId: 'owner-1',
          bookingId: null,
          supportTicketId: null,
          itemId: 'item-1',
          eventType: 'ITEM_APPROVED',
        }) as object,
      ],
      skipDuplicates: true,
    });
    expect(createPushDeliveries).toHaveBeenCalledWith({
      data: [{ eventId: 'event-3', tokenId: 'owner-token-1' }],
      skipDuplicates: true,
    });
  });
});
