import { PrismaClient } from '@prisma/client';
import {
  assertLocalPilotSeedAllowed,
  seedLocalPilotData,
} from './local-pilot-seed';

const localEnvironment = {
  NODE_ENV: 'development',
  ALLOW_LOCAL_PILOT_SEED: 'true',
  DATABASE_URL:
    'postgresql://sosedi:sosedi@localhost:5432/sosedi?schema=public',
};

describe('local pilot seed guard', () => {
  it('requires an explicit opt-in', () => {
    expect(() =>
      assertLocalPilotSeedAllowed({
        ...localEnvironment,
        ALLOW_LOCAL_PILOT_SEED: undefined,
      }),
    ).toThrow('ALLOW_LOCAL_PILOT_SEED=true');
  });

  it('rejects production even with an explicit opt-in', () => {
    expect(() =>
      assertLocalPilotSeedAllowed({
        ...localEnvironment,
        NODE_ENV: 'production',
      }),
    ).toThrow('production');
  });

  it('rejects a non-loopback PostgreSQL target', () => {
    expect(() =>
      assertLocalPilotSeedAllowed({
        ...localEnvironment,
        DATABASE_URL: 'postgresql://user:pass@db.example/sosedi',
      }),
    ).toThrow('loopback');
  });

  it('allows an explicitly opted-in local development database', () => {
    expect(() => assertLocalPilotSeedAllowed(localEnvironment)).not.toThrow();
  });
});

describe('local pilot fixture photos', () => {
  it('upserts one deterministic bundled cover for every fixture', async () => {
    type ItemUpsertArgs = { create: { clientRequestId: string } };
    type PhotoUpsertArgs = { create: { thumbnailUrl: string } };

    const photoUpsert = jest.fn<Promise<unknown>, [PhotoUpsertArgs]>();
    photoUpsert.mockResolvedValue({});
    const prisma = {
      category: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'category-1', slug: 'proektory-i-ekrany' },
          { id: 'category-2', slug: 'foto-i-video' },
          { id: 'category-3', slug: 'igrovye-pristavki' },
          { id: 'category-4', slug: 'nastolnye-igry' },
          { id: 'category-5', slug: 'muzykalnye-instrumenty' },
          { id: 'category-6', slug: 'shvejnye-mashiny' },
        ]),
      },
      user: {
        upsert: jest
          .fn()
          .mockResolvedValueOnce({ id: 'owner-1' })
          .mockResolvedValueOnce({ id: 'borrower-1' }),
      },
      item: {
        upsert: jest
          .fn<Promise<{ id: string }>, [ItemUpsertArgs]>()
          .mockImplementation(({ create }) =>
            Promise.resolve({ id: create.clientRequestId }),
          ),
      },
      itemPhoto: { upsert: photoUpsert },
      favorite: { upsert: jest.fn().mockResolvedValue({}) },
    } as unknown as PrismaClient;

    await seedLocalPilotData(prisma);

    expect(photoUpsert).toHaveBeenCalledTimes(7);
    const assetUrls = photoUpsert.mock.calls.map(
      ([args]) => args.create.thumbnailUrl,
    );
    expect(assetUrls).toEqual([
      'asset:///assets/images/mock_items/projector.jpg',
      'asset:///assets/images/mock_items/camera.jpg',
      'asset:///assets/images/mock_items/game-console.jpg',
      'asset:///assets/images/mock_items/board-game.jpg',
      'asset:///assets/images/mock_items/acoustic-guitar.jpg',
      'asset:///assets/images/mock_items/sewing-machine.jpg',
      'asset:///assets/images/mock_items/projector-screen.jpg',
    ]);
  });
});
