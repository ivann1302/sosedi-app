import { BadRequestException } from '@nestjs/common';
import { BookingMessageAuthorRole, BookingStatus } from '@prisma/client';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import {
  BOOKING_CHAT_MAX_PER_BOOKING_WINDOW,
  BookingMessageService,
} from './booking-message.service';

const booking = {
  id: 'booking-1',
  borrowerId: 'borrower-1',
  lenderId: 'lender-1',
  status: BookingStatus.ACTIVE,
  expiresAt: null,
  borrower: { deletedAt: null, isBlocked: false },
  lender: { deletedAt: null, isBlocked: false },
};

const message = {
  id: 'message-1',
  bookingId: booking.id,
  authorId: booking.borrowerId,
  authorRole: BookingMessageAuthorRole.BORROWER,
  clientMessageId: '11111111-1111-4111-8111-111111111141',
  body: 'Добрый день',
  createdAt: new Date('2026-08-09T12:00:00.000Z'),
};

function createService({
  repeated = null,
  rateCount = 0,
}: {
  repeated?: typeof message | null;
  rateCount?: number;
} = {}) {
  const create = jest.fn().mockResolvedValue(message);
  const count = jest.fn().mockResolvedValue(rateCount);
  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    booking: { findFirst: jest.fn().mockResolvedValue(booking) },
    bookingMessage: {
      findUnique: jest.fn().mockResolvedValue(repeated),
      count,
      create,
    },
    userBlock: { findFirst: jest.fn().mockResolvedValue(null) },
    notificationOutboxEvent: {
      create: jest.fn().mockResolvedValue({ id: 'event-1' }),
    },
  };
  const prisma = {
    $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
      callback(tx),
    ),
  };
  return {
    service: new BookingMessageService(
      prisma as unknown as PrismaService,
      {} as UsersService,
    ),
    count,
    create,
    transaction: prisma.$transaction,
  };
}

describe('BookingMessageService', () => {
  it('returns an exact idempotent retry before consuming the rate quota', async () => {
    const { service, count, create } = createService({ repeated: message });

    await expect(
      service.send(booking.borrowerId, booking.id, {
        clientMessageId: message.clientMessageId,
        body: `  ${message.body}  `,
      }),
    ).resolves.toMatchObject({
      id: message.id,
      author: 'SELF',
      body: message.body,
    });
    expect(count).not.toHaveBeenCalled();
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects the per-booking minute cap without storing a message', async () => {
    const { service, create } = createService({
      rateCount: BOOKING_CHAT_MAX_PER_BOOKING_WINDOW,
    });

    await expect(
      service.send(booking.borrowerId, booking.id, {
        clientMessageId: message.clientMessageId,
        body: message.body,
      }),
    ).rejects.toBeInstanceOf(TooManyRequestsException);
    expect(create).not.toHaveBeenCalled();
  });

  it('rejects unsafe control characters before opening a transaction', async () => {
    const { service, transaction } = createService();

    await expect(
      service.send(booking.borrowerId, booking.id, {
        clientMessageId: message.clientMessageId,
        body: 'Текст\u0000с хвостом',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(transaction).not.toHaveBeenCalled();
  });
});
