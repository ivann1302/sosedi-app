import { BadRequestException, NotFoundException } from '@nestjs/common';
import { KycStatus, Prisma, ToolStatus, UserRole } from '@prisma/client';
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

type TestTool = {
  id: string;
  ownerId: string;
  title: string;
  description: string;
  pricePerDay: Prisma.Decimal;
  depositAmount: Prisma.Decimal | null;
  status: ToolStatus;
  rejectReason: string | null;
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
  metadata: Record<string, unknown>;
  ipAddress: string | null;
};

function createService() {
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
        role: UserRole.OWNER,
        kycStatus: KycStatus.PENDING,
        isBlocked: false,
        deletedAt: null,
        createdAt: new Date('2026-06-02T10:00:00.000Z'),
        updatedAt: new Date('2026-06-02T10:00:00.000Z'),
      },
    ],
  ]);

  const category: TestCategory = {
    id: 'category-1',
    name: 'Перфораторы',
    slug: 'perforatory',
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

  function makeTool(overrides: Partial<TestTool> = {}): TestTool {
    return {
      id: overrides.id ?? 'tool-1',
      ownerId: overrides.ownerId ?? 'owner-1',
      title: overrides.title ?? 'Перфоратор Bosch',
      description:
        overrides.description ?? 'Надежный перфоратор для ремонта квартиры',
      pricePerDay: overrides.pricePerDay ?? new Prisma.Decimal(500),
      depositAmount: overrides.depositAmount ?? null,
      status: overrides.status ?? ToolStatus.PENDING,
      rejectReason: overrides.rejectReason ?? null,
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

  const tools = new Map<string, TestTool>([
    ['tool-1', makeTool({ id: 'tool-1', status: ToolStatus.PENDING })],
    [
      'tool-2',
      makeTool({
        id: 'tool-2',
        title: 'Дрель Makita',
        status: ToolStatus.APPROVED,
        createdAt: new Date('2026-06-01T09:00:00.000Z'),
      }),
    ],
    ['hidden-tool', makeTool({ id: 'hidden-tool', status: ToolStatus.HIDDEN })],
  ]);
  const auditLogs: TestAuditLog[] = [];

  const tx = {
    tool: {
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        const tool = tools.get(where.id);
        return Promise.resolve(
          tool ? { id: tool.id, status: tool.status } : null,
        );
      }),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<Pick<TestTool, 'status' | 'rejectReason'>>;
        }) => {
          const tool = tools.get(where.id);
          if (!tool) {
            return Promise.resolve(null);
          }

          Object.assign(tool, data, {
            updatedAt: new Date('2026-06-02T11:00:00.000Z'),
          });
          return Promise.resolve(tool);
        },
      ),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: { data: TestAuditLog }) => {
        auditLogs.push(data);
        return Promise.resolve(data);
      }),
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
    tool: {
      findMany: jest.fn(
        ({
          where,
          take,
        }: {
          where: { status: ToolStatus };
          orderBy: { createdAt: 'asc' };
          take: number;
        }) => {
          return Promise.resolve(
            Array.from(tools.values())
              .filter((tool) => tool.status === where.status)
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
    tools,
    users,
  };
}

describe('AdminService', () => {
  it('returns users for admin list newest first', async () => {
    const { service } = createService();

    await expect(service.listUsers()).resolves.toMatchObject([
      { id: 'owner-1', phone: '+79990000002', role: UserRole.OWNER },
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

  it('returns pending tools for moderation', async () => {
    const { service } = createService();

    await expect(service.listPendingTools()).resolves.toMatchObject([
      {
        id: 'tool-1',
        status: ToolStatus.PENDING,
        pricePerDay: 500,
        owner: { phone: '+79990000002' },
      },
    ]);
  });

  it('approves tool and writes audit log', async () => {
    const { service, auditLogs, tools } = createService();

    await expect(
      service.approveTool('admin-1', 'tool-1', '127.0.0.1'),
    ).resolves.toMatchObject({
      id: 'tool-1',
      status: ToolStatus.APPROVED,
      rejectReason: null,
    });
    expect(tools.get('tool-1')?.status).toBe(ToolStatus.APPROVED);
    expect(auditLogs).toEqual([
      {
        adminId: 'admin-1',
        action: 'TOOL_APPROVED',
        entityType: 'Tool',
        entityId: 'tool-1',
        metadata: { previousStatus: ToolStatus.PENDING },
        ipAddress: '127.0.0.1',
      },
    ]);
  });

  it('rejects tool with reason and writes audit log', async () => {
    const { service, auditLogs, tools } = createService();
    const reason = 'Фото не показывает состояние инструмента';

    await expect(
      service.rejectTool('admin-1', 'tool-1', { reason }),
    ).resolves.toMatchObject({
      id: 'tool-1',
      status: ToolStatus.REJECTED,
      rejectReason: reason,
    });
    expect(tools.get('tool-1')?.rejectReason).toBe(reason);
    expect(auditLogs).toMatchObject([
      {
        adminId: 'admin-1',
        action: 'TOOL_REJECTED',
        entityType: 'Tool',
        entityId: 'tool-1',
        metadata: {
          previousStatus: ToolStatus.PENDING,
          rejectReason: reason,
        },
      },
    ]);
  });

  it('does not moderate owner-hidden tool', async () => {
    const { service, auditLogs } = createService();

    await expect(
      service.approveTool('admin-1', 'hidden-tool'),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(auditLogs).toHaveLength(0);
  });
});
