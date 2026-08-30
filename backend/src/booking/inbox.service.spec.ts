import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { InboxService } from './inbox.service';

const firstEvent = {
  id: '11111111-1111-4111-8111-111111111111',
  eventId: '21111111-1111-4111-8111-111111111111',
  bookingId: '31111111-1111-4111-8111-111111111111',
  supportTicketId: null,
  itemId: null,
  eventType: 'BOOKING_CONFIRMED',
  readAt: null,
  createdAt: new Date('2026-08-30T10:00:00.000Z'),
};

describe('InboxService', () => {
  it('returns a user-scoped unread cursor page', async () => {
    const findMany = jest.fn().mockResolvedValue([
      firstEvent,
      {
        ...firstEvent,
        id: '12222222-2222-4222-8222-222222222222',
        eventId: '22222222-2222-4222-8222-222222222222',
      },
    ]);
    const prisma = {
      inboxEvent: { findMany },
    } as unknown as PrismaService;
    const service = new InboxService(prisma);

    await expect(
      service.listPage('user-1', { limit: 1, unreadOnly: true }),
    ).resolves.toEqual({
      items: [
        {
          eventId: firstEvent.eventId,
          bookingId: firstEvent.bookingId,
          supportTicketId: null,
          itemId: null,
          eventType: firstEvent.eventType,
          readAt: null,
          createdAt: firstEvent.createdAt,
        },
      ],
      nextCursor: firstEvent.id,
    });
    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { recipientId: 'user-1', readAt: null },
        take: 2,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      }),
    );
  });

  it('rejects a cursor that does not belong to the recipient', async () => {
    const findMany = jest.fn();
    const prisma = {
      inboxEvent: {
        findFirst: jest.fn().mockResolvedValue(null),
        findMany,
      },
    } as unknown as PrismaService;
    const service = new InboxService(prisma);

    await expect(
      service.listPage('user-1', {
        cursor: '11111111-1111-4111-8111-111111111111',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(findMany).not.toHaveBeenCalled();
  });

  it('marks only the recipient unread events as read', async () => {
    const now = new Date('2026-08-30T12:00:00.000Z');
    jest.useFakeTimers({ now });
    const updateMany = jest.fn().mockResolvedValue({ count: 3 });
    const prisma = {
      inboxEvent: { updateMany },
    } as unknown as PrismaService;
    const service = new InboxService(prisma);

    await expect(service.markAllRead('user-1')).resolves.toEqual({
      updated: 3,
    });
    expect(updateMany).toHaveBeenCalledWith({
      where: { recipientId: 'user-1', readAt: null },
      data: { readAt: now },
    });
    jest.useRealTimers();
  });
});
