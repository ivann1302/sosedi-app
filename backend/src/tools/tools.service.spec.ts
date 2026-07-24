import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingStatus,
  KycStatus,
  Prisma,
  ToolStatus,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ToolListSort } from './dto/list-tools-query.dto';
import { UpdateToolDto } from './dto/update-tool.dto';
import { ToolsService } from './tools.service';

type TestCategory = {
  id: string;
  name: string;
  slug: string;
  iconName: string | null;
  isActive: boolean;
};

type TestOwner = {
  id: string;
  name: string | null;
  city: string | null;
  avatarUrl: string | null;
  role: UserRole;
  kycStatus: KycStatus | null;
  isBlocked: boolean;
  deletedAt: Date | null;
};

type TestBooking = {
  toolId: string;
  status: BookingStatus;
  startDate: Date;
  endDate: Date;
};

type TestTool = {
  id: string;
  ownerId: string;
  categoryId: string;
  title: string;
  description: string;
  pricePerDay: Prisma.Decimal;
  depositAmount: Prisma.Decimal | null;
  status: ToolStatus;
  rejectReason: string | null;
  address: string;
  latitude: number;
  longitude: number;
  createdAt: Date;
  updatedAt: Date;
  category: Omit<TestCategory, 'isActive'>;
  owner: TestOwner;
  photos: [];
};

type TestToolWhere = {
  id?: string | { in: string[] };
  status?: ToolStatus;
  categoryId?: string;
  category?: { isActive?: boolean };
  owner?: { isBlocked?: boolean; deletedAt?: null };
  pricePerDay?: {
    gte?: number;
    lte?: number;
  };
  bookings?: {
    none: {
      status: { in: BookingStatus[] };
      startDate: { lte: Date };
      endDate: { gte: Date };
    };
  };
};

type TestToolCreateData = {
  ownerId: string;
  categoryId: string;
  title: string;
  description: string;
  pricePerDay: number;
  depositAmount?: number | null;
  status: ToolStatus;
  rejectReason: string | null;
  address: string;
  latitude: number;
  longitude: number;
};

type TestToolUpdateData = Partial<{
  categoryId: string;
  title: string;
  description: string;
  pricePerDay: number;
  depositAmount: number | null;
  status: ToolStatus;
  rejectReason: string | null;
  address: string;
  latitude: number;
  longitude: number;
}>;

function createService() {
  const categories = new Map<string, TestCategory>([
    [
      'category-1',
      {
        id: 'category-1',
        name: 'Перфораторы',
        slug: 'perforatory',
        iconName: 'hammer',
        isActive: true,
      },
    ],
    [
      'category-2',
      {
        id: 'category-2',
        name: 'Скрытая категория',
        slug: 'skrytaya-kategoriya',
        iconName: null,
        isActive: false,
      },
    ],
  ]);
  const owners = new Map<string, TestOwner>([
    [
      'owner-1',
      {
        id: 'owner-1',
        name: 'Иван',
        city: 'Москва',
        avatarUrl: null,
        role: UserRole.RENTER,
        kycStatus: null,
        isBlocked: false,
        deletedAt: null,
      },
    ],
    [
      'blocked-owner',
      {
        id: 'blocked-owner',
        name: 'Заблокированный владелец',
        city: 'Москва',
        avatarUrl: null,
        role: UserRole.OWNER,
        kycStatus: KycStatus.PENDING,
        isBlocked: true,
        deletedAt: null,
      },
    ],
    [
      'deleted-owner',
      {
        id: 'deleted-owner',
        name: 'Удаленный владелец',
        city: 'Москва',
        avatarUrl: null,
        role: UserRole.OWNER,
        kycStatus: KycStatus.PENDING,
        isBlocked: false,
        deletedAt: new Date('2026-06-01T12:00:00.000Z'),
      },
    ],
  ]);
  const bookings: TestBooking[] = [];
  const tools = new Map<string, TestTool>();

  function categoryForTool(categoryId: string): Omit<TestCategory, 'isActive'> {
    const category = categories.get(categoryId);
    if (!category) {
      throw new Error(`Unknown category ${categoryId}`);
    }

    return {
      id: category.id,
      name: category.name,
      slug: category.slug,
      iconName: category.iconName,
    };
  }

  function makeTool(overrides: Partial<TestTool> = {}): TestTool {
    const categoryId = overrides.categoryId ?? 'category-1';
    const ownerId = overrides.ownerId ?? 'owner-1';

    return {
      id: overrides.id ?? `tool-${tools.size + 1}`,
      ownerId,
      categoryId,
      title: overrides.title ?? 'Перфоратор Bosch',
      description:
        overrides.description ?? 'Надежный перфоратор для ремонта квартиры',
      pricePerDay: overrides.pricePerDay ?? new Prisma.Decimal(500),
      depositAmount: overrides.depositAmount ?? null,
      status: overrides.status ?? ToolStatus.APPROVED,
      rejectReason: overrides.rejectReason ?? null,
      address: overrides.address ?? 'Москва, Тверская 1',
      latitude: overrides.latitude ?? 55.7558,
      longitude: overrides.longitude ?? 37.6173,
      createdAt: overrides.createdAt ?? new Date('2026-06-01T10:00:00.000Z'),
      updatedAt: overrides.updatedAt ?? new Date('2026-06-01T10:00:00.000Z'),
      category: categoryForTool(categoryId),
      owner: overrides.owner ?? owners.get(ownerId)!,
      photos: [],
    };
  }

  function storeTool(overrides: Partial<TestTool> = {}) {
    const tool = makeTool(overrides);
    tools.set(tool.id, tool);
    return tool;
  }

  function matchesPublicWhere(tool: TestTool, where: TestToolWhere): boolean {
    const category = categories.get(tool.categoryId);
    const idFilter = where.id;

    if (typeof idFilter === 'object') {
      return idFilter.in.includes(tool.id);
    }

    if (typeof idFilter === 'string' && tool.id !== idFilter) {
      return false;
    }

    if (where.status && tool.status !== where.status) {
      return false;
    }

    if (where.categoryId && tool.categoryId !== where.categoryId) {
      return false;
    }

    if (where.category?.isActive === true && !category?.isActive) {
      return false;
    }

    if (where.owner?.isBlocked === false && tool.owner.isBlocked) {
      return false;
    }

    if (
      where.owner &&
      Object.hasOwn(where.owner, 'deletedAt') &&
      where.owner.deletedAt === null &&
      tool.owner.deletedAt !== null
    ) {
      return false;
    }

    if (
      where.pricePerDay?.gte !== undefined &&
      tool.pricePerDay.lt(where.pricePerDay.gte)
    ) {
      return false;
    }

    if (
      where.pricePerDay?.lte !== undefined &&
      tool.pricePerDay.gt(where.pricePerDay.lte)
    ) {
      return false;
    }

    const bookingFilter = where.bookings?.none;
    if (bookingFilter) {
      const hasOverlap = bookings.some((booking) => {
        return (
          booking.toolId === tool.id &&
          bookingFilter.status.in.includes(booking.status) &&
          booking.startDate <= bookingFilter.startDate.lte &&
          booking.endDate >= bookingFilter.endDate.gte
        );
      });

      if (hasOverlap) {
        return false;
      }
    }

    return true;
  }

  const prisma = {
    user: {
      updateMany: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string; role?: UserRole };
          data: Partial<Pick<TestOwner, 'role' | 'kycStatus'>>;
        }) => {
          const owner = owners.get(where.id);
          if (!owner || (where.role && owner.role !== where.role)) {
            return Promise.resolve({ count: 0 });
          }

          Object.assign(owner, data);
          return Promise.resolve({ count: 1 });
        },
      ),
    },
    category: {
      findFirst: jest.fn(({ where }: { where: Partial<TestCategory> }) => {
        const category = categories.get(where.id ?? '');
        if (!category || category.isActive !== where.isActive) {
          return Promise.resolve(null);
        }

        return Promise.resolve({ id: category.id });
      }),
    },
    tool: {
      create: jest.fn(({ data }: { data: TestToolCreateData }) => {
        const tool = makeTool({
          id: `tool-${tools.size + 1}`,
          ownerId: data.ownerId,
          categoryId: data.categoryId,
          title: data.title,
          description: data.description,
          pricePerDay: new Prisma.Decimal(data.pricePerDay),
          depositAmount:
            data.depositAmount === null || data.depositAmount === undefined
              ? null
              : new Prisma.Decimal(data.depositAmount),
          status: data.status,
          rejectReason: data.rejectReason,
          address: data.address,
          latitude: data.latitude,
          longitude: data.longitude,
        });
        tools.set(tool.id, tool);
        return Promise.resolve(tool);
      }),
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(tools.get(where.id) ?? null);
      }),
      findFirst: jest.fn(({ where }: { where: TestToolWhere }) => {
        return Promise.resolve(
          Array.from(tools.values()).find((tool) =>
            matchesPublicWhere(tool, where),
          ) ?? null,
        );
      }),
      findMany: jest.fn(
        ({
          where,
          take,
          skip,
        }: {
          where: TestToolWhere;
          take?: number;
          skip?: number;
        }) => {
          return Promise.resolve(
            Array.from(tools.values())
              .filter((tool) => matchesPublicWhere(tool, where))
              .slice(skip ?? 0, (skip ?? 0) + (take ?? tools.size)),
          );
        },
      ),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: TestToolUpdateData;
        }) => {
          const tool = tools.get(where.id);
          if (!tool) {
            return Promise.resolve(null);
          }

          if (data.categoryId !== undefined) {
            tool.categoryId = data.categoryId;
            tool.category = categoryForTool(data.categoryId);
          }

          if (data.pricePerDay !== undefined) {
            tool.pricePerDay = new Prisma.Decimal(data.pricePerDay);
          }

          if (Object.hasOwn(data, 'depositAmount')) {
            const depositAmount = data.depositAmount;
            tool.depositAmount =
              depositAmount === null || depositAmount === undefined
                ? null
                : new Prisma.Decimal(depositAmount);
          }

          const plainData: Partial<TestTool> = {};
          if (data.title !== undefined) {
            plainData.title = data.title;
          }
          if (data.description !== undefined) {
            plainData.description = data.description;
          }
          if (data.status !== undefined) {
            plainData.status = data.status;
          }
          if (data.rejectReason !== undefined) {
            plainData.rejectReason = data.rejectReason;
          }
          if (data.address !== undefined) {
            plainData.address = data.address;
          }
          if (data.latitude !== undefined) {
            plainData.latitude = data.latitude;
          }
          if (data.longitude !== undefined) {
            plainData.longitude = data.longitude;
          }

          Object.assign(tool, {
            ...plainData,
            updatedAt: new Date('2026-06-01T11:00:00.000Z'),
          });

          return Promise.resolve(tool);
        },
      ),
    },
    $queryRaw: jest.fn(() => Promise.resolve([])),
  } as unknown as PrismaService & {
    $queryRaw: jest.Mock;
    $transaction: jest.Mock;
  };
  prisma.$transaction = jest.fn(
    <T>(callback: (tx: PrismaService) => Promise<T>) => callback(prisma),
  );

  return {
    service: new ToolsService(prisma),
    prisma,
    categories,
    bookings,
    owners,
    tools,
    storeTool,
  };
}

describe('ToolsService', () => {
  it('creates owner tool with pending moderation status', async () => {
    const { service, tools, owners } = createService();

    const result = await service.create('owner-1', {
      categoryId: 'category-1',
      title: 'Перфоратор Bosch',
      description: 'Надежный перфоратор для ремонта квартиры',
      pricePerDay: 500,
      depositAmount: null,
      address: 'Москва, Тверская 1',
      latitude: 55.7558,
      longitude: 37.6173,
    });

    expect(result.status).toBe(ToolStatus.PENDING);
    expect(result.pricePerDay).toBe(500);
    expect(tools.get(result.id)?.ownerId).toBe('owner-1');
    expect(owners.get('owner-1')).toMatchObject({
      role: UserRole.OWNER,
      kycStatus: KycStatus.PENDING,
    });
  });

  it('rejects inactive category for create and update', async () => {
    const { service, storeTool } = createService();
    const tool = storeTool();

    await expect(
      service.create('owner-1', {
        categoryId: 'category-2',
        title: 'Перфоратор Bosch',
        description: 'Надежный перфоратор для ремонта квартиры',
        pricePerDay: 500,
        address: 'Москва, Тверская 1',
        latitude: 55.7558,
        longitude: 37.6173,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);

    await expect(
      service.updateOwn('owner-1', tool.id, { categoryId: 'category-2' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('updates only own tool and sends it back to moderation', async () => {
    const { service, storeTool, tools } = createService();
    const tool = storeTool({ status: ToolStatus.APPROVED });

    const updated = await service.updateOwn('owner-1', tool.id, {
      title: 'Перфоратор Bosch GBH',
      pricePerDay: 650,
    });

    expect(updated).toMatchObject({
      title: 'Перфоратор Bosch GBH',
      pricePerDay: 650,
      status: ToolStatus.PENDING,
      rejectReason: null,
    });
    expect(tools.get(tool.id)?.status).toBe(ToolStatus.PENDING);

    await expect(
      service.updateOwn('other-owner', tool.id, { title: 'Чужое объявление' }),
    ).rejects.toBeInstanceOf(ForbiddenException);

    await expect(
      service.updateOwn('owner-1', tool.id, {
        title: null,
      } as unknown as UpdateToolDto),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('hides own tool without deleting it', async () => {
    const { service, storeTool, tools } = createService();
    const tool = storeTool({ status: ToolStatus.APPROVED });

    await expect(service.hideOwn('owner-1', tool.id)).resolves.toMatchObject({
      id: tool.id,
      status: ToolStatus.HIDDEN,
    });
    expect(tools.has(tool.id)).toBe(true);
  });

  it('lists only approved public tools with filters', async () => {
    const { service, storeTool, bookings } = createService();
    const available = storeTool({ id: 'tool-available' });
    const booked = storeTool({
      id: 'tool-booked',
      pricePerDay: new Prisma.Decimal(600),
    });
    storeTool({ id: 'tool-pending', status: ToolStatus.PENDING });
    storeTool({ id: 'tool-inactive-category', categoryId: 'category-2' });
    bookings.push({
      toolId: booked.id,
      status: BookingStatus.PENDING,
      startDate: new Date('2026-06-10T00:00:00.000Z'),
      endDate: new Date('2026-06-12T00:00:00.000Z'),
    });

    await expect(
      service.listPublic({
        categoryId: 'category-1',
        minPrice: 100,
        maxPrice: 700,
        availableFrom: '2026-06-10',
        availableTo: '2026-06-11',
      }),
    ).resolves.toMatchObject([{ id: available.id }]);
  });

  it('does not show tools from blocked or deleted owners', async () => {
    const { service, storeTool } = createService();
    const visible = storeTool({ id: 'tool-visible' });
    storeTool({ id: 'tool-blocked-owner', ownerId: 'blocked-owner' });
    storeTool({ id: 'tool-deleted-owner', ownerId: 'deleted-owner' });

    await expect(service.listPublic({})).resolves.toMatchObject([
      { id: visible.id },
    ]);
    await expect(
      service.getPublicById('tool-blocked-owner'),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(
      service.getPublicById('tool-deleted-owner'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns public card only for approved active-category tool', async () => {
    const { service, storeTool } = createService();
    const approved = storeTool({ id: 'tool-approved' });
    const pending = storeTool({
      id: 'tool-pending',
      status: ToolStatus.PENDING,
    });

    await expect(service.getPublicById(approved.id)).resolves.toMatchObject({
      id: approved.id,
    });
    await expect(service.getPublicById(pending.id)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('uses geo query and keeps distance order', async () => {
    const { service, prisma, storeTool } = createService();
    const farther = storeTool({ id: 'tool-farther' });
    const closer = storeTool({ id: 'tool-closer' });
    prisma.$queryRaw.mockResolvedValueOnce([
      { id: closer.id, distanceMeters: 1000 },
      { id: farther.id, distanceMeters: 2000 },
    ]);

    await expect(
      service.listPublic({
        latitude: 55.7558,
        longitude: 37.6173,
        radiusKm: 10,
        sort: ToolListSort.DISTANCE,
      }),
    ).resolves.toMatchObject([
      { id: closer.id, distanceMeters: 1000 },
      { id: farther.id, distanceMeters: 2000 },
    ]);
    expect(prisma.$queryRaw).toHaveBeenCalledTimes(1);
  });

  it('rejects invalid ranges', async () => {
    const { service } = createService();

    await expect(
      service.listPublic({ minPrice: 700, maxPrice: 100 }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(service.listPublic({ radiusKm: 10 })).rejects.toBeInstanceOf(
      BadRequestException,
    );
    await expect(
      service.listPublic({
        latitude: 55.7558,
        longitude: 37.6173,
        radiusKm: 51,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.listPublic({
        availableFrom: '2026-02-31',
        availableTo: '2026-03-02',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
