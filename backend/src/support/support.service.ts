import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminCapability,
  BookingIssueReason,
  BookingStatus,
  Prisma,
  SupportTicketStatus,
  SupportTicketType,
} from '@prisma/client';
import type { AdminAuditContext } from '../admin/admin-audit-context';
import { moscowCalendarDate } from '../booking/booking-period';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { CreateSupportMessageDto } from './dto/create-support-message.dto';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';
import { ReplySupportTicketDto } from './dto/reply-support-ticket.dto';
import { SupportMessageResponseDto } from './dto/support-message-response.dto';
import { SupportTicketResponseDto } from './dto/support-ticket-response.dto';

export type AdminSupportTicketResponse = SupportTicketResponseDto & {
  user: {
    id: string;
    name: string | null;
  };
  assignee: {
    id: string;
    name: string | null;
  } | null;
};

export type AdminBookingChatMessageResponse = {
  id: string;
  bookingId: string;
  authorRole: string;
  body: string;
  createdAt: Date;
};

@Injectable()
export class SupportService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly upload: UploadService,
  ) {}

  async create(
    userId: string,
    dto: CreateSupportTicketDto,
    now = new Date(),
  ): Promise<SupportTicketResponseDto> {
    const hasBookingId = dto.bookingId !== undefined;
    const hasIssueReason = dto.bookingIssueReason !== undefined;
    if (hasBookingId !== hasIssueReason) {
      throw new BadRequestException(
        'bookingId и bookingIssueReason должны передаваться вместе',
      );
    }
    if (dto.bookingId && dto.bookingIssueReason) {
      const booking = await this.prisma.booking.findFirst({
        where: {
          id: dto.bookingId,
          OR: [{ borrowerId: userId }, { lenderId: userId }],
        },
        select: {
          id: true,
          borrowerId: true,
          lenderId: true,
          status: true,
          startDate: true,
          endDate: true,
        },
      });
      if (!booking) {
        throw new NotFoundException('Бронирование не найдено');
      }
      this.validateBookingIssue(userId, booking, dto.bookingIssueReason, now);
    }

    return this.prisma.supportTicket.create({
      data: {
        userId,
        bookingId: dto.bookingId,
        bookingIssueReason: dto.bookingIssueReason,
        type: SupportTicketType.GENERAL,
        subject: dto.subject.trim(),
        message: dto.message.trim(),
      },
      select: SUPPORT_TICKET_SELECT,
    });
  }

  private validateBookingIssue(
    actorId: string,
    booking: {
      borrowerId: string;
      lenderId: string;
      status: BookingStatus;
      startDate: Date;
      endDate: Date;
    },
    reason: BookingIssueReason,
    now: Date,
  ): void {
    const isBorrower = booking.borrowerId === actorId;
    const today = moscowCalendarDate(now);
    const startDate = booking.startDate.toISOString().slice(0, 10);
    const endDate = booking.endDate.toISOString().slice(0, 10);
    let allowed = false;

    if (reason === BookingIssueReason.OWNER_NO_SHOW) {
      allowed =
        isBorrower &&
        booking.status === BookingStatus.CONFIRMED &&
        today >= startDate;
    } else if (reason === BookingIssueReason.BORROWER_NO_SHOW) {
      allowed =
        !isBorrower &&
        booking.status === BookingStatus.CONFIRMED &&
        today >= startDate;
    } else if (reason === BookingIssueReason.ITEM_FAULTY) {
      allowed =
        isBorrower &&
        booking.status === BookingStatus.CONFIRMED &&
        today >= startDate;
    } else if (reason === BookingIssueReason.EARLY_RETURN) {
      allowed = booking.status === BookingStatus.ACTIVE && today < endDate;
    } else if (reason === BookingIssueReason.LATE_RETURN) {
      allowed = booking.status === BookingStatus.ACTIVE && today > endDate;
    } else {
      allowed =
        booking.status === BookingStatus.ACTIVE ||
        booking.status === BookingStatus.RETURNED;
    }

    if (!allowed) {
      throw new ConflictException({
        code: 'BOOKING_ISSUE_NOT_ALLOWED',
        message:
          'Причина недоступна для этой стороны, даты или состояния бронирования',
      });
    }
  }

  listMine(userId: string): Promise<SupportTicketResponseDto[]> {
    return this.prisma.supportTicket.findMany({
      where: { userId, type: SupportTicketType.GENERAL },
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      select: SUPPORT_TICKET_SELECT,
    });
  }

  async listMessages(
    actorId: string,
    ticketId: string,
    allowAdmin: boolean,
  ): Promise<SupportMessageResponseDto[]> {
    await this.getAccessibleTicket(actorId, ticketId, allowAdmin);
    return this.prisma.supportMessage.findMany({
      where: { ticketId },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: SUPPORT_MESSAGE_SELECT,
    });
  }

  async listBookingChatForAdmin(
    adminId: string,
    ticketId: string,
    context: AdminAuditContext,
  ): Promise<AdminBookingChatMessageResponse[]> {
    return this.prisma.$transaction(async (tx) => {
      const ticket = await tx.supportTicket.findFirst({
        where: {
          id: ticketId,
          type: SupportTicketType.GENERAL,
          bookingId: { not: null },
        },
        select: { id: true, bookingId: true },
      });
      if (!ticket?.bookingId) {
        throw new NotFoundException('Обращение по бронированию не найдено');
      }
      const newest = await tx.bookingMessage.findMany({
        where: { bookingId: ticket.bookingId },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: 100,
        select: {
          id: true,
          bookingId: true,
          authorRole: true,
          body: true,
          createdAt: true,
        },
      });
      await tx.adminAuditLog.create({
        data: {
          adminId,
          action: 'SUPPORT_BOOKING_CHAT_ACCESSED',
          entityType: 'SupportTicket',
          entityId: ticket.id,
          capability: AdminCapability.SUPPORT,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          metadata: {
            bookingId: ticket.bookingId,
            messageCount: newest.length,
          },
        },
      });
      return newest.reverse();
    });
  }

  async createMessage(
    actorId: string,
    ticketId: string,
    dto: CreateSupportMessageDto,
    allowAdmin: boolean,
    context?: AdminAuditContext,
  ): Promise<SupportMessageResponseDto> {
    const ticket = await this.getAccessibleTicket(
      actorId,
      ticketId,
      allowAdmin,
    );
    if (ticket.status === SupportTicketStatus.CLOSED) {
      throw new ConflictException('Обращение уже закрыто');
    }
    if (allowAdmin && ticket.assigneeId && ticket.assigneeId !== actorId) {
      throw new ConflictException('Обращение назначено другому оператору');
    }

    const attachments = await Promise.all(
      dto.attachmentIntentIds.map((intentId) =>
        this.upload.verifySupportAttachmentIntent(
          actorId,
          ticketId,
          intentId,
          allowAdmin,
        ),
      ),
    );

    return this.prisma.$transaction(async (tx) => {
      const confirmedAt = new Date();
      for (const attachment of attachments) {
        const consumed = await tx.uploadIntent.updateMany({
          where: {
            id: attachment.intentId,
            actorId,
            entityId: ticketId,
            confirmedAt: null,
            expiresAt: { gt: confirmedAt },
          },
          data: { confirmedAt },
        });
        if (consumed.count !== 1) {
          throw new ConflictException(
            'Upload intent уже использован или истёк',
          );
        }
      }

      const message = await tx.supportMessage.create({
        data: {
          ticketId,
          authorId: actorId,
          authorRole: allowAdmin ? 'SUPPORT' : 'USER',
          body: dto.body.trim(),
          attachments: {
            create: attachments.map((attachment) => ({
              uploadIntentId: attachment.intentId,
              storageKey: attachment.objectKey,
              sha256: attachment.sha256,
            })),
          },
        },
        select: SUPPORT_MESSAGE_SELECT,
      });

      if (allowAdmin) {
        await tx.supportTicket.update({
          where: { id: ticketId },
          data: {
            assigneeId: actorId,
            status: SupportTicketStatus.IN_PROGRESS,
          },
        });
        await tx.notificationOutboxEvent.create({
          data: {
            supportTicketId: ticketId,
            eventType: 'SUPPORT_MESSAGE_CREATED',
            deduplicationKey: `support:${ticketId}:message:${message.id}`,
          },
        });
        await tx.adminAuditLog.create({
          data: {
            adminId: actorId,
            action: 'SUPPORT_MESSAGE_CREATED',
            entityType: 'SupportTicket',
            entityId: ticketId,
            capability: AdminCapability.SUPPORT,
            requestId: context?.requestId,
            ipAddress: context?.ipAddress,
            deviceId: context?.deviceId,
            metadata: { attachmentCount: attachments.length },
          },
        });
      }
      return message;
    });
  }

  listForAdmin(): Promise<AdminSupportTicketResponse[]> {
    return this.prisma.supportTicket.findMany({
      where: { type: SupportTicketType.GENERAL },
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      select: ADMIN_SUPPORT_TICKET_SELECT,
    });
  }

  async assignToSelf(
    adminId: string,
    ticketId: string,
    context: AdminAuditContext,
  ): Promise<AdminSupportTicketResponse> {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.supportTicket.findFirst({
        where: { id: ticketId, type: SupportTicketType.GENERAL },
        select: { id: true, status: true, assigneeId: true },
      });
      if (!existing) {
        throw new NotFoundException('Обращение не найдено');
      }
      if (existing.status === SupportTicketStatus.CLOSED) {
        throw new ConflictException('Обращение уже закрыто');
      }
      if (existing.assigneeId && existing.assigneeId !== adminId) {
        throw new ConflictException('Обращение уже назначено');
      }

      if (!existing.assigneeId) {
        const updated = await tx.supportTicket.updateMany({
          where: { id: ticketId, assigneeId: null },
          data: {
            assigneeId: adminId,
            status: SupportTicketStatus.IN_PROGRESS,
          },
        });
        if (updated.count !== 1) {
          throw new ConflictException('Обращение уже назначено');
        }

        await tx.adminAuditLog.create({
          data: {
            adminId,
            action: 'SUPPORT_TICKET_ASSIGNED',
            entityType: 'SupportTicket',
            entityId: ticketId,
            capability: AdminCapability.SUPPORT,
            requestId: context.requestId,
            ipAddress: context.ipAddress,
            deviceId: context.deviceId,
            before: { assigneeId: null, status: existing.status },
            after: {
              assigneeId: adminId,
              status: SupportTicketStatus.IN_PROGRESS,
            },
          },
        });
      }

      return tx.supportTicket.findUniqueOrThrow({
        where: { id: ticketId },
        select: ADMIN_SUPPORT_TICKET_SELECT,
      });
    });
  }

  async replyAsAdmin(
    adminId: string,
    ticketId: string,
    dto: ReplySupportTicketDto,
    context: AdminAuditContext,
  ): Promise<AdminSupportTicketResponse> {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.supportTicket.findFirst({
        where: { id: ticketId, type: SupportTicketType.GENERAL },
        select: {
          id: true,
          status: true,
          adminResponse: true,
          assigneeId: true,
        },
      });
      if (!existing) {
        throw new NotFoundException('Обращение не найдено');
      }
      if (
        existing.status === SupportTicketStatus.CLOSED ||
        existing.adminResponse
      ) {
        throw new ConflictException('На обращение уже дан ответ');
      }
      if (existing.assigneeId && existing.assigneeId !== adminId) {
        throw new ConflictException('Обращение назначено другому оператору');
      }

      const respondedAt = new Date();
      const updated = await tx.supportTicket.updateMany({
        where: {
          id: ticketId,
          type: SupportTicketType.GENERAL,
          status: { not: SupportTicketStatus.CLOSED },
          adminResponse: null,
        },
        data: {
          status: SupportTicketStatus.IN_PROGRESS,
          adminResponse: dto.message.trim(),
          assigneeId: adminId,
          respondedById: adminId,
          respondedAt,
        },
      });
      if (updated.count !== 1) {
        throw new ConflictException('На обращение уже дан ответ');
      }

      await tx.adminAuditLog.create({
        data: {
          adminId,
          action: 'SUPPORT_TICKET_REPLIED',
          entityType: 'SupportTicket',
          entityId: ticketId,
          capability: AdminCapability.SUPPORT,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          before: { status: existing.status, hasAdminResponse: false },
          after: {
            status: SupportTicketStatus.IN_PROGRESS,
            hasAdminResponse: true,
          },
        },
      });

      await tx.supportMessage.create({
        data: {
          ticketId,
          authorId: adminId,
          authorRole: 'SUPPORT',
          body: dto.message.trim(),
        },
      });
      await tx.notificationOutboxEvent.create({
        data: {
          supportTicketId: ticketId,
          eventType: 'SUPPORT_REPLIED',
          deduplicationKey: `support:${ticketId}:first-reply`,
        },
      });

      return tx.supportTicket.findUniqueOrThrow({
        where: { id: ticketId },
        select: ADMIN_SUPPORT_TICKET_SELECT,
      });
    });
  }

  async closeAsAdmin(
    adminId: string,
    ticketId: string,
    context: AdminAuditContext,
  ): Promise<AdminSupportTicketResponse> {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.supportTicket.findFirst({
        where: { id: ticketId, type: SupportTicketType.GENERAL },
        select: { id: true, status: true, assigneeId: true },
      });
      if (!existing) {
        throw new NotFoundException('Обращение не найдено');
      }
      if (existing.status === SupportTicketStatus.CLOSED) {
        throw new ConflictException('Обращение уже закрыто');
      }
      if (existing.assigneeId && existing.assigneeId !== adminId) {
        throw new ConflictException('Обращение назначено другому оператору');
      }

      const updated = await tx.supportTicket.updateMany({
        where: {
          id: ticketId,
          type: SupportTicketType.GENERAL,
          status: { not: SupportTicketStatus.CLOSED },
          OR: [{ assigneeId: null }, { assigneeId: adminId }],
        },
        data: {
          status: SupportTicketStatus.CLOSED,
          assigneeId: adminId,
        },
      });
      if (updated.count !== 1) {
        throw new ConflictException(
          'Обращение уже закрыто или назначено другому оператору',
        );
      }

      await tx.adminAuditLog.create({
        data: {
          adminId,
          action: 'SUPPORT_TICKET_CLOSED',
          entityType: 'SupportTicket',
          entityId: ticketId,
          capability: AdminCapability.SUPPORT,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          before: {
            status: existing.status,
            assigneeId: existing.assigneeId,
          },
          after: {
            status: SupportTicketStatus.CLOSED,
            assigneeId: adminId,
          },
        },
      });
      await tx.notificationOutboxEvent.create({
        data: {
          supportTicketId: ticketId,
          eventType: 'SUPPORT_TICKET_CLOSED',
          deduplicationKey: `support:${ticketId}:closed`,
        },
      });

      return tx.supportTicket.findUniqueOrThrow({
        where: { id: ticketId },
        select: ADMIN_SUPPORT_TICKET_SELECT,
      });
    });
  }

  private async getAccessibleTicket(
    actorId: string,
    ticketId: string,
    allowAdmin: boolean,
  ): Promise<{
    id: string;
    status: SupportTicketStatus;
    assigneeId: string | null;
  }> {
    const ticket = await this.prisma.supportTicket.findFirst({
      where: {
        id: ticketId,
        type: SupportTicketType.GENERAL,
        ...(allowAdmin ? {} : { userId: actorId }),
      },
      select: { id: true, status: true, assigneeId: true },
    });
    if (!ticket) {
      throw new NotFoundException('Обращение не найдено');
    }
    return ticket;
  }
}

const SUPPORT_TICKET_SELECT = {
  id: true,
  type: true,
  bookingId: true,
  bookingIssueReason: true,
  subject: true,
  message: true,
  status: true,
  adminResponse: true,
  respondedAt: true,
  createdAt: true,
  updatedAt: true,
} as const;

const ADMIN_SUPPORT_TICKET_SELECT = {
  ...SUPPORT_TICKET_SELECT,
  user: {
    select: {
      id: true,
      name: true,
    },
  },
  assignee: {
    select: {
      id: true,
      name: true,
    },
  },
} as const;

const SUPPORT_MESSAGE_SELECT = {
  id: true,
  authorRole: true,
  body: true,
  createdAt: true,
  attachments: {
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    select: {
      id: true,
      sha256: true,
      createdAt: true,
    },
  },
} satisfies Prisma.SupportMessageSelect;
