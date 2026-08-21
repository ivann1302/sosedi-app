import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingMessageAuthorRole,
  BookingStatus,
  Prisma,
} from '@prisma/client';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { PrismaService } from '../prisma/prisma.service';
import { UserBlockResponseDto } from '../users/dto/user-block-response.dto';
import { UsersService } from '../users/users.service';
import {
  type BookingMessageAuthor,
  BookingMessagePageResponseDto,
  BookingMessageReadResponseDto,
  BookingMessageResponseDto,
} from './dto/booking-message-response.dto';
import { CreateBookingMessageDto } from './dto/create-booking-message.dto';
import { ListBookingMessagesQueryDto } from './dto/list-booking-messages-query.dto';

const DEFAULT_PAGE_SIZE = 50;
export const BOOKING_CHAT_MAX_BODY_LENGTH = 2000;
export const BOOKING_CHAT_RATE_WINDOW_MS = 60 * 1000;
export const BOOKING_CHAT_MAX_PER_BOOKING_WINDOW = 20;
export const BOOKING_CHAT_MAX_PER_ACTOR_WINDOW = 60;
const WRITABLE_STATUSES = new Set<BookingStatus>([
  BookingStatus.CONFIRMED,
  BookingStatus.ACTIVE,
  BookingStatus.RETURNED,
]);

const MESSAGE_SELECT = {
  id: true,
  bookingId: true,
  authorId: true,
  authorRole: true,
  clientMessageId: true,
  body: true,
  createdAt: true,
} satisfies Prisma.BookingMessageSelect;

type MessageRow = Prisma.BookingMessageGetPayload<{
  select: typeof MESSAGE_SELECT;
}>;

@Injectable()
export class BookingMessageService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly users: UsersService,
  ) {}

  async blockCounterparty(
    actorId: string,
    bookingId: string,
  ): Promise<UserBlockResponseDto> {
    const booking = await this.requireParticipant(
      this.prisma,
      actorId,
      bookingId,
    );
    const counterpartyId =
      booking.borrowerId === actorId ? booking.lenderId : booking.borrowerId;
    return this.users.blockUser(actorId, counterpartyId);
  }

  async list(
    actorId: string,
    bookingId: string,
    query: ListBookingMessagesQueryDto,
  ): Promise<BookingMessagePageResponseDto> {
    const booking = await this.requireParticipant(
      this.prisma,
      actorId,
      bookingId,
    );
    const limit = query.limit ?? DEFAULT_PAGE_SIZE;
    let after: { createdAt: Date; id: string } | null = null;
    if (query.cursor) {
      after = await this.prisma.bookingMessage.findFirst({
        where: { id: query.cursor, bookingId },
        select: { createdAt: true, id: true },
      });
      if (!after) {
        throw new BadRequestException({
          code: 'INVALID_MESSAGE_CURSOR',
          message: 'Курсор сообщений недействителен',
        });
      }
    }

    const rows = await this.prisma.bookingMessage.findMany({
      where: {
        bookingId,
        ...(after
          ? {
              OR: [
                { createdAt: { lt: after.createdAt } },
                { createdAt: after.createdAt, id: { lt: after.id } },
              ],
            }
          : {}),
      },
      select: MESSAGE_SELECT,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });
    const hasMore = rows.length > limit;
    const visible = (hasMore ? rows.slice(0, limit) : rows).reverse();
    return {
      items: visible.map((message) =>
        this.toResponse(actorId, booking, message),
      ),
      nextCursor: hasMore ? (visible[0]?.id ?? null) : null,
    };
  }

  async send(
    actorId: string,
    bookingId: string,
    dto: CreateBookingMessageDto,
  ): Promise<BookingMessageResponseDto> {
    const body = dto.body.trim();
    if (
      body.length === 0 ||
      body.length > BOOKING_CHAT_MAX_BODY_LENGTH ||
      containsUnsafeControlCharacter(body)
    ) {
      throw new BadRequestException({
        code: 'INVALID_MESSAGE_BODY',
        message:
          'Сообщение должно содержать от 1 до 2000 символов без служебных символов',
      });
    }
    const now = new Date();
    const result = await this.prisma.$transaction(async (tx) => {
      const actorRateLock = `booking-chat-rate:${actorId}`;
      const idempotencyLock = `${actorId}:${dto.clientMessageId}`;
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${actorRateLock}))`;
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${idempotencyLock}))`;
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;

      const booking = await this.requireParticipant(tx, actorId, bookingId);
      const repeated = await tx.bookingMessage.findUnique({
        where: {
          authorId_clientMessageId: {
            authorId: actorId,
            clientMessageId: dto.clientMessageId,
          },
        },
        select: MESSAGE_SELECT,
      });
      if (repeated) {
        if (repeated.bookingId !== bookingId || repeated.body !== body) {
          throw new ConflictException({
            code: 'IDEMPOTENCY_KEY_REUSED',
            message: 'Идентификатор сообщения уже использован',
          });
        }
        return { booking, message: repeated };
      }

      if (!this.canWrite(booking.status, booking.expiresAt, now)) {
        throw new ConflictException({
          code: 'BOOKING_CHAT_READ_ONLY',
          message:
            'В этом состоянии бронирования чат доступен только для чтения',
        });
      }
      const recipientId =
        booking.borrowerId === actorId ? booking.lenderId : booking.borrowerId;
      const recipient =
        booking.borrowerId === recipientId ? booking.borrower : booking.lender;
      if (recipient.deletedAt || recipient.isBlocked) {
        throw new ConflictException({
          code: 'BOOKING_CHAT_READ_ONLY',
          message:
            'В этом состоянии бронирования чат доступен только для чтения',
        });
      }
      const interactionBlock = await tx.userBlock.findFirst({
        where: {
          OR: [
            { blockerId: actorId, blockedId: recipientId },
            { blockerId: recipientId, blockedId: actorId },
          ],
        },
        select: { id: true },
      });
      if (interactionBlock) {
        throw new ConflictException({
          code: 'BOOKING_CHAT_BLOCKED',
          message: 'Отправка сообщений между участниками недоступна',
        });
      }

      const rateWindowStart = new Date(
        now.getTime() - BOOKING_CHAT_RATE_WINDOW_MS,
      );
      const [bookingRateCount, actorRateCount] = await Promise.all([
        tx.bookingMessage.count({
          where: {
            bookingId,
            authorId: actorId,
            createdAt: { gte: rateWindowStart },
          },
        }),
        tx.bookingMessage.count({
          where: {
            authorId: actorId,
            createdAt: { gte: rateWindowStart },
          },
        }),
      ]);
      if (
        bookingRateCount >= BOOKING_CHAT_MAX_PER_BOOKING_WINDOW ||
        actorRateCount >= BOOKING_CHAT_MAX_PER_ACTOR_WINDOW
      ) {
        throw new TooManyRequestsException(
          'Слишком много сообщений. Попробуйте через минуту',
        );
      }

      const authorRole =
        booking.borrowerId === actorId
          ? BookingMessageAuthorRole.BORROWER
          : BookingMessageAuthorRole.LENDER;
      const message = await tx.bookingMessage.create({
        data: {
          bookingId,
          authorId: actorId,
          authorRole,
          clientMessageId: dto.clientMessageId,
          body,
        },
        select: MESSAGE_SELECT,
      });
      await tx.notificationOutboxEvent.create({
        data: {
          bookingId,
          recipientId,
          eventType: 'BOOKING_MESSAGE_CREATED',
          deduplicationKey: `booking:${bookingId}:message:${message.id}`,
        },
      });
      return { booking, message };
    });

    return this.toResponse(actorId, result.booking, result.message);
  }

  async markRead(
    actorId: string,
    bookingId: string,
  ): Promise<BookingMessageReadResponseDto> {
    await this.requireParticipant(this.prisma, actorId, bookingId);
    const readAt = new Date();
    const updated = await this.prisma.inboxEvent.updateMany({
      where: {
        recipientId: actorId,
        bookingId,
        eventType: 'BOOKING_MESSAGE_CREATED',
        readAt: null,
      },
      data: { readAt },
    });
    return { readAt, updatedCount: updated.count };
  }

  private async requireParticipant(
    db: Pick<PrismaService, 'booking'>,
    actorId: string,
    bookingId: string,
  ) {
    const booking = await db.booking.findFirst({
      where: {
        id: bookingId,
        OR: [{ borrowerId: actorId }, { lenderId: actorId }],
      },
      select: {
        id: true,
        borrowerId: true,
        lenderId: true,
        status: true,
        expiresAt: true,
        borrower: { select: { deletedAt: true, isBlocked: true } },
        lender: { select: { deletedAt: true, isBlocked: true } },
      },
    });
    if (!booking) {
      throw new NotFoundException('Бронирование не найдено');
    }
    return booking;
  }

  private canWrite(
    status: BookingStatus,
    expiresAt: Date | null,
    now: Date,
  ): boolean {
    if (status === BookingStatus.PENDING) {
      return expiresAt !== null && expiresAt > now;
    }
    return WRITABLE_STATUSES.has(status);
  }

  private toResponse(
    actorId: string,
    booking: { borrowerId: string; lenderId: string },
    message: MessageRow,
  ): BookingMessageResponseDto {
    const actorRole =
      booking.borrowerId === actorId
        ? BookingMessageAuthorRole.BORROWER
        : BookingMessageAuthorRole.LENDER;
    const author: BookingMessageAuthor =
      message.authorRole === BookingMessageAuthorRole.SYSTEM
        ? 'SYSTEM'
        : message.authorRole === actorRole
          ? 'SELF'
          : 'COUNTERPARTY';
    return {
      id: message.id,
      bookingId: message.bookingId,
      author,
      clientMessageId: author === 'SELF' ? message.clientMessageId : null,
      body: message.body,
      createdAt: message.createdAt,
    };
  }
}

function containsUnsafeControlCharacter(value: string): boolean {
  for (const character of value) {
    const codePoint = character.codePointAt(0);
    if (
      codePoint === undefined ||
      codePoint <= 8 ||
      codePoint === 11 ||
      codePoint === 12 ||
      (codePoint >= 14 && codePoint <= 31) ||
      codePoint === 127
    ) {
      return true;
    }
  }
  return false;
}
