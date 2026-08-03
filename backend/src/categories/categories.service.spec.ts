import { BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CategoriesService } from './categories.service';

type TestCategory = {
  id: string;
  name: string;
  slug: string;
  iconName: string | null;
  sortOrder: number;
  isActive: boolean;
  isAllowedForListings: boolean;
  listingPolicy: 'ALLOWED' | 'RESTRICTED' | 'PROHIBITED';
  safetyNotice: string;
  createdAt: Date;
  updatedAt: Date;
};

function createService(initialCategories: TestCategory[] = []) {
  const categories = new Map<string, TestCategory>();
  const auditEntries: Array<Record<string, unknown>> = [];

  for (const category of initialCategories) {
    categories.set(category.id, category);
  }

  const prisma = {
    category: {
      findMany: jest.fn(() => {
        return Promise.resolve(
          Array.from(categories.values())
            .filter(
              (category) => category.isActive && category.isAllowedForListings,
            )
            .sort(
              (left, right) =>
                left.sortOrder - right.sortOrder ||
                left.name.localeCompare(right.name),
            ),
        );
      }),
      findFirst: jest.fn(({ where }: { where: Partial<TestCategory> }) => {
        return Promise.resolve(
          Array.from(categories.values()).find((category) => {
            return Object.entries(where).every(([key, value]) => {
              return category[key as keyof TestCategory] === value;
            });
          }) ?? null,
        );
      }),
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(categories.get(where.id) ?? null);
      }),
      create: jest.fn(({ data }: { data: Partial<TestCategory> }) => {
        const category: TestCategory = {
          id: `category-${categories.size + 1}`,
          name: data.name ?? 'Категория',
          slug: data.slug ?? 'category',
          iconName: data.iconName ?? null,
          sortOrder: data.sortOrder ?? 0,
          isActive: data.isActive ?? true,
          isAllowedForListings: data.isAllowedForListings ?? false,
          listingPolicy: data.listingPolicy ?? 'RESTRICTED',
          safetyNotice:
            data.safetyNotice ??
            'Категория требует отдельной проверки перед публикацией.',
          createdAt: new Date('2026-06-01T10:00:00.000Z'),
          updatedAt: new Date('2026-06-01T10:00:00.000Z'),
        };
        categories.set(category.id, category);
        return Promise.resolve(category);
      }),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<TestCategory>;
        }) => {
          const category = categories.get(where.id);
          if (!category) {
            return Promise.resolve(null);
          }

          Object.assign(category, data, {
            updatedAt: new Date('2026-06-01T11:00:00.000Z'),
          });
          return Promise.resolve(category);
        },
      ),
    },
    adminAuditLog: {
      create: jest.fn(({ data }: { data: Record<string, unknown> }) => {
        auditEntries.push(data);
        return Promise.resolve(data);
      }),
    },
    $transaction: jest.fn(
      (
        callback: (transaction: typeof prisma) => Promise<unknown>,
      ): Promise<unknown> => callback(prisma),
    ),
  } as unknown as PrismaService;

  return {
    service: new CategoriesService(prisma),
    categories,
    auditEntries,
  };
}

const baseCategories: TestCategory[] = [
  {
    id: 'category-1',
    name: 'Проекторы и экраны',
    slug: 'proektory-i-ekrany',
    iconName: 'projector',
    sortOrder: 20,
    isActive: true,
    isAllowedForListings: true,
    listingPolicy: 'ALLOWED',
    safetyNotice:
      'Перед передачей проверьте комплектность, кабели и исправность устройства.',
    createdAt: new Date('2026-06-01T10:00:00.000Z'),
    updatedAt: new Date('2026-06-01T10:00:00.000Z'),
  },
  {
    id: 'category-2',
    name: 'Фото и видео',
    slug: 'foto-i-video',
    iconName: 'camera',
    sortOrder: 10,
    isActive: true,
    isAllowedForListings: true,
    listingPolicy: 'ALLOWED',
    safetyNotice:
      'Перед передачей проверьте комплектность, аккумулятор и удалите личные данные.',
    createdAt: new Date('2026-06-01T10:00:00.000Z'),
    updatedAt: new Date('2026-06-01T10:00:00.000Z'),
  },
  {
    id: 'category-3',
    name: 'Скрытая категория',
    slug: 'skrytaya-kategoriya',
    iconName: null,
    sortOrder: 5,
    isActive: false,
    isAllowedForListings: false,
    listingPolicy: 'PROHIBITED',
    safetyNotice: 'Публикация этой категории запрещена правилами площадки.',
    createdAt: new Date('2026-06-01T10:00:00.000Z'),
    updatedAt: new Date('2026-06-01T10:00:00.000Z'),
  },
];

describe('CategoriesService', () => {
  const auditContext = {
    requestId: 'category-request-1',
    ipAddress: '127.0.0.1',
    deviceId: 'device-hash',
  };

  it('returns active categories ordered for public list', async () => {
    const { service } = createService(baseCategories);

    await expect(service.listActive()).resolves.toMatchObject([
      { slug: 'foto-i-video', isActive: true },
      { slug: 'proektory-i-ekrany', isActive: true },
    ]);
  });

  it('returns active category by slug', async () => {
    const { service } = createService(baseCategories);

    await expect(
      service.getBySlug('proektory-i-ekrany'),
    ).resolves.toMatchObject({
      id: 'category-1',
      name: 'Проекторы и экраны',
      slug: 'proektory-i-ekrany',
      listingPolicy: 'ALLOWED',
      safetyNotice:
        'Перед передачей проверьте комплектность, кабели и исправность устройства.',
    });
  });

  it('does not return inactive category by slug', async () => {
    const { service } = createService(baseCategories);

    await expect(
      service.getBySlug('skrytaya-kategoriya'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('creates, updates and disables category', async () => {
    const { service, categories, auditEntries } = createService();

    const created = await service.create(
      'admin-1',
      {
        name: 'Фото и видео',
        slug: 'kompressory',
        iconName: 'gauge',
        sortOrder: 60,
      },
      auditContext,
    );

    await expect(
      service.update(
        'admin-1',
        created.id,
        {
          name: 'Фото и видео',
          iconName: null,
        },
        auditContext,
      ),
    ).resolves.toMatchObject({
      name: 'Фото и видео',
      iconName: null,
    });

    await expect(
      service.disable('admin-1', created.id, auditContext),
    ).resolves.toMatchObject({
      isActive: false,
    });
    expect(categories.get(created.id)?.isActive).toBe(false);
    expect(created.isAllowedForListings).toBe(false);
    expect(created.listingPolicy).toBe('RESTRICTED');
    expect(created.safetyNotice).toBe(
      'Категория требует отдельной проверки перед публикацией.',
    );
    expect(auditEntries).toMatchObject([
      {
        adminId: 'admin-1',
        action: 'CATEGORY_CREATED',
        entityId: created.id,
        requestId: auditContext.requestId,
      },
      {
        adminId: 'admin-1',
        action: 'CATEGORY_UPDATED',
        entityId: created.id,
      },
      {
        adminId: 'admin-1',
        action: 'CATEGORY_DISABLED',
        entityId: created.id,
      },
    ]);
    expect(JSON.stringify(auditEntries)).not.toContain('safetyNotice');
  });

  it.each(['name', 'slug', 'sortOrder'])(
    'rejects null update for required field %s',
    async (field) => {
      const { service } = createService(baseCategories);

      await expect(
        service.update(
          'admin-1',
          'category-1',
          {
            [field]: null,
          },
          auditContext,
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    },
  );
});
