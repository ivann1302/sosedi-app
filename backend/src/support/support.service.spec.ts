import { ConflictException } from '@nestjs/common';
import {
  BookingIssueReason,
  BookingStatus,
  SupportTicketStatus,
  SupportTicketType,
  type SupportTicket,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { SupportService } from './support.service';

type TestBookingIssueContext = {
  id: string;
  borrowerId: string;
  lenderId: string;
  status: BookingStatus;
  startDate: Date;
  endDate: Date;
};

type SupportTicketFindManyArgs = {
  where: { userId?: string; type?: SupportTicketType };
  select?: {
    user?: {
      select?: { id?: boolean; name?: boolean; phone?: boolean };
    };
  };
};

function createService() {
  const tickets: SupportTicket[] = [];
  const messages: Array<{
    id: string;
    ticketId: string;
    authorId: string;
    authorRole: 'USER' | 'SUPPORT';
    body: string;
    attachments: unknown[];
    createdAt: Date;
  }> = [];
  const auditLogs: unknown[] = [];
  const notificationOutboxCreate = jest.fn(({ data }: { data: unknown }) =>
    Promise.resolve({ id: 'outbox-1', data }),
  );
  const bookingFindFirst = jest.fn<
    Promise<TestBookingIssueContext | null>,
    [unknown]
  >();
  const supportTicketFindMany = jest.fn(
    ({ where }: SupportTicketFindManyArgs) => {
      return Promise.resolve(
        tickets.filter(
          (ticket) =>
            (where.userId === undefined || ticket.userId === where.userId) &&
            (where.type === undefined || ticket.type === where.type),
        ),
      );
    },
  );
  const prismaMock = {
    supportTicket: {
      create: jest.fn(
        ({
          data,
        }: {
          data: Pick<
            SupportTicket,
            | 'userId'
            | 'subject'
            | 'message'
            | 'type'
            | 'bookingId'
            | 'bookingIssueReason'
          >;
        }) => {
          const ticket: SupportTicket = {
            id: `ticket-${tickets.length + 1}`,
            status: SupportTicketStatus.OPEN,
            adminResponse: null,
            assigneeId: null,
            respondedById: null,
            respondedAt: null,
            createdAt: new Date('2026-07-29T03:00:00.000Z'),
            updatedAt: new Date('2026-07-29T03:00:00.000Z'),
            ...data,
            bookingId: data.bookingId ?? null,
            bookingIssueReason: data.bookingIssueReason ?? null,
          };
          tickets.push(ticket);
          return Promise.resolve(ticket);
        },
      ),
      findMany: supportTicketFindMany,
      findFirst: jest.fn(({ where }: { where: { id: string } }) => {
        const ticket = tickets.find((candidate) => candidate.id === where.id);
        return Promise.resolve(ticket ? { ...ticket } : null);
      }),
      updateMany: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<SupportTicket>;
        }) => {
          const ticket = tickets.find(
            (candidate) =>
              candidate.id === where.id && !candidate.adminResponse,
          );
          if (!ticket) {
            return Promise.resolve({ count: 0 });
          }
          Object.assign(ticket, data);
          return Promise.resolve({ count: 1 });
        },
      ),
      findUniqueOrThrow: jest.fn(({ where }: { where: { id: string } }) => {
        const ticket = tickets.find((candidate) => candidate.id === where.id);
        if (!ticket) {
          throw new Error('Ticket not found');
        }
        return Promise.resolve(ticket);
      }),
    },
    booking: {
      findFirst: bookingFindFirst,
    },
    supportMessage: {
      create: jest.fn(
        ({
          data,
        }: {
          data: {
            ticketId: string;
            authorId: string;
            authorRole: 'USER' | 'SUPPORT';
            body: string;
          };
        }) => {
          const message = {
            id: `message-${messages.length + 1}`,
            ...data,
            attachments: [],
            createdAt: new Date('2026-07-29T03:10:00.000Z'),
          };
          messages.push(message);
          return Promise.resolve(message);
        },
      ),
      findMany: jest.fn(({ where }: { where: { ticketId: string } }) => {
        return Promise.resolve(
          messages.filter((message) => message.ticketId === where.ticketId),
        );
      }),
    },
    notificationOutboxEvent: {
      create: notificationOutboxCreate,
    },
    adminAuditLog: {
      create: jest.fn(({ data }: { data: unknown }) => {
        auditLogs.push(data);
        return Promise.resolve(data);
      }),
    },
    $transaction: jest.fn(
      (callback: (tx: typeof prismaMock) => Promise<unknown>) =>
        callback(prismaMock),
    ),
  };
  const prisma = prismaMock as unknown as PrismaService;

  const upload = {
    verifySupportAttachmentIntent: jest.fn(),
  } as unknown as UploadService;

  return {
    service: new SupportService(prisma, upload),
    tickets,
    messages,
    auditLogs,
    bookingFindFirst,
    notificationOutboxCreate,
    supportTicketFindMany,
  };
}

describe('SupportService', () => {
  it('creates a general request without requiring booking or payment state', async () => {
    const { service } = createService();

    await expect(
      service.create('user-after-completed-booking', {
        subject: 'Вопрос после аренды',
        message: 'Нужна помощь после завершения бронирования.',
      }),
    ).resolves.toMatchObject({
      type: SupportTicketType.GENERAL,
      status: SupportTicketStatus.OPEN,
    });
  });

  it('creates only a general ticket and normalizes surrounding whitespace', async () => {
    const { service } = createService();

    await expect(
      service.create('user-1', {
        subject: '  Вопрос по передаче  ',
        message: '  Нужна помощь со временем встречи.  ',
      }),
    ).resolves.toMatchObject({
      userId: 'user-1',
      type: SupportTicketType.GENERAL,
      subject: 'Вопрос по передаче',
      message: 'Нужна помощь со временем встречи.',
    });
  });

  it('creates a structured no-show issue only for the affected participant', async () => {
    const { service, bookingFindFirst } = createService();
    bookingFindFirst.mockResolvedValue({
      id: 'booking-1',
      borrowerId: 'borrower-1',
      lenderId: 'lender-1',
      status: BookingStatus.CONFIRMED,
      startDate: new Date('2026-07-29T00:00:00.000Z'),
      endDate: new Date('2026-07-30T00:00:00.000Z'),
    });

    await expect(
      service.create(
        'borrower-1',
        {
          bookingId: '11111111-1111-4111-8111-111111111111',
          bookingIssueReason: BookingIssueReason.OWNER_NO_SHOW,
          subject: 'Владелец не пришёл',
          message: 'Я нахожусь в согласованном месте, владельца вещи нет.',
        },
        new Date('2026-07-29T09:00:00.000Z'),
      ),
    ).resolves.toMatchObject({
      bookingId: '11111111-1111-4111-8111-111111111111',
      bookingIssueReason: BookingIssueReason.OWNER_NO_SHOW,
      type: SupportTicketType.GENERAL,
    });

    await expect(
      service.create(
        'lender-1',
        {
          bookingId: '11111111-1111-4111-8111-111111111111',
          bookingIssueReason: BookingIssueReason.OWNER_NO_SHOW,
          subject: 'Некорректная причина',
          message: 'Владелец не может пожаловаться на собственную неявку.',
        },
        new Date('2026-07-29T09:00:00.000Z'),
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it.each([
    {
      reason: BookingIssueReason.BORROWER_NO_SHOW,
      allowedActor: 'lender-1',
      deniedActor: 'borrower-1',
    },
    {
      reason: BookingIssueReason.ITEM_FAULTY,
      allowedActor: 'borrower-1',
      deniedActor: 'lender-1',
    },
  ])(
    'enforces the affected participant for $reason',
    async ({ reason, allowedActor, deniedActor }) => {
      const { service, bookingFindFirst } = createService();
      bookingFindFirst.mockResolvedValue({
        id: 'booking-1',
        borrowerId: 'borrower-1',
        lenderId: 'lender-1',
        status: BookingStatus.CONFIRMED,
        startDate: new Date('2026-07-29T00:00:00.000Z'),
        endDate: new Date('2026-07-30T00:00:00.000Z'),
      });
      const dto = {
        bookingId: '11111111-1111-4111-8111-111111111111',
        bookingIssueReason: reason,
        subject: 'Проблема при передаче',
        message: 'Нужна ручная помощь поддержки по подтверждённой аренде.',
      };

      await expect(
        service.create(allowedActor, dto, new Date('2026-07-29T09:00:00.000Z')),
      ).resolves.toMatchObject({ bookingIssueReason: reason });
      await expect(
        service.create(deniedActor, dto, new Date('2026-07-29T09:00:00.000Z')),
      ).rejects.toBeInstanceOf(ConflictException);
    },
  );

  it.each([
    {
      reason: BookingIssueReason.EARLY_RETURN,
      now: new Date('2026-07-29T09:00:00.000Z'),
    },
    {
      reason: BookingIssueReason.LATE_RETURN,
      now: new Date('2026-08-01T09:00:00.000Z'),
    },
    {
      reason: BookingIssueReason.ITEM_DAMAGED,
      now: new Date('2026-07-30T09:00:00.000Z'),
    },
    {
      reason: BookingIssueReason.ITEM_LOST,
      now: new Date('2026-07-30T09:00:00.000Z'),
    },
  ])(
    'accepts manual $reason handling without changing Booking',
    async ({ reason, now }) => {
      const { service, bookingFindFirst } = createService();
      bookingFindFirst.mockResolvedValue({
        id: 'booking-1',
        borrowerId: 'borrower-1',
        lenderId: 'lender-1',
        status: BookingStatus.ACTIVE,
        startDate: new Date('2026-07-28T00:00:00.000Z'),
        endDate: new Date('2026-07-31T00:00:00.000Z'),
      });

      await expect(
        service.create(
          'borrower-1',
          {
            bookingId: '11111111-1111-4111-8111-111111111111',
            bookingIssueReason: reason,
            subject: 'Проблема с возвратом',
            message: 'Нужна ручная помощь поддержки по текущей аренде.',
          },
          now,
        ),
      ).resolves.toMatchObject({ bookingIssueReason: reason });
    },
  );

  it('lists only the authenticated user general tickets', async () => {
    const { service, tickets } = createService();
    await service.create('user-1', {
      subject: 'Первый вопрос',
      message: 'Достаточно длинное описание вопроса.',
    });
    tickets.push({
      id: 'ticket-2',
      userId: 'user-2',
      bookingId: null,
      bookingIssueReason: null,
      type: SupportTicketType.GENERAL,
      subject: 'Чужой вопрос',
      message: 'Это обращение другого пользователя.',
      status: SupportTicketStatus.OPEN,
      createdAt: new Date('2026-07-29T03:00:00.000Z'),
      updatedAt: new Date('2026-07-29T03:00:00.000Z'),
    });
    tickets.push({
      id: 'ticket-3',
      userId: 'user-1',
      bookingId: null,
      bookingIssueReason: null,
      type: SupportTicketType.DISPUTE,
      subject: 'Будущий финансовый спор',
      message: 'Не должен попадать в API обычной поддержки.',
      status: SupportTicketStatus.OPEN,
      adminResponse: null,
      assigneeId: null,
      respondedById: null,
      respondedAt: null,
      createdAt: new Date('2026-07-29T03:00:00.000Z'),
      updatedAt: new Date('2026-07-29T03:00:00.000Z'),
    });

    await expect(service.listMine('user-1')).resolves.toHaveLength(1);
  });

  it('does not select the user phone for the support queue', async () => {
    const { service, supportTicketFindMany } = createService();

    await service.listForAdmin();

    const select = supportTicketFindMany.mock.calls[0]?.[0].select;
    expect(select?.user?.select).toEqual({
      id: true,
      name: true,
    });
  });

  it('stores one admin reply and writes an audit record without message content', async () => {
    const { service, auditLogs, notificationOutboxCreate } = createService();
    const ticket = await service.create('user-1', {
      subject: 'Вопрос по встрече',
      message: 'Достаточно длинное описание вопроса.',
    });

    await expect(
      service.replyAsAdmin(
        'admin-1',
        ticket.id,
        { message: '  Мы связались со второй стороной.  ' },
        {
          requestId: 'request-1',
          ipAddress: '127.0.0.1',
          deviceId: 'operator-1',
        },
      ),
    ).resolves.toMatchObject({
      status: SupportTicketStatus.IN_PROGRESS,
      adminResponse: 'Мы связались со второй стороной.',
      respondedById: 'admin-1',
    });
    expect(auditLogs).toEqual([
      expect.objectContaining({
        action: 'SUPPORT_TICKET_REPLIED',
        entityId: ticket.id,
      }),
    ]);
    expect(JSON.stringify(auditLogs)).not.toContain('связались');
    expect(notificationOutboxCreate).toHaveBeenCalledWith({
      data: {
        supportTicketId: ticket.id,
        eventType: 'SUPPORT_REPLIED',
        deduplicationKey: `support:${ticket.id}:first-reply`,
      },
    });
  });

  it('assigns an open ticket to the current support operator', async () => {
    const { service, auditLogs } = createService();
    const ticket = await service.create('user-1', {
      subject: 'Вопрос по встрече',
      message: 'Достаточно длинное описание вопроса.',
    });

    await expect(
      service.assignToSelf('admin-1', ticket.id, {
        requestId: 'request-2',
        ipAddress: '127.0.0.1',
        deviceId: 'operator-1',
      }),
    ).resolves.toMatchObject({
      status: SupportTicketStatus.IN_PROGRESS,
      assigneeId: 'admin-1',
    });
    expect(auditLogs).toEqual([
      expect.objectContaining({
        action: 'SUPPORT_TICKET_ASSIGNED',
        entityId: ticket.id,
      }),
    ]);
  });

  it('closes a general ticket atomically with PII-free audit and inbox event', async () => {
    const { service, auditLogs, notificationOutboxCreate } = createService();
    const ticket = await service.create('user-1', {
      subject: 'Вопрос по встрече',
      message: 'Достаточно длинное описание вопроса.',
    });

    await expect(
      service.closeAsAdmin('admin-1', ticket.id, {
        requestId: 'request-3',
        ipAddress: '127.0.0.1',
        deviceId: 'operator-1',
      }),
    ).resolves.toMatchObject({
      status: SupportTicketStatus.CLOSED,
      assigneeId: 'admin-1',
    });
    expect(auditLogs).toEqual([
      expect.objectContaining({
        action: 'SUPPORT_TICKET_CLOSED',
        entityId: ticket.id,
        before: { status: SupportTicketStatus.OPEN, assigneeId: null },
        after: {
          status: SupportTicketStatus.CLOSED,
          assigneeId: 'admin-1',
        },
      }),
    ]);
    expect(JSON.stringify(auditLogs)).not.toContain(ticket.message);
    expect(notificationOutboxCreate).toHaveBeenCalledWith({
      data: {
        supportTicketId: ticket.id,
        eventType: 'SUPPORT_TICKET_CLOSED',
        deduplicationKey: `support:${ticket.id}:closed`,
      },
    });
    await expect(
      service.createMessage(
        'user-1',
        ticket.id,
        { body: 'Попытка написать в закрытое обращение.' },
        false,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('does not let one support operator close another operator ticket', async () => {
    const { service } = createService();
    const ticket = await service.create('user-1', {
      subject: 'Вопрос по встрече',
      message: 'Достаточно длинное описание вопроса.',
    });
    await service.assignToSelf('admin-1', ticket.id, {
      requestId: 'request-4',
      ipAddress: '127.0.0.1',
      deviceId: 'operator-1',
    });

    await expect(
      service.closeAsAdmin('admin-2', ticket.id, {
        requestId: 'request-5',
        ipAddress: '127.0.0.2',
        deviceId: 'operator-2',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
