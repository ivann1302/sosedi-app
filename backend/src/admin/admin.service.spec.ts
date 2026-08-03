import { ConflictException, NotFoundException } from '@nestjs/common';
import {
  AdminCapability,
  ItemCondition,
  ItemStatus,
  KycStatus,
  Prisma,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AdminService } from './admin.service';

type TestUser = {
  id: string;
  phone: string;
  name: string | null;
  city: string | null;
  avatarUrl: string | null;
  role: UserRole;
  kycStatus: KycStatus | null;
  isBlocked: boolean;
  sessionVersion: number;
  deletedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

type TestCategory = {
  id: string;
  name: string;
  slug: string;
  iconName: string | null;
};

type TestOwner = {
  id: string;
  phone: string;
  name: string | null;
  city: string | null;
  avatarUrl: string | null;
  isBlocked: boolean;
  deletedAt: Date | null;
};

type TestItem = {
  id: string;
  ownerId: string;
  title: string;
  description: string;
  condition: ItemCondition;
  completeness: string;
  handoverTerms: string;
  pricePerDay: Prisma.Decimal;
  depositAmount: Prisma.Decimal | null;
  status: ItemStatus;
  rejectReason: string | null;
  publicArea: string;
  address: string;
  latitude: number;
  longitude: number;
  category: TestCategory;
  owner: TestOwner;
  photos: [];
  createdAt: Date;
  updatedAt: Date;
};

type TestAuditLog = {
  adminId: string;
  action: string;
  entityType: string;
  entityId: string;
  capability: AdminCapability;
  reason: string | null;
  requestId: string;
  ipAddress: string;
  deviceId: string | null;
  before: Record<string, unknown>;
  after: Record<string, unknown>;
};

const auditContext = {
  requestId: 'request-123',
  ipAddress: '127.0.0.1',
  deviceId: 'device-hash',
};

function createService({ activeBooking = false } = {}) {
  const users = new Map<string, TestUser>([
    [
      'admin-1',
      {
        id: 'admin-1',
        phone: '+79990000001',
        name: 'Админ',
        city: 'Москва',
        avatarUrl: null,
        role: UserRole.ADMIN,
        kycStatus: null,
        isBlocked: false,
        sessionVersion: 0,
        deletedAt: null,
        createdAt: new Date('2026-06-01T10:00:00.000Z'),
        updatedAt: new Date('2026-06-01T10:00:00.000Z'),
      },
    ],
    [
      'owner-1',
      {
        id: 'owner-1',
        phone: '+79990000002',
        name: 'Иван',
        city: 'Москва',
        avatarUrl: null,
        role: UserRole.USER,
        kycStatus: KycStatus.PENDING,
        isBlocked: false,
        sessionVersion: 0,
        deletedAt: null,
        createdAt: new Date('2026-06-02T10:00:00.000Z'),
        updatedAt: new Date('2026-06-02T10:00:00.000Z'),
      },
    ],
  ]);

  const category: TestCategory = {
    id: 'category-1',
    name: 'Проекторы и экраны',
    slug: 'proektory-i-ekrany',
    iconName: 'hammer',
  };
  const owner: TestOwner = {
    id: 'owner-1',
    phone: '+79990000002',
    name: 'Иван',
    city: 'Москва',
    avatarUrl: null,
    isBlocked: false,
    deletedAt: null,
  };

  function makeItem(overrides: Partial<TestItem> = {}): TestItem {
    return {
      id: overrides.id ?? 'item-1',
      ownerId: overrides.ownerId ?? 'owner-1',
      title: overrides.title ?? 'Проектор Epson',
      description:
        overrides.description ?? 'Надежный проектор для ремонта квартиры',
      condition: overrides.condition ?? ItemCondition.GOOD,
      completeness: overrides.completeness ?? 'Проектор и кабель питания',
      handoverTerms:
        overrides.handoverTerms ?? 'Проверить комплект при передаче',
      pricePerDay: overrides.pricePerDay ?? new Prisma.Decimal(500),
      depositAmount: overrides.depositAmount ?? null,
      status: overrides.status ?? ItemStatus.PENDING,
      rejectReason: overrides.rejectReason ?? null,
      publicArea: overrides.publicArea ?? 'Центральный округ',
      address: overrides.address ?? 'Москва, Тверская 1',
      latitude: overrides.latitude ?? 55.7558,
      longitude: overrides.longitude ?? 37.6173,
      category: overrides.category ?? category,
      owner: overrides.owner ?? owner,
      photos: [],
      createdAt: overrides.createdAt ?? new Date('2026-06-02T10:00:00.000Z'),
      updatedAt: overrides.updatedAt ?? new Date('2026-06-02T10:00:00.000Z'),
    };
  }

  const items = new Map<string, TestItem>([
    ['item-1', makeItem({ id: 'item-1', status: ItemStatus.PENDING })],
    [
      'item-2',
      makeItem({
        id: 'item-2',
        title: 'Дрель Makita',
        status: ItemStatus.APPROVED,
        createdAt: new Date('2026-06-01T09:00:00.000Z'),
      }),
    ],
    ['hidden-item', makeItem({ id: 'hidden-item', status: ItemStatus.HIDDEN })],
  ]);
  const auditLogs: TestAuditLog[] = [];

  const tx = {
    booking: {
      findFirst: jest
        .fn()
        .mockResolvedValue(activeBooking ? { id: 'booking-1' } : null),
    },
    user: {
      updateMany: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string; isBlocked: false; deletedAt: null };
          data: {
            isBlocked: boolean;
            sessionVersion: { increment: number };
          };
        }) => {
          const user = users.get(where.id);
          if (!user || user.isBlocked || user.deletedAt) {
            return Promise.resolve({ count: 0 });
          }
          user.isBlocked = data.isBlocked;
          user.sessionVersion += data.sessionVersion.increment;
          return Promise.resolve({ count: 1 });
        },
      ),
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(users.get(where.id) ?? null);
      }),
    },
    item: {
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        const item = items.get(where.id);
        return Promise.resolve(
          item ? { id: item.id, status: item.status } : null,
        );
      }),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<Pick<TestItem, 'status' | 'rejectReason'>>;
        }) => {
          const item = items.get(where.id);
          if (!item) {
            return Promise.resolve(null);
          }

          Object.assign(item, data, {
            updatedAt: new Date('2026-06-02T11:00:00.000Z'),
          });
          return Promise.resolve(item);
        },
      ),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: { data: TestAuditLog }) => {
        auditLogs.push(data);
        return Promise.resolve(data);
      }),
    },
    notificationOutboxEvent: {
      create: jest.fn(({ data }: { data: Record<string, unknown> }) =>
        Promise.resolve({ id: 'event-1', ...data }),
      ),
    },
  };

  const prisma = {
    user: {
      findMany: jest.fn(
        ({ take }: { orderBy: { createdAt: 'desc' }; take: number }) => {
          return Promise.resolve(
            Array.from(users.values())
              .sort((left, right) => {
                return right.createdAt.getTime() - left.createdAt.getTime();
              })
              .slice(0, take),
          );
        },
      ),
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(users.get(where.id) ?? null);
      }),
    },
    item: {
      findMany: jest.fn(
        ({
          where,
          take,
        }: {
          where: { status: ItemStatus };
          orderBy: { createdAt: 'asc' };
          take: number;
        }) => {
          return Promise.resolve(
            Array.from(items.values())
              .filter((item) => item.status === where.status)
              .sort((left, right) => {
                return left.createdAt.getTime() - right.createdAt.getTime();
              })
              .slice(0, take),
          );
        },
      ),
    },
    $transaction: jest.fn((callback: (client: typeof tx) => Promise<unknown>) =>
      callback(tx),
    ),
  } as unknown as PrismaService;

  return {
    service: new AdminService(prisma),
    auditLogs,
    items,
    users,
    notificationOutboxCreate: tx.notificationOutboxEvent.create,
  };
}

describe('AdminService', () => {
  it('returns users for admin list newest first', async () => {
    const { service } = createService();

    await expect(service.listUsers()).resolves.toMatchObject([
      { id: 'owner-1', phone: '+79990000002', role: UserRole.USER },
      { id: 'admin-1', phone: '+79990000001', role: UserRole.ADMIN },
    ]);
  });

  it('returns user card and rejects unknown user', async () => {
    const { service } = createService();

    await expect(service.getUser('owner-1')).resolves.toMatchObject({
      id: 'owner-1',
      kycStatus: KycStatus.PENDING,
    });
    await expect(service.getUser('missing-user')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('returns pending items for moderation', async () => {
    const { service } = createService();

    const [item] = await service.listPendingItems();

    expect(item).toMatchObject({
      id: 'item-1',
      status: ItemStatus.PENDING,
      condition: ItemCondition.GOOD,
      completeness: 'Проектор и кабель питания',
      pricePerDay: 500,
      publicArea: 'Центральный округ',
      owner: { id: 'owner-1', name: 'Иван' },
    });
    expect(item).not.toHaveProperty('address');
    expect(item).not.toHaveProperty('latitude');
    expect(item).not.toHaveProperty('longitude');
    expect(item.owner).not.toHaveProperty('phone');
  });

  it('blocks a user, revokes sessions, and writes audit log', async () => {
    const { service, auditLogs, users } = createService();

    await expect(
      service.blockUser(
        'admin-1',
        'owner-1',
        { reason: 'Подтверждённое злоупотребление' },
        auditContext,
      ),
    ).resolves.toMatchObject({
      id: 'owner-1',
      isBlocked: true,
    });
    expect(users.get('owner-1')?.sessionVersion).toBe(1);
    expect(auditLogs).toContainEqual({
      adminId: 'admin-1',
      action: 'USER_BLOCKED',
      entityType: 'User',
      entityId: 'owner-1',
      capability: AdminCapability.MODERATION,
      reason: 'Подтверждённое злоупотребление',
      requestId: 'request-123',
      ipAddress: '127.0.0.1',
      deviceId: 'device-hash',
      before: {
        isBlocked: false,
        sessionVersion: 0,
      },
      after: { isBlocked: true, sessionVersion: 1 },
    });
  });

  it('does not block a participant with an unfinished booking', async () => {
    const { service, auditLogs, users } = createService({
      activeBooking: true,
    });

    await expect(
      service.blockUser(
        'admin-1',
        'owner-1',
        { reason: 'Подтверждённое злоупотребление' },
        auditContext,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(users.get('owner-1')?.isBlocked).toBe(false);
    expect(auditLogs).toHaveLength(0);
  });

  it('approves item and writes audit log', async () => {
    const { service, auditLogs, items, notificationOutboxCreate } =
      createService();

    await expect(
      service.approveItem('admin-1', 'item-1', auditContext),
    ).resolves.toMatchObject({
      id: 'item-1',
      status: ItemStatus.APPROVED,
      rejectReason: null,
    });
    expect(items.get('item-1')?.status).toBe(ItemStatus.APPROVED);
    expect(auditLogs).toEqual([
      {
        adminId: 'admin-1',
        action: 'ITEM_APPROVED',
        entityType: 'Item',
        entityId: 'item-1',
        capability: AdminCapability.MODERATION,
        reason: null,
        requestId: 'request-123',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
        before: { status: ItemStatus.PENDING },
        after: { status: ItemStatus.APPROVED, rejectReason: null },
      },
    ]);
    expect(notificationOutboxCreate).toHaveBeenCalledWith({
      data: {
        recipientId: 'owner-1',
        itemId: 'item-1',
        eventType: 'ITEM_APPROVED',
        deduplicationKey: 'item:item-1:ITEM_APPROVED:2026-06-02T11:00:00.000Z',
      },
    });
  });

  it('rejects item with reason and writes audit log', async () => {
    const { service, auditLogs, items, notificationOutboxCreate } =
      createService();
    const reason = 'Фото не показывает состояние вещи';

    await expect(
      service.rejectItem('admin-1', 'item-1', { reason }, auditContext),
    ).resolves.toMatchObject({
      id: 'item-1',
      status: ItemStatus.REJECTED,
      rejectReason: reason,
    });
    expect(items.get('item-1')?.rejectReason).toBe(reason);
    expect(auditLogs).toMatchObject([
      {
        adminId: 'admin-1',
        action: 'ITEM_REJECTED',
        entityType: 'Item',
        entityId: 'item-1',
        capability: AdminCapability.MODERATION,
        reason,
        requestId: 'request-123',
        ipAddress: '127.0.0.1',
        deviceId: 'device-hash',
        before: { status: ItemStatus.PENDING },
        after: { status: ItemStatus.REJECTED, rejectReason: reason },
      },
    ]);
    expect(notificationOutboxCreate).toHaveBeenCalledWith({
      data: {
        recipientId: 'owner-1',
        itemId: 'item-1',
        eventType: 'ITEM_REJECTED',
        deduplicationKey: 'item:item-1:ITEM_REJECTED:2026-06-02T11:00:00.000Z',
      },
    });
  });

  it('does not moderate owner-hidden item', async () => {
    const { service, auditLogs } = createService();

    await expect(
      service.approveItem('admin-1', 'hidden-item', auditContext),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(auditLogs).toHaveLength(0);
  });
});
