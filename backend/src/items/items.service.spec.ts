import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingStatus,
  ItemCondition,
  ItemStatus,
  KycStatus,
  Prisma,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ItemListSort } from './dto/list-items-query.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { ItemsService } from './items.service';

type TestCategory = {
  id: string;
  name: string;
  slug: string;
  iconName: string | null;
  isActive: boolean;
  isAllowedForListings: boolean;
  listingPolicy: 'ALLOWED' | 'RESTRICTED' | 'PROHIBITED';
  safetyNotice: string;
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
  itemId: string;
  status: BookingStatus;
  startDate: Date;
  endDate: Date;
};

type TestFavorite = {
  userId: string;
  itemId: string;
  createdAt: Date;
};

type TestItemPhoto = {
  id: string;
  originalUrl: string;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

type TestItem = {
  id: string;
  ownerId: string;
  categoryId: string;
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
  createdAt: Date;
  updatedAt: Date;
  category: Omit<TestCategory, 'isActive' | 'isAllowedForListings'>;
  owner: TestOwner;
  photos: TestItemPhoto[];
};

type TestItemWhere = {
  id?: string | { in: string[] };
  ownerId?: string;
  status?: ItemStatus;
  categoryId?: string;
  publicArea?: string;
  category?: {
    isActive?: boolean;
    isAllowedForListings?: boolean;
    listingPolicy?: 'ALLOWED' | 'RESTRICTED' | 'PROHIBITED';
  };
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
  OR?: Array<{
    title?: { contains: string; mode: 'insensitive' };
    description?: { contains: string; mode: 'insensitive' };
  }>;
};

type TestItemCreateData = {
  ownerId: string;
  categoryId: string;
  title: string;
  description: string;
  condition: ItemCondition;
  completeness: string;
  handoverTerms: string;
  pricePerDay: number;
  depositAmount?: number | null;
  status: ItemStatus;
  rejectReason: string | null;
  publicArea: string;
  address: string;
  latitude: number;
  longitude: number;
};

type TestItemUpdateData = Partial<{
  categoryId: string;
  title: string;
  description: string;
  condition: ItemCondition;
  completeness: string;
  handoverTerms: string;
  pricePerDay: number;
  depositAmount: number | null;
  status: ItemStatus;
  rejectReason: string | null;
  publicArea: string;
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
        name: 'Проекторы и экраны',
        slug: 'proektory-i-ekrany',
        iconName: 'projector',
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: 'ALLOWED',
        safetyNotice:
          'Перед передачей проверьте комплектность, кабели и исправность устройства.',
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
        isAllowedForListings: false,
        listingPolicy: 'RESTRICTED',
        safetyNotice: 'Категория требует отдельной проверки перед публикацией.',
      },
    ],
    [
      'category-3',
      {
        id: 'category-3',
        name: 'Категория без legal-разрешения',
        slug: 'not-allowed',
        iconName: null,
        isActive: true,
        isAllowedForListings: false,
        listingPolicy: 'PROHIBITED',
        safetyNotice: 'Публикация этой категории запрещена правилами площадки.',
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
        role: UserRole.USER,
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
        role: UserRole.USER,
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
        role: UserRole.USER,
        kycStatus: KycStatus.PENDING,
        isBlocked: false,
        deletedAt: new Date('2026-06-01T12:00:00.000Z'),
      },
    ],
  ]);
  const bookings: TestBooking[] = [];
  const favorites: TestFavorite[] = [];
  const items = new Map<string, TestItem>();

  function categoryForItem(
    categoryId: string,
  ): Omit<TestCategory, 'isActive' | 'isAllowedForListings'> {
    const category = categories.get(categoryId);
    if (!category) {
      throw new Error(`Unknown category ${categoryId}`);
    }

    return {
      id: category.id,
      name: category.name,
      slug: category.slug,
      iconName: category.iconName,
      safetyNotice: category.safetyNotice,
    };
  }

  function makeItem(overrides: Partial<TestItem> = {}): TestItem {
    const categoryId = overrides.categoryId ?? 'category-1';
    const ownerId = overrides.ownerId ?? 'owner-1';

    return {
      id: overrides.id ?? `item-${items.size + 1}`,
      ownerId,
      categoryId,
      title: overrides.title ?? 'Проектор Epson',
      description:
        overrides.description ?? 'Домашний проектор в исправном состоянии',
      condition: overrides.condition ?? ItemCondition.GOOD,
      completeness:
        overrides.completeness ?? 'Проектор, пульт, кабель питания и чехол',
      handoverTerms:
        overrides.handoverTerms ?? 'Личная передача по договорённости',
      pricePerDay: overrides.pricePerDay ?? new Prisma.Decimal(500),
      depositAmount: overrides.depositAmount ?? null,
      status: overrides.status ?? ItemStatus.APPROVED,
      rejectReason: overrides.rejectReason ?? null,
      publicArea: overrides.publicArea ?? 'Центральный округ',
      address: overrides.address ?? 'Москва, Тверская 1',
      latitude: overrides.latitude ?? 55.7558,
      longitude: overrides.longitude ?? 37.6173,
      createdAt: overrides.createdAt ?? new Date('2026-06-01T10:00:00.000Z'),
      updatedAt: overrides.updatedAt ?? new Date('2026-06-01T10:00:00.000Z'),
      category: categoryForItem(categoryId),
      owner: overrides.owner ?? owners.get(ownerId)!,
      photos: overrides.photos ?? [],
    };
  }

  function storeItem(overrides: Partial<TestItem> = {}) {
    const item = makeItem(overrides);
    items.set(item.id, item);
    return item;
  }

  function matchesPublicWhere(item: TestItem, where: TestItemWhere): boolean {
    const category = categories.get(item.categoryId);
    const idFilter = where.id;

    if (typeof idFilter === 'object' && !idFilter.in.includes(item.id)) {
      return false;
    }

    if (typeof idFilter === 'string' && item.id !== idFilter) {
      return false;
    }

    if (where.status && item.status !== where.status) {
      return false;
    }

    if (where.categoryId && item.categoryId !== where.categoryId) {
      return false;
    }

    if (where.publicArea && item.publicArea !== where.publicArea) {
      return false;
    }

    if (where.ownerId && item.ownerId !== where.ownerId) {
      return false;
    }

    if (where.OR) {
      const matchesSearch = where.OR.some((condition) => {
        const title = condition.title?.contains.toLowerCase();
        const description = condition.description?.contains.toLowerCase();
        return (
          (title !== undefined && item.title.toLowerCase().includes(title)) ||
          (description !== undefined &&
            item.description.toLowerCase().includes(description))
        );
      });
      if (!matchesSearch) {
        return false;
      }
    }

    if (where.category?.isActive === true && !category?.isActive) {
      return false;
    }

    if (
      where.category?.isAllowedForListings === true &&
      !category?.isAllowedForListings
    ) {
      return false;
    }

    if (
      where.category?.listingPolicy !== undefined &&
      category?.listingPolicy !== where.category.listingPolicy
    ) {
      return false;
    }

    if (where.owner?.isBlocked === false && item.owner.isBlocked) {
      return false;
    }

    if (
      where.owner &&
      Object.hasOwn(where.owner, 'deletedAt') &&
      where.owner.deletedAt === null &&
      item.owner.deletedAt !== null
    ) {
      return false;
    }

    if (
      where.pricePerDay?.gte !== undefined &&
      item.pricePerDay.lt(where.pricePerDay.gte)
    ) {
      return false;
    }

    if (
      where.pricePerDay?.lte !== undefined &&
      item.pricePerDay.gt(where.pricePerDay.lte)
    ) {
      return false;
    }

    const bookingFilter = where.bookings?.none;
    if (bookingFilter) {
      const hasOverlap = bookings.some((booking) => {
        return (
          booking.itemId === item.id &&
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
        if (
          !category ||
          category.isActive !== where.isActive ||
          category.isAllowedForListings !== where.isAllowedForListings ||
          category.listingPolicy !== where.listingPolicy
        ) {
          return Promise.resolve(null);
        }

        return Promise.resolve({ id: category.id });
      }),
    },
    item: {
      create: jest.fn(({ data }: { data: TestItemCreateData }) => {
        const item = makeItem({
          id: `item-${items.size + 1}`,
          ownerId: data.ownerId,
          categoryId: data.categoryId,
          title: data.title,
          description: data.description,
          condition: data.condition,
          completeness: data.completeness,
          handoverTerms: data.handoverTerms,
          pricePerDay: new Prisma.Decimal(data.pricePerDay),
          depositAmount:
            data.depositAmount === null || data.depositAmount === undefined
              ? null
              : new Prisma.Decimal(data.depositAmount),
          status: data.status,
          rejectReason: data.rejectReason,
          publicArea: data.publicArea,
          address: data.address,
          latitude: data.latitude,
          longitude: data.longitude,
        });
        items.set(item.id, item);
        return Promise.resolve(item);
      }),
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(items.get(where.id) ?? null);
      }),
      findFirst: jest.fn(({ where }: { where: TestItemWhere }) => {
        return Promise.resolve(
          Array.from(items.values()).find((item) =>
            matchesPublicWhere(item, where),
          ) ?? null,
        );
      }),
      findMany: jest.fn(
        ({
          where,
          take,
          skip,
        }: {
          where: TestItemWhere;
          take?: number;
          skip?: number;
        }) => {
          return Promise.resolve(
            Array.from(items.values())
              .filter((item) => matchesPublicWhere(item, where))
              .slice(skip ?? 0, (skip ?? 0) + (take ?? items.size)),
          );
        },
      ),
      groupBy: jest.fn(({ where }: { where: TestItemWhere }) => {
        const areas = Array.from(items.values())
          .filter((item) => matchesPublicWhere(item, where))
          .map((item) => item.publicArea)
          .filter((area, index, values) => values.indexOf(area) === index)
          .sort((left, right) => left.localeCompare(right, 'ru'));
        return Promise.resolve(areas.map((publicArea) => ({ publicArea })));
      }),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: TestItemUpdateData;
        }) => {
          const item = items.get(where.id);
          if (!item) {
            return Promise.resolve(null);
          }

          if (data.categoryId !== undefined) {
            item.categoryId = data.categoryId;
            item.category = categoryForItem(data.categoryId);
          }

          if (data.pricePerDay !== undefined) {
            item.pricePerDay = new Prisma.Decimal(data.pricePerDay);
          }

          if (Object.hasOwn(data, 'depositAmount')) {
            const depositAmount = data.depositAmount;
            item.depositAmount =
              depositAmount === null || depositAmount === undefined
                ? null
                : new Prisma.Decimal(depositAmount);
          }

          const plainData: Partial<TestItem> = {};
          if (data.title !== undefined) {
            plainData.title = data.title;
          }
          if (data.description !== undefined) {
            plainData.description = data.description;
          }
          if (data.condition !== undefined) {
            plainData.condition = data.condition;
          }
          if (data.completeness !== undefined) {
            plainData.completeness = data.completeness;
          }
          if (data.handoverTerms !== undefined) {
            plainData.handoverTerms = data.handoverTerms;
          }
          if (data.status !== undefined) {
            plainData.status = data.status;
          }
          if (data.rejectReason !== undefined) {
            plainData.rejectReason = data.rejectReason;
          }
          if (data.publicArea !== undefined) {
            plainData.publicArea = data.publicArea;
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

          Object.assign(item, {
            ...plainData,
            updatedAt: new Date('2026-06-01T11:00:00.000Z'),
          });

          return Promise.resolve(item);
        },
      ),
    },
    booking: {
      findFirst: jest.fn(
        ({
          where,
        }: {
          where: {
            itemId: string;
            status: { in: BookingStatus[] };
          };
        }) => {
          const booking = bookings.find(
            (candidate) =>
              candidate.itemId === where.itemId &&
              where.status.in.includes(candidate.status),
          );

          return Promise.resolve(booking ? { id: 'booking-1' } : null);
        },
      ),
    },
    favorite: {
      findMany: jest.fn(
        ({ where }: { where: { userId: string; item: TestItemWhere } }) => {
          return Promise.resolve(
            favorites
              .filter((favorite) => favorite.userId === where.userId)
              .sort(
                (left, right) =>
                  right.createdAt.getTime() - left.createdAt.getTime(),
              )
              .flatMap((favorite) => {
                const item = items.get(favorite.itemId);
                return item && matchesPublicWhere(item, where.item)
                  ? [{ item }]
                  : [];
              }),
          );
        },
      ),
      upsert: jest.fn(
        ({
          where,
        }: {
          where: { userId_itemId: { userId: string; itemId: string } };
        }) => {
          const { userId, itemId } = where.userId_itemId;
          if (
            !favorites.some(
              (favorite) =>
                favorite.userId === userId && favorite.itemId === itemId,
            )
          ) {
            favorites.push({ userId, itemId, createdAt: new Date() });
          }
          return Promise.resolve({ itemId });
        },
      ),
      deleteMany: jest.fn(
        ({ where }: { where: { userId: string; itemId: string } }) => {
          const index = favorites.findIndex(
            (favorite) =>
              favorite.userId === where.userId &&
              favorite.itemId === where.itemId,
          );
          if (index < 0) {
            return Promise.resolve({ count: 0 });
          }
          favorites.splice(index, 1);
          return Promise.resolve({ count: 1 });
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
    service: new ItemsService(prisma),
    prisma,
    categories,
    bookings,
    favorites,
    owners,
    items,
    storeItem,
  };
}

describe('ItemsService', () => {
  it('creates an item without changing the user product role', async () => {
    const { service, items, owners } = createService();

    const result = await service.create('owner-1', {
      categoryId: 'category-1',
      title: 'Проектор Epson',
      description: 'Домашний проектор в исправном состоянии',
      condition: ItemCondition.GOOD,
      completeness: 'Проектор, пульт, кабель питания и чехол',
      handoverTerms: 'Личная передача по договорённости',
      pricePerDay: 500,
      depositAmount: null,
      publicArea: 'Центральный округ',
      address: 'Москва, Тверская 1',
      latitude: 55.7558,
      longitude: 37.6173,
      ownershipConfirmed: true,
      conditionConfirmed: true,
      completenessConfirmed: true,
      safetyAndMarketplaceRulesAccepted: true,
      listingRulesVersion: '2026-07-28',
    });

    expect(result.status).toBe(ItemStatus.PENDING);
    expect(result.pricePerDay).toBe(500);
    expect(result).toMatchObject({
      publicArea: 'Центральный округ',
      address: 'Москва, Тверская 1',
      latitude: 55.7558,
      longitude: 37.6173,
    });
    expect(items.get(result.id)?.ownerId).toBe('owner-1');
    expect(owners.get('owner-1')).toMatchObject({
      role: UserRole.USER,
      kycStatus: null,
    });
  });

  it('rejects categories outside the active launch whitelist', async () => {
    const { service, storeItem } = createService();
    const item = storeItem();

    await expect(
      service.create('owner-1', {
        categoryId: 'category-2',
        title: 'Проектор Epson',
        description: 'Домашний проектор в исправном состоянии',
        condition: ItemCondition.GOOD,
        completeness: 'Проектор, пульт, кабель питания и чехол',
        handoverTerms: 'Личная передача по договорённости',
        pricePerDay: 500,
        publicArea: 'Центральный округ',
        address: 'Москва, Тверская 1',
        latitude: 55.7558,
        longitude: 37.6173,
        ownershipConfirmed: true,
        conditionConfirmed: true,
        completenessConfirmed: true,
        safetyAndMarketplaceRulesAccepted: true,
        listingRulesVersion: '2026-07-28',
      }),
    ).rejects.toBeInstanceOf(NotFoundException);

    await expect(
      service.updateOwn('owner-1', item.id, { categoryId: 'category-3' }),
    ).rejects.toBeInstanceOf(NotFoundException);

    await expect(
      service.updateOwn('owner-1', item.id, { categoryId: 'category-2' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('updates only own item and sends it back to moderation', async () => {
    const { service, storeItem, items } = createService();
    const item = storeItem({ status: ItemStatus.APPROVED });

    const updated = await service.updateOwn('owner-1', item.id, {
      title: 'Проектор Epson GBH',
      pricePerDay: 650,
    });

    expect(updated).toMatchObject({
      title: 'Проектор Epson GBH',
      pricePerDay: 650,
      status: ItemStatus.PENDING,
      rejectReason: null,
    });
    expect(items.get(item.id)?.status).toBe(ItemStatus.PENDING);

    await expect(
      service.updateOwn('other-owner', item.id, { title: 'Чужое объявление' }),
    ).rejects.toBeInstanceOf(NotFoundException);

    await expect(
      service.updateOwn('owner-1', item.id, {
        title: null,
      } as unknown as UpdateItemDto),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('hides own item without deleting it', async () => {
    const { service, storeItem, items } = createService();
    const item = storeItem({ status: ItemStatus.APPROVED });

    await expect(service.hideOwn('owner-1', item.id)).resolves.toMatchObject({
      id: item.id,
      status: ItemStatus.HIDDEN,
    });
    expect(items.has(item.id)).toBe(true);
  });

  it.each([
    BookingStatus.PENDING,
    BookingStatus.CONFIRMED,
    BookingStatus.ACTIVE,
    BookingStatus.RETURNED,
  ])(
    'keeps the listing unchanged while it has a %s booking',
    async (status) => {
      const { service, storeItem, bookings, items } = createService();
      const item = storeItem({ status: ItemStatus.APPROVED });
      bookings.push({
        itemId: item.id,
        status,
        startDate: new Date('2026-08-10T00:00:00.000Z'),
        endDate: new Date('2026-08-12T00:00:00.000Z'),
      });

      await expect(
        service.updateOwn('owner-1', item.id, {
          pricePerDay: 650,
          address: 'Москва, новый приватный адрес',
        }),
      ).rejects.toBeInstanceOf(ConflictException);
      await expect(service.hideOwn('owner-1', item.id)).rejects.toBeInstanceOf(
        ConflictException,
      );

      expect(items.get(item.id)).toMatchObject({
        pricePerDay: new Prisma.Decimal(500),
        address: 'Москва, Тверская 1',
        status: ItemStatus.APPROVED,
      });
    },
  );

  it.each([BookingStatus.COMPLETED, BookingStatus.CANCELLED])(
    'allows listing changes after a %s booking',
    async (status) => {
      const { service, storeItem, bookings } = createService();
      const item = storeItem({ status: ItemStatus.APPROVED });
      bookings.push({
        itemId: item.id,
        status,
        startDate: new Date('2026-08-10T00:00:00.000Z'),
        endDate: new Date('2026-08-12T00:00:00.000Z'),
      });

      await expect(
        service.updateOwn('owner-1', item.id, { pricePerDay: 650 }),
      ).resolves.toMatchObject({
        pricePerDay: 650,
        status: ItemStatus.PENDING,
      });
      await expect(service.hideOwn('owner-1', item.id)).resolves.toMatchObject({
        status: ItemStatus.HIDDEN,
      });
    },
  );

  it('lists only approved public items with filters', async () => {
    const { service, storeItem, bookings } = createService();
    const available = storeItem({ id: 'item-available' });
    const booked = storeItem({
      id: 'item-booked',
      pricePerDay: new Prisma.Decimal(600),
    });
    storeItem({ id: 'item-pending', status: ItemStatus.PENDING });
    storeItem({ id: 'item-inactive-category', categoryId: 'category-2' });
    bookings.push({
      itemId: booked.id,
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

  it('filters public items by an exact public area', async () => {
    const { service, storeItem } = createService();
    storeItem({ id: 'item-khamovniki', publicArea: 'Хамовники' });
    storeItem({ id: 'item-arbat', publicArea: 'Арбат' });

    await expect(
      service.listPublic({ area: 'Хамовники' }),
    ).resolves.toMatchObject([{ id: 'item-khamovniki' }]);
  });

  it('lists distinct public areas only from visible items', async () => {
    const { service, storeItem } = createService();
    storeItem({ id: 'item-khamovniki-1', publicArea: 'Хамовники' });
    storeItem({ id: 'item-khamovniki-2', publicArea: 'Хамовники' });
    storeItem({ id: 'item-arbat', publicArea: 'Арбат' });
    storeItem({
      id: 'item-hidden',
      publicArea: 'Тверской',
      status: ItemStatus.PENDING,
    });
    storeItem({
      id: 'item-blocked-owner',
      publicArea: 'Якиманка',
      ownerId: 'blocked-owner',
    });

    await expect(service.listPublicAreas()).resolves.toEqual([
      'Арбат',
      'Хамовники',
    ]);
  });

  it('limits a page and uses a unique stable sort tie-breaker', async () => {
    const { service, prisma, storeItem } = createService();
    storeItem({ id: 'item-a' });
    storeItem({ id: 'item-b' });

    await service.listPublic({
      sort: ItemListSort.PRICE_ASC,
      limit: 1,
      offset: 1,
    });

    const findManyCalls = (
      prisma.item.findMany as unknown as {
        mock: { calls: Array<[unknown]> };
      }
    ).mock.calls;
    expect(findManyCalls.at(-1)?.[0]).toEqual(
      expect.objectContaining({
        take: 1,
        skip: 1,
        orderBy: [
          { pricePerDay: 'asc' },
          { createdAt: 'desc' },
          { id: 'desc' },
        ],
      }),
    );
  });

  it('searches approved items by title or description in PostgreSQL', async () => {
    const { service, storeItem } = createService();
    storeItem({
      id: 'item-drill',
      title: 'Аккумуляторная дрель',
      description: 'С кейсом',
    });
    storeItem({
      id: 'item-projector',
      title: 'Проектор',
      description: 'Для домашнего кинотеатра',
    });

    await expect(service.listPublic({ search: '  ДРЕЛЬ  ' })).resolves.toEqual(
      expect.arrayContaining([expect.objectContaining({ id: 'item-drill' })]),
    );
    await expect(service.listPublic({ search: 'кинотеатра' })).resolves.toEqual(
      expect.arrayContaining([
        expect.objectContaining({ id: 'item-projector' }),
      ]),
    );
  });

  it('does not show items from blocked or deleted owners', async () => {
    const { service, storeItem } = createService();
    const visible = storeItem({ id: 'item-visible' });
    storeItem({ id: 'item-blocked-owner', ownerId: 'blocked-owner' });
    storeItem({ id: 'item-deleted-owner', ownerId: 'deleted-owner' });

    await expect(service.listPublic({})).resolves.toMatchObject([
      { id: visible.id },
    ]);
    await expect(
      service.getPublicById('item-blocked-owner'),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(
      service.getPublicById('item-deleted-owner'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('lists only the actor own items across moderation statuses', async () => {
    const { service, storeItem } = createService();
    const pending = storeItem({
      id: 'item-own-pending',
      status: ItemStatus.PENDING,
    });
    const approved = storeItem({
      id: 'item-own-approved',
      status: ItemStatus.APPROVED,
    });
    storeItem({ id: 'item-other', ownerId: 'blocked-owner' });

    await expect(service.listOwn('owner-1')).resolves.toEqual(
      expect.arrayContaining([
        expect.objectContaining({ id: pending.id, status: ItemStatus.PENDING }),
        expect.objectContaining({
          id: approved.id,
          status: ItemStatus.APPROVED,
        }),
      ]),
    );
    await expect(service.listOwn('owner-1')).resolves.toHaveLength(2);
  });

  it('returns public card only for approved active-category item', async () => {
    const { service, storeItem } = createService();
    const approved = storeItem({ id: 'item-approved' });
    const pending = storeItem({
      id: 'item-pending',
      status: ItemStatus.PENDING,
    });

    await expect(service.getPublicById(approved.id)).resolves.toMatchObject({
      id: approved.id,
    });
    await expect(service.getPublicById(pending.id)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('returns a stable coarse location without exact private item data', async () => {
    const { service, storeItem } = createService();
    const item = storeItem({
      id: 'item-private-location',
      publicArea: 'Центральный округ',
      address: 'Москва, Тверская улица, 1',
      latitude: 55.7558,
      longitude: 37.6173,
      photos: [
        {
          id: 'photo-1',
          originalUrl: 'https://private.example/original.jpg',
          thumbnailUrl: 'https://cdn.example/thumbnail.jpg',
          previewUrl: 'https://cdn.example/preview.jpg',
          sortOrder: 0,
          isCover: true,
          createdAt: new Date('2026-06-01T10:00:00.000Z'),
        },
      ],
    });

    const first = await service.getPublicById(item.id);
    const second = await service.getPublicById(item.id);

    expect(first).toEqual(second);
    expect(first).toMatchObject({
      area: 'Центральный округ',
      approximateLocation: {
        latitude: 55.75,
        longitude: 37.65,
        precision: 'SPARSE',
      },
      distanceBucket: null,
      photos: [
        {
          id: 'photo-1',
          thumbnailUrl: 'https://cdn.example/thumbnail.jpg',
          previewUrl: 'https://cdn.example/preview.jpg',
        },
      ],
    });
    expect(first).not.toHaveProperty('address');
    expect(first).not.toHaveProperty('latitude');
    expect(first).not.toHaveProperty('longitude');
    expect(first).not.toHaveProperty('distanceMeters');
    expect(first.photos[0]).not.toHaveProperty('originalUrl');
    expect(first.approximateLocation).not.toEqual({
      latitude: item.latitude,
      longitude: item.longitude,
      precision: 'SPARSE',
    });
  });

  it('uses geo query and keeps distance order', async () => {
    const { service, prisma, storeItem } = createService();
    const farther = storeItem({ id: 'item-farther' });
    const closer = storeItem({ id: 'item-closer' });
    prisma.$queryRaw.mockResolvedValueOnce([
      { id: closer.id, distanceMeters: 1000 },
      { id: farther.id, distanceMeters: 2000 },
    ]);

    await expect(
      service.listPublic({
        latitude: 55.7558,
        longitude: 37.6173,
        radiusKm: 10,
        sort: ItemListSort.DISTANCE,
      }),
    ).resolves.toMatchObject([
      { id: closer.id, distanceBucket: 'FROM_1_TO_3_KM' },
      { id: farther.id, distanceBucket: 'FROM_1_TO_3_KM' },
    ]);
    expect(prisma.$queryRaw).toHaveBeenCalledTimes(1);
  });

  it('rechecks public visibility after the geo query', async () => {
    const { service, prisma, storeItem } = createService();
    const item = storeItem({ id: 'item-hidden-during-query' });
    prisma.$queryRaw.mockImplementationOnce(() => {
      item.publicArea = 'Москва, Тверская улица, 1';
      item.status = ItemStatus.PENDING;
      return Promise.resolve([{ id: item.id, distanceMeters: 1000 }]);
    });

    await expect(
      service.listPublic({
        latitude: 55.7558,
        longitude: 37.6173,
        radiusKm: 10,
        sort: ItemListSort.DISTANCE,
      }),
    ).resolves.toEqual([]);
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

  it('keeps favorites user-scoped, idempotent and public-only', async () => {
    const { service, storeItem, favorites } = createService();
    const visible = storeItem({ id: 'item-visible' });
    const hidden = storeItem({
      id: 'item-hidden',
      status: ItemStatus.PENDING,
    });

    await service.addFavorite('user-1', visible.id);
    await service.addFavorite('user-1', visible.id);
    await service.addFavorite('user-2', visible.id);

    await expect(service.listFavorites('user-1')).resolves.toMatchObject([
      { id: visible.id },
    ]);
    await expect(service.listFavorites('user-3')).resolves.toEqual([]);
    await expect(
      service.addFavorite('user-1', hidden.id),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(favorites).toHaveLength(2);
  });

  it('removes only the actor favorite and stays idempotent', async () => {
    const { service, storeItem } = createService();
    const item = storeItem({ id: 'item-visible' });
    await service.addFavorite('user-1', item.id);
    await service.addFavorite('user-2', item.id);

    await expect(service.removeFavorite('user-1', item.id)).resolves.toEqual({
      itemId: item.id,
    });
    await expect(service.removeFavorite('user-1', item.id)).resolves.toEqual({
      itemId: item.id,
    });
    await expect(service.listFavorites('user-1')).resolves.toEqual([]);
    await expect(service.listFavorites('user-2')).resolves.toMatchObject([
      { id: item.id },
    ]);
  });
});
