import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  InboxEventDetailsResponseDto,
  InboxEventResponseDto,
} from './dto/inbox-event-response.dto';

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
}
