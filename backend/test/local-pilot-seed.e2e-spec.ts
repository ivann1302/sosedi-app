import { type INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { CategoryListingPolicy, ItemStatus } from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { seedLocalPilotData } from '../src/operations/local-pilot-seed';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetTestState } from './support/test-state';

const categorySlugs = [
  'proektory-i-ekrany',
  'foto-i-video',
  'igrovye-pristavki',
  'nastolnye-igry',
  'muzykalnye-instrumenty',
  'shvejnye-mashiny',
];

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object');
  }
  return value as Record<string, unknown>;
}

describe('Local pilot seed (e2e)', () => {
  let app: INestApplication<App> | undefined;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
  });

  beforeEach(async () => {
    if (!app) {
      throw new Error('Test app was not initialized');
    }
    await resetTestState(app);
    await prisma.category.createMany({
      data: categorySlugs.map((slug, index) => ({
        name: `Pilot category ${index + 1}`,
        slug,
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      })),
    });
  });

  afterAll(async () => {
    await app?.close();
  });

  it('is idempotent and exposes only approved privacy-safe fixtures', async () => {
    await expect(seedLocalPilotData(prisma)).resolves.toEqual({
      users: 2,
      items: 7,
      favorites: 2,
    });
    await expect(seedLocalPilotData(prisma)).resolves.toEqual({
      users: 2,
      items: 7,
      favorites: 2,
    });

    await expect(prisma.user.count()).resolves.toBe(2);
    await expect(prisma.item.count()).resolves.toBe(7);
    await expect(prisma.favorite.count()).resolves.toBe(2);
    await expect(
      prisma.item.count({ where: { status: ItemStatus.APPROVED } }),
    ).resolves.toBe(6);

    if (!app) {
      throw new Error('Test app was not initialized');
    }
    const response = await request(app.getHttpServer())
      .get('/api/v1/items')
      .query({ limit: 20 })
      .expect(200);
    const body = asRecord(response.body as unknown);
    const items = body.data;
    if (!Array.isArray(items)) {
      throw new Error('Expected public item list');
    }
    expect(items).toHaveLength(6);
    for (const item of items.map(asRecord)) {
      expect(item).not.toHaveProperty('address');
      expect(item).not.toHaveProperty('latitude');
      expect(item).not.toHaveProperty('longitude');
    }
  });
});
