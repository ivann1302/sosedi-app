import {
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  PrismaClient,
  UserRole,
  type Item,
} from '@prisma/client';

const LOOPBACK_HOSTS = new Set(['localhost', '127.0.0.1', '[::1]']);
const OWNER_PHONE = '+79990001001';
const BORROWER_PHONE = '+79990001002';

const fixtures = [
  {
    requestId: 'local-pilot-projector',
    category: 'proektory-i-ekrany',
    title: 'Проектор для домашнего кино',
    price: 650,
    area: 'Хамовники',
    latitude: 55.733,
    longitude: 37.574,
    photoId: '10000000-0000-4000-8000-000000000001',
    photoAsset: 'projector.jpg',
    status: ItemStatus.APPROVED,
  },
  {
    requestId: 'local-pilot-camera',
    category: 'foto-i-video',
    title: 'Беззеркальная камера для прогулки',
    price: 900,
    area: 'Арбат',
    latitude: 55.752,
    longitude: 37.592,
    photoId: '10000000-0000-4000-8000-000000000002',
    photoAsset: 'camera.jpg',
    status: ItemStatus.APPROVED,
  },
  {
    requestId: 'local-pilot-console',
    category: 'igrovye-pristavki',
    title: 'Игровая приставка с двумя геймпадами',
    price: 800,
    area: 'Пресненский',
    latitude: 55.761,
    longitude: 37.565,
    photoId: '10000000-0000-4000-8000-000000000003',
    photoAsset: 'game-console.jpg',
    status: ItemStatus.APPROVED,
  },
  {
    requestId: 'local-pilot-board-game',
    category: 'nastolnye-igry',
    title: 'Большая настольная игра для компании',
    price: 250,
    area: 'Хамовники',
    latitude: 55.728,
    longitude: 37.566,
    photoId: '10000000-0000-4000-8000-000000000004',
    photoAsset: 'board-game.jpg',
    status: ItemStatus.APPROVED,
  },
  {
    requestId: 'local-pilot-guitar',
    category: 'muzykalnye-instrumenty',
    title: 'Акустическая гитара в чехле',
    price: 500,
    area: 'Арбат',
    latitude: 55.749,
    longitude: 37.585,
    photoId: '10000000-0000-4000-8000-000000000005',
    photoAsset: 'acoustic-guitar.jpg',
    status: ItemStatus.APPROVED,
  },
  {
    requestId: 'local-pilot-sewing-machine',
    category: 'shvejnye-mashiny',
    title: 'Компактная швейная машина',
    price: 550,
    area: 'Пресненский',
    latitude: 55.764,
    longitude: 37.579,
    photoId: '10000000-0000-4000-8000-000000000006',
    photoAsset: 'sewing-machine.jpg',
    status: ItemStatus.APPROVED,
  },
  {
    requestId: 'local-pilot-pending-projector',
    category: 'proektory-i-ekrany',
    title: 'Портативный экран для проектора',
    price: 300,
    area: 'Хамовники',
    latitude: 55.731,
    longitude: 37.581,
    photoId: '10000000-0000-4000-8000-000000000007',
    photoAsset: 'projector-screen.jpg',
    status: ItemStatus.PENDING,
  },
] as const;

export function assertLocalPilotSeedAllowed(
  environment: NodeJS.ProcessEnv,
): void {
  if (environment.ALLOW_LOCAL_PILOT_SEED !== 'true') {
    throw new Error('Local pilot seed requires ALLOW_LOCAL_PILOT_SEED=true');
  }
  if (environment.NODE_ENV === 'production') {
    throw new Error('Local pilot seed is forbidden in production');
  }
  if (environment.NODE_ENV !== 'development') {
    throw new Error('Local pilot seed requires NODE_ENV=development');
  }

  const rawDatabaseUrl = environment.DATABASE_URL;
  if (!rawDatabaseUrl) {
    throw new Error('Local pilot seed requires DATABASE_URL');
  }

  let databaseUrl: URL;
  try {
    databaseUrl = new URL(rawDatabaseUrl);
  } catch {
    throw new Error('Local pilot seed requires a valid PostgreSQL URL');
  }
  if (
    !['postgres:', 'postgresql:'].includes(databaseUrl.protocol) ||
    !LOOPBACK_HOSTS.has(databaseUrl.hostname)
  ) {
    throw new Error('Local pilot seed requires a loopback PostgreSQL target');
  }
}

export async function seedLocalPilotData(prisma: PrismaClient): Promise<{
  users: number;
  items: number;
  favorites: number;
}> {
  const requiredSlugs = [
    ...new Set(fixtures.map((fixture) => fixture.category)),
  ];
  const categories = await prisma.category.findMany({
    where: {
      slug: { in: requiredSlugs },
      isActive: true,
      isAllowedForListings: true,
      listingPolicy: CategoryListingPolicy.ALLOWED,
    },
    select: { id: true, slug: true },
  });
  const categoryIds = new Map(
    categories.map((category) => [category.slug, category.id]),
  );
  const missing = requiredSlugs.filter((slug) => !categoryIds.has(slug));
  if (missing.length > 0) {
    throw new Error(
      `Run the canonical category seed first; missing: ${missing.join(', ')}`,
    );
  }

  const [owner, borrower] = await Promise.all([
    upsertPilotUser(prisma, OWNER_PHONE, 'Иван · локальный пилот'),
    upsertPilotUser(prisma, BORROWER_PHONE, 'Анна · локальный пилот'),
  ]);

  const items: Item[] = [];
  for (const fixture of fixtures) {
    const categoryId = categoryIds.get(fixture.category);
    if (!categoryId) {
      throw new Error(`Missing fixture category ${fixture.category}`);
    }
    const data = {
      categoryId,
      title: fixture.title,
      description: `Локальное демо-объявление: ${fixture.title}. Вещь исправна и готова к личной передаче.`,
      condition: ItemCondition.GOOD,
      completeness:
        'Основная вещь, необходимые кабели или комплект и инструкция',
      handoverTerms: 'Проверить состояние и комплект при личной передаче',
      pricePerDay: fixture.price,
      depositAmount: null,
      status: fixture.status,
      rejectReason: null,
      publicArea: fixture.area,
      address: `Москва, локальная тестовая точка ${fixtures.indexOf(fixture) + 1}`,
      latitude: fixture.latitude,
      longitude: fixture.longitude,
      listingRulesVersion: null,
      listingRulesAcceptedAt: null,
      listingRulesAcceptanceMethod: null,
      safetyNoticeSnapshot: null,
    };
    const item = await prisma.item.upsert({
      where: {
        ownerId_clientRequestId: {
          ownerId: owner.id,
          clientRequestId: fixture.requestId,
        },
      },
      update: data,
      create: {
        ...data,
        ownerId: owner.id,
        clientRequestId: fixture.requestId,
        clientRequestHash: 'local-pilot-fixture',
      },
    });
    items.push(item);

    const assetUrl = `asset:///assets/images/mock_items/${fixture.photoAsset}`;
    const photoData = {
      itemId: item.id,
      originalUrl: assetUrl,
      thumbnailUrl: assetUrl,
      previewUrl: assetUrl,
      sortOrder: 0,
      isCover: true,
    };
    await prisma.itemPhoto.upsert({
      where: { id: fixture.photoId },
      update: photoData,
      create: { id: fixture.photoId, ...photoData },
    });
  }

  for (const item of items.slice(0, 2)) {
    await prisma.favorite.upsert({
      where: {
        userId_itemId: { userId: borrower.id, itemId: item.id },
      },
      update: {},
      create: { userId: borrower.id, itemId: item.id },
    });
  }

  return { users: 2, items: items.length, favorites: 2 };
}

function upsertPilotUser(prisma: PrismaClient, phone: string, name: string) {
  return prisma.user.upsert({
    where: { phone },
    update: {
      name,
      city: 'Москва',
      role: UserRole.USER,
      isBlocked: false,
      deletedAt: null,
      anonymizedAt: null,
    },
    create: { phone, name, city: 'Москва', role: UserRole.USER },
  });
}
