import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingIssueReason,
  BookingStatus,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  SupportTicketType,
  UserRole,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { PrismaService } from './../src/prisma/prisma.service';
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';
import sharp from 'sharp';
import { moscowCalendarDate } from '../src/booking/booking-period';

describe('Support (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;
  let attachmentBytes = Buffer.alloc(0);
  const storage = {
    getPrivateBucket: jest.fn(() => 'private-bucket'),
    createPresignedPostUpload: jest.fn(() =>
      Promise.resolve({
        uploadUrl: 'https://upload.test/support',
        fields: { key: 'signed-key' },
      }),
    ),
    inspectUploadedObject: jest.fn(() =>
      Promise.resolve({
        sizeBytes: attachmentBytes.length,
        contentType: 'image/jpeg',
        prefix: attachmentBytes,
      }),
    ),
    getObjectBuffer: jest.fn(() => Promise.resolve(attachmentBytes)),
    putObject: jest.fn(() => Promise.resolve(undefined)),
    createPresignedDownloadUrl: jest.fn(() =>
      Promise.resolve('https://download.test/support'),
    ),
  };

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    return app.getHttpServer();
  }

  beforeAll(async () => {
    attachmentBytes = await sharp({
      create: {
        width: 2,
        height: 2,
        channels: 3,
        background: '#0f766e',
      },
    })
      .jpeg()
      .toBuffer();
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(S3StorageService)
      .useValue(storage)
      .compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
    jwt = app.get(JwtService);
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    jest.clearAllMocks();
    await resetTestState(app);
  });

  it('creates a general ticket and lists only the authenticated user tickets', async () => {
    const [user, anotherUser] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990008001', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990008002', role: UserRole.USER },
      }),
    ]);
    await prisma.supportTicket.create({
      data: {
        userId: anotherUser.id,
        type: SupportTicketType.GENERAL,
        subject: 'Чужое обращение',
        message: 'Приватное обращение другого пользователя.',
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      { secret: 'e2e-access-secret', expiresIn: '15m' },
    );
    const authorization = `Bearer ${accessToken}`;
    const anotherAuthorization = `Bearer ${await jwt.signAsync(
      {
        sub: anotherUser.id,
        phone: anotherUser.phone,
        role: anotherUser.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      { secret: 'e2e-access-secret', expiresIn: '15m' },
    )}`;

    const createResponse = await request(httpServer())
      .post('/api/v1/support/tickets')
      .set('Authorization', authorization)
      .send({
        subject: 'Вопрос по передаче',
        message: 'Нужна помощь со временем встречи.',
      })
      .expect(201);

    const created = asRecord(asRecord(createResponse.body as unknown).data);
    expect(created).toMatchObject({
      type: 'GENERAL',
      status: 'OPEN',
      subject: 'Вопрос по передаче',
    });

    const listResponse = await request(httpServer())
      .get('/api/v1/support/tickets')
      .set('Authorization', authorization)
      .expect(200);

    const listData = asRecord(listResponse.body as unknown).data;
    expect(Array.isArray(listData)).toBe(true);
    const tickets = listData as unknown[];
    expect(tickets).toHaveLength(1);
    expect(asRecord(tickets[0]).id).toBe(created.id);

    const ticketId = String(created.id);
    const presignResponse = await request(httpServer())
      .post('/api/v1/uploads/presigned-url')
      .set('Authorization', authorization)
      .send({
        purpose: 'SUPPORT_ATTACHMENT',
        supportTicketId: ticketId,
        fileName: 'meeting.jpg',
        contentType: 'image/jpeg',
        sizeBytes: attachmentBytes.length,
      })
      .expect(201);
    const intent = asRecord(asRecord(presignResponse.body as unknown).data);

    const messageResponse = await request(httpServer())
      .post(`/api/v1/support/tickets/${ticketId}/messages`)
      .set('Authorization', authorization)
      .send({
        body: 'Прикладываю фотографию для контекста.',
        attachmentIntentIds: [intent.intentId],
      })
      .expect(201);
    const message = asRecord(asRecord(messageResponse.body as unknown).data);
    const attachments = message.attachments as unknown[];
    expect(attachments).toHaveLength(1);
    const attachment = asRecord(attachments[0]);
    expect(attachment.sha256).toMatch(/^[a-f0-9]{64}$/);
    expect(storage.putObject).toHaveBeenCalledWith(
      'private-bucket',
      String(intent.key),
      expect.any(Buffer),
      'image/jpeg',
    );

    await request(httpServer())
      .get(`/api/v1/support/tickets/${ticketId}/messages`)
      .set('Authorization', anotherAuthorization)
      .expect(404);
    await request(httpServer())
      .get(
        `/api/v1/support/tickets/${ticketId}/attachments/${String(attachment.id)}/download-url`,
      )
      .set('Authorization', anotherAuthorization)
      .expect(404);

    const downloadResponse = await request(httpServer())
      .get(
        `/api/v1/support/tickets/${ticketId}/attachments/${String(attachment.id)}/download-url`,
      )
      .set('Authorization', authorization)
      .expect(200);
    expect(asRecord(asRecord(downloadResponse.body as unknown).data)).toEqual({
      downloadUrl: 'https://download.test/support',
      expiresInSeconds: 60,
    });
  });

  it('keeps booking and money unchanged across the manual issue matrix', async () => {
    const [borrower, lender, outsider] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990008101', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990008102', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990008103', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Booking issue',
        slug: 'booking-issue',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: lender.id,
        categoryId: category.id,
        title: 'Вещь для проверки no-show',
        description: 'Тестовое объявление для ручного обращения поддержки',
        condition: ItemCondition.GOOD,
        completeness: 'Полный комплект',
        handoverTerms: 'Личная передача',
        pricePerDay: 500,
        status: ItemStatus.APPROVED,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
    });
    const today = moscowCalendarDate();
    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: borrower.id,
        lenderId: lender.id,
        startDate: new Date(`${today}T00:00:00.000Z`),
        endDate: new Date(`${today}T00:00:00.000Z`),
        totalAmount: 500,
        status: BookingStatus.CONFIRMED,
      },
    });
    const authorization = async (user: typeof borrower) =>
      `Bearer ${await jwt.signAsync(
        {
          sub: user.id,
          phone: user.phone,
          role: user.role,
          tokenType: 'access',
          sessionVersion: 0,
        },
        { secret: 'e2e-access-secret', expiresIn: '15m' },
      )}`;
    const [borrowerAuth, lenderAuth, outsiderAuth] = await Promise.all([
      authorization(borrower),
      authorization(lender),
      authorization(outsider),
    ]);
    const payload = {
      bookingId: booking.id,
      bookingIssueReason: BookingIssueReason.OWNER_NO_SHOW,
      subject: 'Владелец не пришёл',
      message: 'Я нахожусь в согласованном месте, но владельца вещи нет.',
    };

    await request(httpServer())
      .post('/api/v1/support/tickets')
      .set('Authorization', outsiderAuth)
      .send(payload)
      .expect(404);
    await request(httpServer())
      .post('/api/v1/support/tickets')
      .set('Authorization', lenderAuth)
      .send(payload)
      .expect(409);
    const issueResponse = await request(httpServer())
      .post('/api/v1/support/tickets')
      .set('Authorization', borrowerAuth)
      .send(payload)
      .expect(201)
      .expect(({ body }) => {
        expect(asRecord(body as unknown).data).toMatchObject({
          bookingId: booking.id,
          bookingIssueReason: BookingIssueReason.OWNER_NO_SHOW,
          type: SupportTicketType.GENERAL,
        });
      });
    const dispute = await prisma.supportTicket.create({
      data: {
        userId: borrower.id,
        bookingId: booking.id,
        type: SupportTicketType.DISPUTE,
        subject: 'Будущий финансовый спор',
        message: 'Не должен быть доступен через API обычной поддержки.',
      },
    });
    const listResponse = await request(httpServer())
      .get('/api/v1/support/tickets')
      .set('Authorization', borrowerAuth)
      .expect(200);
    const tickets = asRecord(listResponse.body as unknown).data as unknown[];
    expect(tickets).toHaveLength(1);
    expect(asRecord(tickets[0]).id).toBe(
      asRecord(asRecord(issueResponse.body as unknown).data).id,
    );
    await request(httpServer())
      .get(`/api/v1/support/tickets/${dispute.id}/messages`)
      .set('Authorization', borrowerAuth)
      .expect(404);

    const submitIssue = (
      actorAuthorization: string,
      bookingIssueReason: BookingIssueReason,
    ) =>
      request(httpServer())
        .post('/api/v1/support/tickets')
        .set('Authorization', actorAuthorization)
        .send({
          bookingId: booking.id,
          bookingIssueReason,
          subject: 'Проблема с арендой',
          message: 'Нужна ручная помощь поддержки по текущей аренде.',
        });
    await submitIssue(borrowerAuth, BookingIssueReason.ITEM_FAULTY).expect(201);
    await submitIssue(lenderAuth, BookingIssueReason.BORROWER_NO_SHOW).expect(
      201,
    );
    await submitIssue(borrowerAuth, BookingIssueReason.BORROWER_NO_SHOW).expect(
      409,
    );

    let persisted = await prisma.booking.findUniqueOrThrow({
      where: { id: booking.id },
      include: { payment: true },
    });
    expect(persisted.status).toBe(BookingStatus.CONFIRMED);
    expect(persisted.totalAmount.toNumber()).toBe(500);
    expect(persisted.payment).toBeNull();

    const todayDate = new Date(`${today}T00:00:00.000Z`);
    const tomorrow = new Date(todayDate.getTime() + 24 * 60 * 60 * 1000);
    await prisma.booking.update({
      where: { id: booking.id },
      data: { status: BookingStatus.ACTIVE, endDate: tomorrow },
    });
    for (const reason of [
      BookingIssueReason.EARLY_RETURN,
      BookingIssueReason.ITEM_DAMAGED,
      BookingIssueReason.ITEM_LOST,
    ]) {
      await submitIssue(borrowerAuth, reason).expect(201);
    }

    persisted = await prisma.booking.findUniqueOrThrow({
      where: { id: booking.id },
      include: { payment: true },
    });
    expect(persisted.status).toBe(BookingStatus.ACTIVE);
    expect(persisted.totalAmount.toNumber()).toBe(500);
    expect(persisted.payment).toBeNull();

    const yesterday = new Date(todayDate.getTime() - 24 * 60 * 60 * 1000);
    await prisma.booking.update({
      where: { id: booking.id },
      data: { startDate: yesterday, endDate: yesterday },
    });
    await submitIssue(lenderAuth, BookingIssueReason.LATE_RETURN).expect(201);
    persisted = await prisma.booking.findUniqueOrThrow({
      where: { id: booking.id },
      include: { payment: true },
    });
    expect(persisted.status).toBe(BookingStatus.ACTIVE);
    expect(persisted.totalAmount.toNumber()).toBe(500);
    expect(persisted.payment).toBeNull();
  });

  afterAll(async () => {
    await app?.close();
  });
});

function asRecord(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('Expected an object response');
  }
  return value as Record<string, unknown>;
}
