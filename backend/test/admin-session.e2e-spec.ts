import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  AdminCapability,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  ReportReason,
  ReportTargetType,
  SupportTicketStatus,
  UserRole,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { bootstrapFirstAdmin } from './../src/admin/first-admin-bootstrap';
import {
  ADMIN_CSRF_COOKIE,
  ADMIN_SESSION_COOKIE,
} from './../src/admin/admin-session.service';
import { generateTotpCode } from './../src/admin/admin-totp';
import { SmsService } from './../src/auth/sms.service';
import { BookingOutboxProcessor } from './../src/booking/booking-outbox.processor';
import { PrismaService } from './../src/prisma/prisma.service';
import { RedisService } from './../src/redis/redis.service';
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';

class FakeSmsService {
  private readonly codes = new Map<string, string>();

  sendOtp(phone: string, code: string): Promise<void> {
    this.codes.set(phone, code);
    return Promise.resolve();
  }

  codeFor(phone: string): string {
    const code = this.codes.get(phone);
    if (!code) {
      throw new Error(`No OTP captured for ${phone}`);
    }
    return code;
  }

  reset(): void {
    this.codes.clear();
  }
}

function requiredString(value: unknown, name: string): string {
  if (typeof value !== 'string') {
    throw new Error(`Expected ${name} to be a string`);
  }
  return value;
}

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object response body');
  }
  return value as Record<string, unknown>;
}

type AdminBrowserSession = {
  cookie: string;
  csrfToken: string;
  sessionId: string;
};

function adminBrowserSessionFrom(
  setCookies: string[] | undefined,
): AdminBrowserSession {
  if (!setCookies) {
    throw new Error('Expected admin session cookies');
  }
  const adminCookie = setCookies.find((value) =>
    value.startsWith(`${ADMIN_SESSION_COOKIE}=`),
  );
  const csrfCookie = setCookies.find((value) =>
    value.startsWith(`${ADMIN_CSRF_COOKIE}=`),
  );
  if (!adminCookie || !csrfCookie) {
    throw new Error('Expected both admin and CSRF cookies');
  }

  expect(adminCookie).toContain('; Path=/;');
  expect(adminCookie).toContain('; HttpOnly;');
  expect(adminCookie).toContain('; Secure;');
  expect(adminCookie).toContain('; SameSite=Strict');
  expect(csrfCookie).toContain('; Path=/;');
  expect(csrfCookie).not.toContain('; HttpOnly;');
  expect(csrfCookie).toContain('; Secure;');
  expect(csrfCookie).toContain('; SameSite=Strict');
  const csrfPair = csrfCookie.split(';', 1)[0];
  const adminPair = adminCookie.split(';', 1)[0];
  return {
    cookie: [adminCookie, csrfCookie]
      .map((value) => value.split(';', 1)[0])
      .join('; '),
    csrfToken: csrfPair.slice(`${ADMIN_CSRF_COOKIE}=`.length),
    sessionId: adminPair.slice(`${ADMIN_SESSION_COOKIE}=`.length),
  };
}

describe('Admin session (e2e)', () => {
  const installationId = '33333333-3333-4333-8333-333333333333';
  let app: INestApplication<App> | undefined;
  let fakeSms: FakeSmsService;
  let jwt: JwtService;
  let prisma: PrismaService;
  let redis: ReturnType<RedisService['getClient']>;
  const storage = {
    createPresignedDownloadUrl: jest.fn((bucket: string, key: string) =>
      Promise.resolve(`https://download.test/${bucket}/${key}?signed=true`),
    ),
  };

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    return app.getHttpServer();
  }

  async function enrollAdminTotp(accessToken: string): Promise<{
    secret: string;
    confirmationCode: string;
    recoveryCodes: string[];
  }> {
    const setupResponse = await request(httpServer())
      .post('/api/v1/admin/session/totp/setup')
      .set('Authorization', `Bearer ${accessToken}`)
      .set('X-Request-Id', 'admin-mfa-setup-request')
      .set('User-Agent', 'sosedi-admin-enrollment-e2e')
      .expect(201);
    const setupData = asRecord(asRecord(setupResponse.body as unknown).data);
    const secret = requiredString(setupData.secret, 'secret');
    const confirmationCode = generateTotpCode(secret);
    const confirmResponse = await request(httpServer())
      .post('/api/v1/admin/session/totp/confirm')
      .set('Authorization', `Bearer ${accessToken}`)
      .set('X-Request-Id', 'admin-mfa-confirm-request')
      .set('User-Agent', 'sosedi-admin-enrollment-e2e')
      .send({ code: confirmationCode })
      .expect(201);
    const confirmData = asRecord(
      asRecord(confirmResponse.body as unknown).data,
    );
    if (
      !Array.isArray(confirmData.recoveryCodes) ||
      !confirmData.recoveryCodes.every(
        (code): code is string => typeof code === 'string',
      )
    ) {
      throw new Error('Expected recoveryCodes to be a string array');
    }
    return {
      secret,
      confirmationCode,
      recoveryCodes: confirmData.recoveryCodes,
    };
  }

  beforeAll(async () => {
    fakeSms = new FakeSmsService();
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(SmsService)
      .useValue(fakeSms)
      .overrideProvider(S3StorageService)
      .useValue(storage)
      .compile();

    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
    jwt = app.get(JwtService);
    prisma = app.get(PrismaService);
    redis = app.get(RedisService).getClient();
  });

  beforeEach(async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    fakeSms.reset();
    jest.clearAllMocks();
    await resetTestState(app);
  });

  it('bootstraps exactly one first admin under concurrent execution', async () => {
    const input = {
      phone: '8 (999) 000-30-00',
      capabilities: [AdminCapability.MODERATION, AdminCapability.SUPPORT],
    };

    const attempts = await Promise.allSettled([
      bootstrapFirstAdmin(prisma, input),
      bootstrapFirstAdmin(prisma, input),
    ]);

    expect(attempts.map((attempt) => attempt.status).sort()).toEqual([
      'fulfilled',
      'rejected',
    ]);
    const admin = await prisma.user.findFirstOrThrow({
      where: { role: UserRole.ADMIN },
    });
    expect(admin).toMatchObject({
      phone: '+79990003000',
      adminCapabilities: [AdminCapability.MODERATION, AdminCapability.SUPPORT],
    });
    await expect(
      prisma.user.count({ where: { role: UserRole.ADMIN } }),
    ).resolves.toBe(1);
    await expect(
      prisma.adminAuditLog.findFirstOrThrow({
        where: { action: 'FIRST_ADMIN_BOOTSTRAPPED' },
      }),
    ).resolves.toMatchObject({
      adminId: admin.id,
      entityType: 'User',
      entityId: admin.id,
      metadata: {
        capabilities: [AdminCapability.MODERATION, AdminCapability.SUPPORT],
        method: 'OFFLINE_CLI',
      },
    });
  });

  it('requires TOTP or a one-time recovery code for a short admin session', async () => {
    const [admin, owner, reporter] = await Promise.all([
      prisma.user.create({
        data: {
          phone: '+79990003001',
          role: UserRole.ADMIN,
        },
      }),
      prisma.user.create({
        data: {
          phone: '+79990003002',
          role: UserRole.USER,
        },
      }),
      prisma.user.create({
        data: {
          phone: '+79990003003',
          role: UserRole.USER,
        },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Capability boundary',
        slug: 'capability-boundary',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const pendingItem = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Объект проверки полномочий',
        description: 'Не должен меняться администратором без MODERATION',
        condition: ItemCondition.GOOD,
        completeness: 'Полный комплект',
        handoverTerms: 'Личная передача',
        pricePerDay: 500,
        status: ItemStatus.PENDING,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
    });
    const moderationItem = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Объект успешной модерации',
        description: 'Должен создать уведомление только для владельца',
        condition: ItemCondition.GOOD,
        completeness: 'Полный комплект',
        handoverTerms: 'Личная передача',
        pricePerDay: 600,
        status: ItemStatus.PENDING,
        publicArea: 'Центральный округ',
        address: 'Москва, второй приватный адрес',
        latitude: 55.76,
        longitude: 37.62,
      },
    });
    const supportTicket = await prisma.supportTicket.create({
      data: {
        userId: owner.id,
        subject: 'Вопрос в поддержку',
        message: 'Нужна помощь с договорённостью о встрече.',
      },
    });
    const supportMessage = await prisma.supportMessage.create({
      data: {
        ticketId: supportTicket.id,
        authorId: owner.id,
        authorRole: 'USER',
        body: 'Приватное вложение для оператора.',
      },
    });
    const supportObjectKey = `support/${supportTicket.id}/attachment.webp`;
    const supportIntent = await prisma.uploadIntent.create({
      data: {
        actorId: owner.id,
        purpose: 'SUPPORT_ATTACHMENT',
        entityId: supportTicket.id,
        bucket: 'private-bucket',
        objectKey: supportObjectKey,
        contentType: 'image/webp',
        sizeBytes: 1024,
        expiresAt: new Date('2026-08-01T00:00:00.000Z'),
        confirmedAt: new Date('2026-07-30T00:00:00.000Z'),
      },
    });
    const supportAttachment = await prisma.supportAttachment.create({
      data: {
        messageId: supportMessage.id,
        uploadIntentId: supportIntent.id,
        storageKey: supportObjectKey,
        sha256: 'b'.repeat(64),
      },
    });
    const userReport = await prisma.userReport.create({
      data: {
        reporterId: reporter.id,
        targetType: ReportTargetType.ITEM,
        targetId: pendingItem.id,
        reason: ReportReason.MISLEADING_LISTING,
        description:
          'Описание объявления не соответствует фактическому состоянию вещи.',
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: admin.id,
        phone: admin.phone,
        role: admin.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );
    const accessAuthorization = `Bearer ${accessToken}`;
    const ownerAccessToken = await jwt.signAsync(
      {
        sub: owner.id,
        phone: owner.phone,
        role: owner.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );

    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Authorization', accessAuthorization)
      .expect(401);
    await request(httpServer())
      .get('/api/v1/admin/support/tickets')
      .set('Authorization', accessAuthorization)
      .expect(401);
    await request(httpServer())
      .get('/api/v1/admin/reports')
      .set('Authorization', accessAuthorization)
      .expect(401);
    await request(httpServer())
      .post('/api/v1/admin/session/step-up')
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .send({ code: '000000' })
      .expect(403);

    await request(httpServer())
      .post('/api/v1/admin/session/step-up')
      .set('Authorization', accessAuthorization)
      .send({ code: '000000' })
      .expect(401);
    const enrollment = await enrollAdminTotp(accessToken);
    await request(httpServer())
      .post('/api/v1/admin/session/step-up')
      .set('Authorization', accessAuthorization)
      .send({ code: enrollment.confirmationCode })
      .expect(401);
    const stepUpResponse = await request(httpServer())
      .post('/api/v1/admin/session/step-up')
      .set('Authorization', accessAuthorization)
      .set('X-Request-Id', 'admin-step-up-request')
      .send({ code: enrollment.recoveryCodes[0] })
      .expect(201);
    const data = asRecord(asRecord(stepUpResponse.body as unknown).data);
    expect(data).toEqual({ expiresInSeconds: 300 });
    const adminSession = adminBrowserSessionFrom(
      stepUpResponse.headers['set-cookie'],
    );
    await request(httpServer())
      .get('/api/v1/admin/session')
      .set('Cookie', adminSession.cookie)
      .expect(200)
      .expect(({ body }) => {
        const sessionData = asRecord(asRecord(body as unknown).data);
        expect(sessionData.userId).toBe(admin.id);
        expect(sessionData.capabilities).toEqual([]);
        expect(typeof sessionData.expiresInSeconds).toBe('number');
        expect(sessionData.expiresInSeconds).toBeGreaterThan(0);
        expect(sessionData.expiresInSeconds).toBeLessThanOrEqual(300);
      });

    await request(httpServer())
      .post('/api/v1/admin/session/step-up')
      .set('Authorization', accessAuthorization)
      .send({ code: enrollment.recoveryCodes[0] })
      .expect(401);
    const credential = await prisma.adminMfaCredential.findUniqueOrThrow({
      where: { userId: admin.id },
    });
    expect(credential.totpSecretEncrypted).not.toContain(enrollment.secret);
    const setupAudit = await prisma.adminAuditLog.findFirstOrThrow({
      where: { adminId: admin.id, action: 'ADMIN_MFA_SETUP_STARTED' },
    });
    expect(setupAudit).toMatchObject({
      entityType: 'User',
      entityId: admin.id,
      requestId: 'admin-mfa-setup-request',
      before: { pendingMfaSetup: false },
      after: { pendingMfaSetup: true },
    });
    expect(setupAudit.deviceId).toMatch(/^[a-f0-9]{32}$/);
    expect(JSON.stringify(setupAudit)).not.toContain(enrollment.secret);
    const mfaAudit = await prisma.adminAuditLog.findFirstOrThrow({
      where: { adminId: admin.id, action: 'ADMIN_MFA_ENABLED' },
    });
    expect(mfaAudit).toMatchObject({
      entityType: 'User',
      entityId: admin.id,
      requestId: 'admin-mfa-confirm-request',
      before: { mfaEnabled: false },
      after: { mfaEnabled: true },
    });
    expect(mfaAudit.deviceId).toMatch(/^[a-f0-9]{32}$/);
    expect(JSON.stringify(mfaAudit)).not.toContain(enrollment.secret);
    expect(JSON.stringify(mfaAudit)).not.toContain(enrollment.recoveryCodes[0]);
    await expect(
      prisma.adminAuditLog.findFirstOrThrow({
        where: {
          adminId: admin.id,
          action: 'ADMIN_RECOVERY_CODE_USED',
        },
      }),
    ).resolves.toMatchObject({
      entityType: 'User',
      entityId: admin.id,
      requestId: 'admin-step-up-request',
      before: { remaining: 10 },
      after: { remaining: 9 },
      metadata: { remaining: 9 },
    });
    await expect(
      prisma.adminAuditLog.findFirstOrThrow({
        where: {
          adminId: admin.id,
          action: 'ADMIN_STEP_UP_SUCCEEDED',
        },
      }),
    ).resolves.toMatchObject({
      entityType: 'User',
      entityId: admin.id,
      requestId: 'admin-step-up-request',
      before: { stepUpAuthenticated: false },
      after: { stepUpAuthenticated: true },
    });
    await expect(
      prisma.adminAuditLog.findMany({
        where: {
          adminId: admin.id,
          action: {
            in: ['ADMIN_MFA_ENABLED', 'ADMIN_RECOVERY_CODE_USED'],
          },
        },
        select: { action: true, metadata: true },
        orderBy: { createdAt: 'asc' },
      }),
    ).resolves.toEqual([
      {
        action: 'ADMIN_MFA_ENABLED',
        metadata: { method: 'TOTP', recoveryCodeCount: 10 },
      },
      {
        action: 'ADMIN_RECOVERY_CODE_USED',
        metadata: { remaining: 9 },
      },
    ]);

    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .get('/api/v1/admin/support/tickets')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .get('/api/v1/admin/reports')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await prisma.user.update({
      where: { id: admin.id },
      data: { adminCapabilities: [AdminCapability.SUPPORT] },
    });
    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .get(`/api/v1/admin/users/${owner.id}`)
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .get('/api/v1/admin/support/tickets')
      .set('Cookie', adminSession.cookie)
      .expect(200);
    await request(httpServer())
      .patch(`/api/v1/admin/support/tickets/${supportTicket.id}/assign-self`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'support-assign-request')
      .expect(200);
    await request(httpServer())
      .patch(`/api/v1/admin/support/tickets/${supportTicket.id}/reply`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'support-reply-request')
      .send({ message: 'Мы связались со второй стороной.' })
      .expect(200);
    await request(httpServer())
      .get(`/api/v1/admin/support/tickets/${supportTicket.id}/messages`)
      .set('Cookie', adminSession.cookie)
      .expect(200)
      .expect(({ body }) => {
        const messages = asRecord(body as unknown).data;
        expect(Array.isArray(messages)).toBe(true);
        expect(messages).toHaveLength(2);
      });
    await request(httpServer())
      .get(
        `/api/v1/admin/support/tickets/${supportTicket.id}/attachments/${supportAttachment.id}/download-url`,
      )
      .set('Cookie', adminSession.cookie)
      .set('X-Request-Id', 'support-attachment-download-request')
      .expect(200);
    await expect(
      prisma.adminAuditLog.findFirstOrThrow({
        where: {
          adminId: admin.id,
          action: 'SUPPORT_ATTACHMENT_DOWNLOAD_REQUESTED',
          entityId: supportAttachment.id,
        },
      }),
    ).resolves.toMatchObject({
      entityType: 'SupportAttachment',
      capability: AdminCapability.SUPPORT,
      requestId: 'support-attachment-download-request',
      metadata: { supportTicketId: supportTicket.id },
    });
    await request(httpServer())
      .post(`/api/v1/admin/support/tickets/${supportTicket.id}/messages`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'support-message-request')
      .send({
        body: 'Дополнительное уточнение от оператора.',
        attachmentIntentIds: [],
      })
      .expect(201);
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    await app.get(BookingOutboxProcessor).processPending();
    const inboxResponse = await request(httpServer())
      .get('/api/v1/inbox')
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .expect(200);
    const inboxEvents = asRecord(inboxResponse.body as unknown).data;
    expect(Array.isArray(inboxEvents)).toBe(true);
    expect(inboxEvents).toHaveLength(2);
    for (const event of inboxEvents as unknown[]) {
      expect(asRecord(event)).toMatchObject({
        bookingId: null,
        supportTicketId: supportTicket.id,
      });
    }
    const firstEventId = requiredString(
      asRecord((inboxEvents as unknown[])[0]).eventId,
      'support inbox event ID',
    );
    await request(httpServer())
      .get(`/api/v1/inbox/${firstEventId}`)
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .expect(200)
      .expect(({ body }) => {
        const details = asRecord(asRecord(body as unknown).data);
        expect(details.booking).toBeNull();
        expect(details.supportTicket).toEqual(
          expect.objectContaining({
            id: supportTicket.id,
            subject: 'Вопрос в поддержку',
          }),
        );
        expect(JSON.stringify(details)).not.toContain(owner.phone);
        expect(JSON.stringify(details)).not.toContain(supportTicket.message);
      });
    await request(httpServer())
      .patch(`/api/v1/admin/support/tickets/${supportTicket.id}/close`)
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .patch(`/api/v1/admin/support/tickets/${supportTicket.id}/close`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'support-close-request')
      .expect(200)
      .expect(({ body }) => {
        expect(asRecord(asRecord(body as unknown).data)).toMatchObject({
          id: supportTicket.id,
          status: SupportTicketStatus.CLOSED,
        });
      });
    await request(httpServer())
      .post(`/api/v1/admin/support/tickets/${supportTicket.id}/messages`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .send({
        body: 'Сообщение после закрытия должно быть запрещено.',
        attachmentIntentIds: [],
      })
      .expect(409);
    await request(httpServer())
      .post(`/api/v1/support/tickets/${supportTicket.id}/messages`)
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .send({
        body: 'Пользователь тоже не может писать после закрытия.',
        attachmentIntentIds: [],
      })
      .expect(409);
    await app.get(BookingOutboxProcessor).processPending();
    const closedInboxResponse = await request(httpServer())
      .get('/api/v1/inbox')
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .expect(200);
    const closedEvent = (
      asRecord(closedInboxResponse.body as unknown).data as unknown[]
    )
      .map(asRecord)
      .find((event) => event.eventType === 'SUPPORT_TICKET_CLOSED');
    expect(closedEvent).toMatchObject({
      bookingId: null,
      supportTicketId: supportTicket.id,
    });
    await expect(
      prisma.adminAuditLog.findMany({
        where: {
          entityId: supportTicket.id,
          action: {
            in: [
              'SUPPORT_TICKET_ASSIGNED',
              'SUPPORT_TICKET_REPLIED',
              'SUPPORT_MESSAGE_CREATED',
              'SUPPORT_TICKET_CLOSED',
            ],
          },
        },
        orderBy: { createdAt: 'asc' },
      }),
    ).resolves.toEqual([
      expect.objectContaining({
        adminId: admin.id,
        capability: AdminCapability.SUPPORT,
        requestId: 'support-assign-request',
      }),
      expect.objectContaining({
        adminId: admin.id,
        capability: AdminCapability.SUPPORT,
        requestId: 'support-reply-request',
      }),
      expect.objectContaining({
        adminId: admin.id,
        capability: AdminCapability.SUPPORT,
        requestId: 'support-message-request',
        metadata: { attachmentCount: 0 },
      }),
      expect.objectContaining({
        adminId: admin.id,
        capability: AdminCapability.SUPPORT,
        requestId: 'support-close-request',
        before: {
          status: SupportTicketStatus.IN_PROGRESS,
          assigneeId: admin.id,
        },
        after: {
          status: SupportTicketStatus.CLOSED,
          assigneeId: admin.id,
        },
      }),
    ]);
    await request(httpServer())
      .patch(`/api/v1/admin/users/${owner.id}/block`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .send({ reason: 'Недостаточно полномочий для блокировки' })
      .expect(403);
    await request(httpServer())
      .get('/api/v1/admin/items/pending')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .get('/api/v1/admin/reports')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .patch(`/api/v1/admin/items/${pendingItem.id}/approve`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .expect(403);
    await expect(
      prisma.item.findUniqueOrThrow({ where: { id: pendingItem.id } }),
    ).resolves.toMatchObject({ status: ItemStatus.PENDING });
    await prisma.user.update({
      where: { id: admin.id },
      data: { adminCapabilities: [AdminCapability.MODERATION] },
    });
    await request(httpServer())
      .get(`/api/v1/admin/users/${owner.id}`)
      .set('Cookie', adminSession.cookie)
      .expect(200);
    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Cookie', adminSession.cookie)
      .expect(200);
    await request(httpServer())
      .get('/api/v1/admin/support/tickets')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    await request(httpServer())
      .get('/api/v1/admin/items/pending')
      .set('Cookie', adminSession.cookie)
      .expect(200);
    await request(httpServer())
      .get('/api/v1/admin/reports')
      .set('Cookie', adminSession.cookie)
      .expect(200);
    await request(httpServer())
      .patch(`/api/v1/admin/reports/${userReport.id}/decision`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'report-decision-request')
      .send({
        decision: 'HIDE_LISTING',
        reason: 'Подтверждено несоответствие описания объявления.',
      })
      .expect(200);
    await expect(
      prisma.item.findUniqueOrThrow({ where: { id: pendingItem.id } }),
    ).resolves.toMatchObject({ status: ItemStatus.HIDDEN });
    await expect(
      prisma.adminAuditLog.findFirst({
        where: { action: 'REPORT_DECIDED', entityId: userReport.id },
      }),
    ).resolves.toMatchObject({
      adminId: admin.id,
      capability: AdminCapability.MODERATION,
      requestId: 'report-decision-request',
    });
    await request(httpServer())
      .patch(`/api/v1/admin/items/${moderationItem.id}/approve`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'item-approve-request')
      .expect(200);
    await app.get(BookingOutboxProcessor).processPending();
    const moderationInbox = await request(httpServer())
      .get('/api/v1/inbox')
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .expect(200);
    const moderationEvent = (
      asRecord(moderationInbox.body as unknown).data as unknown[]
    )
      .map(asRecord)
      .find((event) => event.eventType === 'ITEM_APPROVED');
    if (!moderationEvent) {
      throw new Error('Moderation inbox event was not created');
    }
    expect(moderationEvent).toMatchObject({
      bookingId: null,
      supportTicketId: null,
      itemId: moderationItem.id,
    });
    const reportDecisionEvent = (
      asRecord(moderationInbox.body as unknown).data as unknown[]
    )
      .map(asRecord)
      .find((event) => event.eventType === 'ITEM_HIDDEN_BY_REPORT_REVIEW');
    if (!reportDecisionEvent) {
      throw new Error('Report decision inbox event was not created');
    }
    expect(reportDecisionEvent).toMatchObject({
      bookingId: null,
      supportTicketId: null,
      itemId: pendingItem.id,
    });
    expect(reportDecisionEvent).not.toHaveProperty('reporterId');
    expect(reportDecisionEvent).not.toHaveProperty('reportId');
    await request(httpServer())
      .get(`/api/v1/inbox/${String(moderationEvent.eventId)}`)
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .expect(200);
    await request(httpServer())
      .get(`/api/v1/inbox/${String(reportDecisionEvent.eventId)}`)
      .set('Authorization', `Bearer ${ownerAccessToken}`)
      .expect(200);
    await prisma.user.update({
      where: { id: admin.id },
      data: { adminCapabilities: [] },
    });
    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Cookie', adminSession.cookie)
      .expect(403);

    await request(httpServer())
      .delete('/api/v1/admin/session')
      .set('Cookie', adminSession.cookie)
      .expect(403);
    const logoutResponse = await request(httpServer())
      .delete('/api/v1/admin/session')
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'admin-session-revoke-request')
      .expect(200);
    expect(logoutResponse.headers['set-cookie']).toHaveLength(2);
    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Cookie', adminSession.cookie)
      .expect(401);
    await expect(
      prisma.adminAuditLog.findFirstOrThrow({
        where: { adminId: admin.id, action: 'ADMIN_SESSION_REVOKED' },
      }),
    ).resolves.toMatchObject({
      entityType: 'User',
      entityId: admin.id,
      requestId: 'admin-session-revoke-request',
      before: { adminSessionActive: true },
      after: { adminSessionActive: false },
    });

    const expiringStepUpResponse = await request(httpServer())
      .post('/api/v1/admin/session/step-up')
      .set('Authorization', accessAuthorization)
      .send({ code: enrollment.recoveryCodes[1] })
      .expect(201);
    const expiringSession = adminBrowserSessionFrom(
      expiringStepUpResponse.headers['set-cookie'],
    );
    await redis.expire(`auth:admin-session:${expiringSession.sessionId}`, 0);
    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Cookie', expiringSession.cookie)
      .expect(401);

    await request(httpServer()).post('/api/v1/admin/bootstrap').expect(404);
    await request(httpServer()).post('/api/v1/admin/promote').expect(404);
  });

  it('revokes a blocked user session before protected actions run', async () => {
    const admin = await prisma.user.create({
      data: {
        phone: '+79990003101',
        role: UserRole.ADMIN,
        adminCapabilities: [AdminCapability.MODERATION],
      },
    });
    const targetPhone = '+79990003102';
    await request(httpServer())
      .post('/api/v1/auth/otp/request')
      .set('X-Installation-Id', installationId)
      .send({ phone: targetPhone })
      .expect(201);
    const loginResponse = await request(httpServer())
      .post('/api/v1/auth/otp/verify')
      .set('X-Installation-Id', installationId)
      .send({ phone: targetPhone, code: fakeSms.codeFor(targetPhone) })
      .expect(201);
    const loginData = asRecord(asRecord(loginResponse.body as unknown).data);
    const target = asRecord(loginData.user);
    const targetId = requiredString(target.id, 'target.id');
    const targetAccessToken = requiredString(
      loginData.accessToken,
      'accessToken',
    );
    const targetRefreshToken = requiredString(
      loginData.refreshToken,
      'refreshToken',
    );
    const adminAccessToken = await jwt.signAsync(
      {
        sub: admin.id,
        phone: admin.phone,
        role: admin.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );

    const enrollment = await enrollAdminTotp(adminAccessToken);
    const stepUpResponse = await request(httpServer())
      .post('/api/v1/admin/session/step-up')
      .set('Authorization', `Bearer ${adminAccessToken}`)
      .send({ code: enrollment.recoveryCodes[0] })
      .expect(201);
    const adminSession = adminBrowserSessionFrom(
      stepUpResponse.headers['set-cookie'],
    );

    const blockResponses = await Promise.all([
      request(httpServer())
        .patch(`/api/v1/admin/users/${targetId}/block`)
        .set('Cookie', adminSession.cookie)
        .set('X-CSRF-Token', adminSession.csrfToken)
        .set('X-Request-Id', 'block-request-123')
        .set('User-Agent', 'sosedi-operator-e2e')
        .send({ reason: 'Подтверждённое злоупотребление' }),
      request(httpServer())
        .patch(`/api/v1/admin/users/${targetId}/block`)
        .set('Cookie', adminSession.cookie)
        .set('X-CSRF-Token', adminSession.csrfToken)
        .set('X-Request-Id', 'block-request-123')
        .set('User-Agent', 'sosedi-operator-e2e')
        .send({ reason: 'Подтверждённое злоупотребление' }),
    ]);
    expect(blockResponses.map((response) => response.status).sort()).toEqual([
      200, 409,
    ]);

    await request(httpServer())
      .post('/api/v1/uploads/presigned-url')
      .set('Authorization', `Bearer ${targetAccessToken}`)
      .send({})
      .expect(401);

    await prisma.user.update({
      where: { id: targetId },
      data: { isBlocked: false },
    });

    await request(httpServer())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${targetAccessToken}`)
      .expect(401);
    await request(httpServer())
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: targetRefreshToken })
      .expect(401);
    const audit = await prisma.adminAuditLog.findFirstOrThrow({
      where: {
        adminId: admin.id,
        action: 'USER_BLOCKED',
        entityId: targetId,
      },
    });
    expect(audit).toMatchObject({
      entityType: 'User',
      capability: AdminCapability.MODERATION,
      reason: 'Подтверждённое злоупотребление',
      requestId: 'block-request-123',
      before: { isBlocked: false, sessionVersion: 0 },
      after: { isBlocked: true, sessionVersion: 1 },
    });
    expect(audit.deviceId).toMatch(/^[a-f0-9]{32}$/);
    await expect(
      prisma.adminAuditLog.count({
        where: {
          action: 'USER_BLOCKED',
          entityId: targetId,
        },
      }),
    ).resolves.toBe(1);
    await expect(
      prisma.adminAuditLog.update({
        where: { id: audit.id },
        data: { reason: 'Подмена аудита' },
      }),
    ).rejects.toThrow('admin_audit_logs is append-only');
    await expect(
      prisma.adminAuditLog.delete({ where: { id: audit.id } }),
    ).rejects.toThrow('admin_audit_logs is append-only');

    await prisma.user.update({
      where: { id: admin.id },
      data: {
        role: UserRole.USER,
        sessionVersion: { increment: 1 },
      },
    });
    await request(httpServer())
      .get('/api/v1/admin/session')
      .set('Cookie', adminSession.cookie)
      .expect(401);
    await expect(
      prisma.adminAuditLog.findUniqueOrThrow({ where: { id: audit.id } }),
    ).resolves.toMatchObject({
      adminId: admin.id,
      action: 'USER_BLOCKED',
      entityId: targetId,
      reason: 'Подтверждённое злоупотребление',
      before: { isBlocked: false, sessionVersion: 0 },
      after: { isBlocked: true, sessionVersion: 1 },
    });
    await expect(
      prisma.adminAuditLog.count({
        where: {
          action: 'USER_BLOCKED',
          entityId: targetId,
        },
      }),
    ).resolves.toBe(1);
  });

  afterAll(async () => {
    await app?.close();
  });
});
