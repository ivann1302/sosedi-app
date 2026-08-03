import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  AdminCapability,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  UserRole,
} from '@prisma/client';
import { createHash, randomUUID } from 'node:crypto';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { ADMIN_SESSION_COOKIE } from './../src/admin/admin-session.service';
import { PrismaService } from './../src/prisma/prisma.service';
import { RedisService } from './../src/redis/redis.service';
import { resetTestState } from './support/test-state';

describe('Sensitive status commands (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let jwt: JwtService;
  let prisma: PrismaService;

  function httpServer(): App {
    if (!app) {
      throw new Error('Test app was not initialized');
    }

    return app.getHttpServer();
  }

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

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

    await resetTestState(app);
  });

  async function accessTokenFor(user: {
    id: string;
    phone: string;
    role: UserRole;
  }): Promise<string> {
    return jwt.signAsync(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );
  }

  async function adminSessionFor(user: {
    id: string;
    phone: string;
    role: UserRole;
  }): Promise<{ cookie: string; csrfToken: string }> {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const sessionId = randomUUID();
    const csrfToken = randomUUID();
    await app
      .get(RedisService)
      .getClient()
      .set(
        `auth:admin-session:${sessionId}`,
        JSON.stringify({
          userId: user.id,
          sessionVersion: 0,
          csrfTokenHash: createHash('sha256').update(csrfToken).digest('hex'),
        }),
        'EX',
        300,
      );

    return {
      cookie: `${ADMIN_SESSION_COOKIE}=${sessionId}`,
      csrfToken,
    };
  }

  it('allows only actor-specific commands from an allowed current state', async () => {
    const [admin, owner] = await Promise.all([
      prisma.user.create({
        data: {
          phone: '+79990002001',
          role: UserRole.ADMIN,
          adminCapabilities: [AdminCapability.MODERATION],
        },
      }),
      prisma.user.create({
        data: {
          phone: '+79990002002',
          role: UserRole.USER,
        },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Командная категория',
        slug: 'status-command-category',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const [pendingItem, approvedItem] = await Promise.all([
      prisma.item.create({
        data: {
          ownerId: owner.id,
          categoryId: category.id,
          title: 'Объявление на модерации',
          description: 'Вещь ожидает решения администратора',
          condition: ItemCondition.GOOD,
          completeness: 'Вещь и комплект штатных аксессуаров',
          handoverTerms: 'Личная передача по договорённости',
          pricePerDay: 500,
          status: ItemStatus.PENDING,
          publicArea: 'Центральный округ',
          address: 'Москва, приватный адрес, 1',
          latitude: 55.75,
          longitude: 37.61,
        },
      }),
      prisma.item.create({
        data: {
          ownerId: owner.id,
          categoryId: category.id,
          title: 'Одобренное объявление',
          description: 'Вещь уже прошла модерацию ранее',
          condition: ItemCondition.GOOD,
          completeness: 'Вещь и комплект штатных аксессуаров',
          handoverTerms: 'Личная передача по договорённости',
          pricePerDay: 600,
          status: ItemStatus.APPROVED,
          publicArea: 'Северный округ',
          address: 'Москва, приватный адрес, 2',
          latitude: 55.85,
          longitude: 37.62,
        },
      }),
    ]);
    const [adminSession, ownerToken] = await Promise.all([
      adminSessionFor(admin),
      accessTokenFor(owner),
    ]);
    const ownerAuthorization = `Bearer ${ownerToken}`;

    await request(httpServer())
      .get('/api/v1/admin/users')
      .set('Cookie', adminSession.cookie)
      .expect(200);
    await request(httpServer())
      .patch(`/api/v1/categories/${category.id}`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .send({ isActive: false })
      .expect(400);
    await request(httpServer())
      .patch(`/api/v1/categories/${category.id}`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'category-update-request')
      .send({ sortOrder: 20 })
      .expect(200);
    await request(httpServer())
      .patch(`/api/v1/categories/${category.id}/disable`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .set('X-Request-Id', 'category-disable-request')
      .expect(200);
    await request(httpServer())
      .patch(`/api/v1/items/${pendingItem.id}`)
      .set('Authorization', ownerAuthorization)
      .send({ status: ItemStatus.APPROVED })
      .expect(400);
    await request(httpServer())
      .patch(`/api/v1/items/${pendingItem.id}/status`)
      .set('Authorization', ownerAuthorization)
      .send({ status: ItemStatus.APPROVED })
      .expect(404);

    await request(httpServer())
      .patch(`/api/v1/admin/items/${pendingItem.id}/approve`)
      .set('Authorization', ownerAuthorization)
      .expect(401);
    await request(httpServer())
      .patch(`/api/v1/admin/items/${pendingItem.id}/approve`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .expect(200);
    await request(httpServer())
      .patch(`/api/v1/admin/items/${pendingItem.id}/approve`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .expect(409);
    await request(httpServer())
      .patch(`/api/v1/admin/items/${approvedItem.id}/reject`)
      .set('Cookie', adminSession.cookie)
      .set('X-CSRF-Token', adminSession.csrfToken)
      .send({ reason: 'Повторная модерация без возврата в PENDING запрещена' })
      .expect(409);

    const genericStatusRoutes = [
      '/api/v1/bookings/614c54e7-a5c8-4484-a830-6e4387fb752c/status',
      '/api/v1/payments/614c54e7-a5c8-4484-a830-6e4387fb752c/status',
      '/api/v1/payouts/614c54e7-a5c8-4484-a830-6e4387fb752c/status',
      '/api/v1/disputes/614c54e7-a5c8-4484-a830-6e4387fb752c/status',
    ];
    for (const path of genericStatusRoutes) {
      await request(httpServer())
        .patch(path)
        .set('Cookie', adminSession.cookie)
        .set('X-CSRF-Token', adminSession.csrfToken)
        .send({ status: 'COMPLETED' })
        .expect(404);
    }

    const [
      unchangedCategory,
      moderatedItem,
      unchangedApprovedItem,
      auditCount,
      categoryAudit,
    ] = await Promise.all([
      prisma.category.findUniqueOrThrow({ where: { id: category.id } }),
      prisma.item.findUniqueOrThrow({ where: { id: pendingItem.id } }),
      prisma.item.findUniqueOrThrow({ where: { id: approvedItem.id } }),
      prisma.adminAuditLog.count({
        where: {
          entityType: 'Item',
          entityId: pendingItem.id,
        },
      }),
      prisma.adminAuditLog.findMany({
        where: {
          entityType: 'Category',
          entityId: category.id,
        },
        orderBy: { createdAt: 'asc' },
      }),
    ]);

    expect(unchangedCategory.isActive).toBe(false);
    expect(moderatedItem.status).toBe(ItemStatus.APPROVED);
    expect(unchangedApprovedItem.status).toBe(ItemStatus.APPROVED);
    expect(auditCount).toBe(1);
    expect(categoryAudit).toMatchObject([
      {
        adminId: admin.id,
        action: 'CATEGORY_UPDATED',
        capability: AdminCapability.MODERATION,
        requestId: 'category-update-request',
      },
      {
        adminId: admin.id,
        action: 'CATEGORY_DISABLED',
        capability: AdminCapability.MODERATION,
        requestId: 'category-disable-request',
      },
    ]);
    expect(JSON.stringify(categoryAudit)).not.toContain('safetyNotice');
  });

  afterAll(async () => {
    await app?.close();
  });
});
