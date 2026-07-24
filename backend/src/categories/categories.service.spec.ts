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
  createdAt: Date;
  updatedAt: Date;
};

function createService(initialCategories: TestCategory[] = []) {
  const categories = new Map<string, TestCategory>();

  for (const category of initialCategories) {
    categories.set(category.id, category);
  }

  const prisma = {
    category: {
      findMany: jest.fn(() => {
        return Promise.resolve(
          Array.from(categories.values())
            .filter((category) => category.isActive)
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
  } as unknown as PrismaService;

  return {
    service: new CategoriesService(prisma),
    categories,
  };
}

const baseCategories: TestCategory[] = [
  {
    id: 'category-1',
    name: 'Перфораторы',
    slug: 'perforatory',
    iconName: 'hammer',
    sortOrder: 20,
    isActive: true,
    createdAt: new Date('2026-06-01T10:00:00.000Z'),
    updatedAt: new Date('2026-06-01T10:00:00.000Z'),
  },
  {
    id: 'category-2',
    name: 'Дрели и шуруповерты',
    slug: 'dreli-i-shurupoverty',
    iconName: 'drill',
    sortOrder: 10,
    isActive: true,
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
    createdAt: new Date('2026-06-01T10:00:00.000Z'),
    updatedAt: new Date('2026-06-01T10:00:00.000Z'),
  },
];

describe('CategoriesService', () => {
  it('returns active categories ordered for public list', async () => {
    const { service } = createService(baseCategories);

    await expect(service.listActive()).resolves.toMatchObject([
      { slug: 'dreli-i-shurupoverty', isActive: true },
      { slug: 'perforatory', isActive: true },
    ]);
  });

  it('returns active category by slug', async () => {
    const { service } = createService(baseCategories);

    await expect(service.getBySlug('perforatory')).resolves.toMatchObject({
      id: 'category-1',
      name: 'Перфораторы',
      slug: 'perforatory',
    });
  });

  it('does not return inactive category by slug', async () => {
    const { service } = createService(baseCategories);

    await expect(
      service.getBySlug('skrytaya-kategoriya'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('creates, updates and disables category', async () => {
    const { service, categories } = createService();

    const created = await service.create({
      name: 'Компрессоры',
      slug: 'kompressory',
      iconName: 'gauge',
      sortOrder: 60,
    });

    await expect(
      service.update(created.id, {
        name: 'Компрессоры и пневмоинструмент',
        iconName: null,
      }),
    ).resolves.toMatchObject({
      name: 'Компрессоры и пневмоинструмент',
      iconName: null,
    });

    await expect(service.disable(created.id)).resolves.toMatchObject({
      isActive: false,
    });
    expect(categories.get(created.id)?.isActive).toBe(false);
  });

  it.each(['name', 'slug', 'sortOrder', 'isActive'])(
    'rejects null update for required field %s',
    async (field) => {
      const { service } = createService(baseCategories);

      await expect(
        service.update('category-1', {
          [field]: null,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    },
  );
});
