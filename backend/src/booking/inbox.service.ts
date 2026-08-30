import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  InboxEventDetailsResponseDto,
  InboxPageResponseDto,
  InboxEventResponseDto,
} from './dto/inbox-event-response.dto';
import { InboxPageQueryDto } from './dto/inbox-page-query.dto';

const DEFAULT_PAGE_LIMIT = 20;

@Injectable()
export class InboxService {
  constructor(private readonly prisma: PrismaService) {}

  async list(recipientId: string): Promise<InboxEventResponseDto[]> {
    return this.prisma.inboxEvent.findMany({
      where: { recipientId },
      select: {
        eventId: true,
        bookingId: true,
        supportTicketId: true,
        itemId: true,
        eventType: true,
        readAt: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listPage(
    recipientId: string,
    query: InboxPageQueryDto,
  ): Promise<InboxPageResponseDto> {
    const limit = query.limit ?? DEFAULT_PAGE_LIMIT;
    if (query.cursor) {
      const cursor = await this.prisma.inboxEvent.findFirst({
        where: { id: query.cursor, recipientId },
        select: { id: true },
      });
      if (!cursor) {
        throw new NotFoundException('Страница событий не найдена');
      }
    }

    const rows = await this.prisma.inboxEvent.findMany({
      where: {
        recipientId,
        ...(query.unreadOnly ? { readAt: null } : {}),
      },
      select: {
        id: true,
        eventId: true,
        bookingId: true,
        supportTicketId: true,
        itemId: true,
        eventType: true,
        readAt: true,
        createdAt: true,
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      cursor: query.cursor ? { id: query.cursor } : undefined,
      skip: query.cursor ? 1 : undefined,
    });
    const hasMore = rows.length > limit;
    const pageRows = hasMore ? rows.slice(0, limit) : rows;

    return {
      items: pageRows.map((row) => ({
        eventId: row.eventId,
        bookingId: row.bookingId,
        supportTicketId: row.supportTicketId,
        itemId: row.itemId,
        eventType: row.eventType,
        readAt: row.readAt,
        createdAt: row.createdAt,
      })),
      nextCursor: hasMore ? (pageRows.at(-1)?.id ?? null) : null,
    };
  }

  async getDetails(
    recipientId: string,
    eventId: string,
  ): Promise<InboxEventDetailsResponseDto> {
    const event = await this.prisma.inboxEvent.findFirst({
      where: {
        eventId,
        recipientId,
        OR: [
          {
            booking: {
              is: {
                OR: [{ borrowerId: recipientId }, { lenderId: recipientId }],
              },
            },
          },
          { supportTicket: { is: { userId: recipientId } } },
          { item: { is: { ownerId: recipientId } } },
        ],
      },
      select: {
        eventId: true,
        bookingId: true,
        supportTicketId: true,
        itemId: true,
        eventType: true,
        readAt: true,
        createdAt: true,
        booking: {
          select: {
            id: true,
            itemId: true,
            startDate: true,
            endDate: true,
            totalAmount: true,
            status: true,
            expiresAt: true,
            cancellationReason: true,
          },
        },
        supportTicket: {
          select: {
            id: true,
            subject: true,
            status: true,
            updatedAt: true,
          },
        },
      },
    });
    if (!event) {
      throw new NotFoundException('Событие не найдено');
    }

    return {
      ...event,
      booking: event.booking
        ? {
            ...event.booking,
            totalAmount: event.booking.totalAmount.toNumber(),
          }
        : null,
    };
  }

  async markRead(
    recipientId: string,
    eventId: string,
  ): Promise<InboxEventResponseDto> {
    const event = await this.prisma.inboxEvent.findUnique({
      where: { eventId_recipientId: { eventId, recipientId } },
      select: { id: true, readAt: true },
    });
    if (!event) {
      throw new NotFoundException('Событие не найдено');
    }

    return this.prisma.inboxEvent.update({
      where: { id: event.id },
      data: { readAt: event.readAt ?? new Date() },
      select: {
        eventId: true,
        bookingId: true,
        supportTicketId: true,
        itemId: true,
        eventType: true,
        readAt: true,
        createdAt: true,
      },
    });
  }

  async markAllRead(recipientId: string): Promise<{ updated: number }> {
    const result = await this.prisma.inboxEvent.updateMany({
      where: { recipientId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: result.count };
  }
}
