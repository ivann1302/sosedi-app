import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
  BookingStatus,
  CategoryListingPolicy,
  ItemCondition,
  ItemStatus,
  UserRole,
} from '@prisma/client';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { PrismaService } from './../src/prisma/prisma.service';
import { resetTestState } from './support/test-state';

function asRecord(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Expected an object');
  }

  return value as Record<string, unknown>;
}

describe('Items public API (e2e)', () => {
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

  it('returns the same coarse location and no private fields in list and card', async () => {
    const owner = await prisma.user.create({
      data: {
        phone: '+79990000123',
        name: 'Иван',
        city: 'Москва',
        role: UserRole.USER,
      },
    });
    const category = await prisma.category.create({
      data: {
        name: 'Проекторы и экраны',
        slug: 'proektory-i-ekrany',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
        safetyNotice:
          'Перед передачей проверьте комплектность, кабели и исправность устройства.',
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Проектор Epson',
        description: 'Надёжный проектор для ремонта квартиры',
        condition: ItemCondition.GOOD,
        completeness: 'Проектор, кейс и ограничитель глубины',
        handoverTerms: 'Личная передача по договорённости',
        pricePerDay: 500,
        status: ItemStatus.APPROVED,
        publicArea: 'Центральный округ',
        address: 'Москва, Тверская улица, 1',
        latitude: 55.7558,
        longitude: 37.6173,
        photos: {
          create: {
            originalUrl: 'https://private.example/original.jpg',
            thumbnailUrl: 'https://cdn.example/thumbnail.jpg',
            previewUrl: 'https://cdn.example/preview.jpg',
            isCover: true,
          },
        },
      },
    });

    const listResponse = await request(httpServer())
      .get('/api/v1/items')
      .expect(200);
    await request(httpServer()).get('/api/v1/tools').expect(404);
    const listBody = asRecord(listResponse.body as unknown);
    const listData = listBody.data;
    if (!Array.isArray(listData) || listData.length !== 1) {
      throw new Error('Expected one public item');
    }

    const cardResponse = await request(httpServer())
      .get(`/api/v1/items/${item.id}`)
      .expect(200);
    const cardBody = asRecord(cardResponse.body as unknown);
    const publicItems = [asRecord(listData[0]), asRecord(cardBody.data)];

    for (const publicItem of publicItems) {
      expect(publicItem).toMatchObject({
        id: item.id,
        area: 'Центральный округ',
        approximateLocation: {
          latitude: 55.75,
          longitude: 37.65,
          precision: 'SPARSE',
        },
        distanceBucket: null,
        photos: [
          {
            thumbnailUrl: 'https://cdn.example/thumbnail.jpg',
            previewUrl: 'https://cdn.example/preview.jpg',
          },
        ],
      });
      expect(publicItem).not.toHaveProperty('address');
      expect(publicItem).not.toHaveProperty('latitude');
      expect(publicItem).not.toHaveProperty('longitude');
      expect(publicItem).not.toHaveProperty('distanceMeters');

      const photos = publicItem.photos;
      if (!Array.isArray(photos) || photos.length !== 1) {
        throw new Error('Expected one public photo');
      }
      expect(photos[0]).not.toHaveProperty('originalUrl');
    }

    expect(publicItems[0].approximateLocation).toEqual(
      publicItems[1].approximateLocation,
    );

    const geoResponse = await request(httpServer())
      .get('/api/v1/items')
      .query({
        latitude: 55.75,
        longitude: 37.65,
        radiusKm: 0.1,
        sort: 'distance',
      })
      .expect(200);
    const geoBody = asRecord(geoResponse.body as unknown);
    const geoData = geoBody.data;
    if (!Array.isArray(geoData)) {
      throw new Error('Expected a public geo list');
    }
    expect(geoData).toMatchObject([
      {
        id: item.id,
        approximateLocation: {
          latitude: 55.75,
          longitude: 37.65,
          precision: 'SPARSE',
        },
        distanceBucket: 'UNDER_1_KM',
      },
    ]);
  });

  it('returns private listings only to their authenticated owner', async () => {
    const [owner, other] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990000140', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000141', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Техника для дома',
        slug: 'owned-items-boundary',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const ownItem = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Моющий пылесос',
        description: 'Исправный пылесос для влажной уборки квартиры',
        condition: ItemCondition.GOOD,
        completeness: 'Пылесос, шланг и две насадки',
        handoverTerms: 'Проверка при передаче',
        pricePerDay: 700,
        status: ItemStatus.PENDING,
        publicArea: 'Хамовники',
        address: 'Москва, приватный адрес, 40',
        latitude: 55.73,
        longitude: 37.59,
      },
    });
    await prisma.item.create({
      data: {
        ownerId: other.id,
        categoryId: category.id,
        title: 'Чужой пылесос',
        description:
          'Объявление другого пользователя не должно попасть в ответ',
        condition: ItemCondition.GOOD,
        completeness: 'Пылесос и насадка',
        handoverTerms: 'Проверка при передаче',
        pricePerDay: 500,
        status: ItemStatus.REJECTED,
        publicArea: 'Арбат',
        address: 'Москва, приватный адрес, 41',
        latitude: 55.75,
        longitude: 37.59,
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: owner.id,
        phone: owner.phone,
        role: owner.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );

    await request(httpServer()).get('/api/v1/items/mine').expect(401);
    const response = await request(httpServer())
      .get('/api/v1/items/mine')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    const body = asRecord(response.body as unknown);
    const data = body.data;
    if (!Array.isArray(data)) {
      throw new Error('Expected owned item list');
    }
    expect(data).toHaveLength(1);
    expect(data[0]).toMatchObject({
      id: ownItem.id,
      status: ItemStatus.PENDING,
      address: 'Москва, приватный адрес, 40',
    });
  });

  it('keeps item favorites private and idempotent', async () => {
    const [owner, firstUser, secondUser] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990000142', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000143', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000144', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Избранное e2e',
        slug: 'favorites-e2e',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Проектор для избранного',
        description: 'Публичная карточка для проверки приватного списка',
        condition: ItemCondition.GOOD,
        completeness: 'Проектор и пульт',
        handoverTerms: 'Проверка при передаче',
        pricePerDay: 500,
        status: ItemStatus.APPROVED,
        publicArea: 'Арбат',
        address: 'Москва, приватный адрес, 42',
        latitude: 55.75,
        longitude: 37.59,
      },
    });
    const authorization = async (user: typeof firstUser) => {
      const token = await jwt.signAsync(
        {
          sub: user.id,
          phone: user.phone,
          role: user.role,
          tokenType: 'access',
          sessionVersion: 0,
        },
        { secret: 'e2e-access-secret', expiresIn: '15m' },
      );
      return `Bearer ${token}`;
    };
    const [firstAuthorization, secondAuthorization] = await Promise.all([
      authorization(firstUser),
      authorization(secondUser),
    ]);

    await request(httpServer()).get('/api/v1/items/favorites').expect(401);
    await request(httpServer())
      .put(`/api/v1/items/${item.id}/favorite`)
      .set('Authorization', firstAuthorization)
      .expect(200);
    await request(httpServer())
      .put(`/api/v1/items/${item.id}/favorite`)
      .set('Authorization', firstAuthorization)
      .expect(200);
    await request(httpServer())
      .put(`/api/v1/items/${item.id}/favorite`)
      .set('Authorization', secondAuthorization)
      .expect(200);

    const firstList = await request(httpServer())
      .get('/api/v1/items/favorites')
      .set('Authorization', firstAuthorization)
      .expect(200);
    expect(asRecord(firstList.body as unknown).data).toMatchObject([
      { id: item.id, area: 'Арбат' },
    ]);

    await request(httpServer())
      .delete(`/api/v1/items/${item.id}/favorite`)
      .set('Authorization', firstAuthorization)
      .expect(200);
    await request(httpServer())
      .delete(`/api/v1/items/${item.id}/favorite`)
      .set('Authorization', firstAuthorization)
      .expect(200);
    const secondList = await request(httpServer())
      .get('/api/v1/items/favorites')
      .set('Authorization', secondAuthorization)
      .expect(200);
    expect(asRecord(secondList.body as unknown).data).toMatchObject([
      { id: item.id },
    ]);
  });

  it('lets a lender borrow another item but rejects self-booking in the database', async () => {
    const [firstUser, secondUser] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990000124', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000125', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Проекторы и экраны',
        slug: 'projectors-booking-contract',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    await prisma.item.create({
      data: {
        ownerId: firstUser.id,
        categoryId: category.id,
        title: 'Экран для проектора',
        description: 'Складной экран для домашнего просмотра',
        condition: ItemCondition.LIKE_NEW,
        completeness: 'Экран, стойка и чехол',
        handoverTerms: 'Личная передача по договорённости',
        pricePerDay: 400,
        status: ItemStatus.APPROVED,
        publicArea: 'Южный округ',
        address: 'Москва, приватный адрес, 1',
        latitude: 55.65,
        longitude: 37.62,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: secondUser.id,
        categoryId: category.id,
        title: 'Проектор Epson',
        description: 'Домашний проектор для фильмов и презентаций',
        condition: ItemCondition.GOOD,
        completeness: 'Проектор, пульт, кабель питания и чехол',
        handoverTerms: 'Личная передача по договорённости',
        pricePerDay: 900,
        status: ItemStatus.APPROVED,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес, 2',
        latitude: 55.76,
        longitude: 37.62,
      },
    });

    await expect(
      prisma.booking.create({
        data: {
          itemId: item.id,
          borrowerId: firstUser.id,
          lenderId: secondUser.id,
          startDate: new Date('2026-08-10T00:00:00.000Z'),
          endDate: new Date('2026-08-11T00:00:00.000Z'),
          totalAmount: 1800,
        },
      }),
    ).resolves.toMatchObject({
      borrowerId: firstUser.id,
      lenderId: secondUser.id,
    });

    await expect(
      prisma.booking.create({
        data: {
          itemId: item.id,
          borrowerId: secondUser.id,
          lenderId: secondUser.id,
          startDate: new Date('2026-08-12T00:00:00.000Z'),
          endDate: new Date('2026-08-13T00:00:00.000Z'),
          totalAmount: 1800,
        },
      }),
    ).rejects.toThrow();
  });

  it('requires common item fields and an allowed launch category on create', async () => {
    const user = await prisma.user.create({
      data: { phone: '+79990000126', role: UserRole.USER },
    });
    const [allowedCategory, forbiddenCategory] = await Promise.all([
      prisma.category.create({
        data: {
          name: 'Фото и видео',
          slug: 'foto-i-video-create-contract',
          isAllowedForListings: true,
          listingPolicy: CategoryListingPolicy.ALLOWED,
        },
      }),
      prisma.category.create({
        data: {
          name: 'Категория без legal-разрешения',
          slug: 'not-allowed-create-contract',
          isAllowedForListings: false,
          listingPolicy: CategoryListingPolicy.PROHIBITED,
        },
      }),
    ]);
    const accessToken = await jwt.signAsync(
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
    const authorization = `Bearer ${accessToken}`;
    const clientRequestId = '11111111-1111-4111-8111-111111111111';
    const payload = {
      categoryId: allowedCategory.id,
      title: 'Камера Sony',
      description: 'Камера для семейных событий и небольших съёмок',
      condition: ItemCondition.LIKE_NEW,
      completeness: 'Камера, аккумулятор, зарядное устройство и сумка',
      handoverTerms: 'Личная передача после проверки комплектации',
      pricePerDay: 1200,
      depositAmount: 0,
      publicArea: 'Центральный округ',
      address: 'Москва, приватный адрес, 3',
      latitude: 55.75,
      longitude: 37.61,
      ownershipConfirmed: true,
      conditionConfirmed: true,
      completenessConfirmed: true,
      safetyAndMarketplaceRulesAccepted: true,
      listingRulesVersion: '2026-07-28',
    };

    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .send({ ...payload, completeness: undefined })
      .expect(400);
    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .send({ ...payload, ownershipConfirmed: false })
      .expect(400);
    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .send({ ...payload, listingRulesVersion: '2026-07-27' })
      .expect(400);
    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .send({ ...payload, depositAmount: 1 })
      .expect(400);
    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .send({ ...payload, categoryId: forbiddenCategory.id })
      .expect(404);

    const response = await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .set('X-Request-Id', clientRequestId)
      .send(payload)
      .expect(201);
    const responseBody = asRecord(response.body as unknown);
    const responseData = asRecord(responseBody.data);
    if (typeof responseData.id !== 'string') {
      throw new Error('Expected the created item id');
    }

    expect(responseBody).toMatchObject({
      success: true,
      data: {
        condition: ItemCondition.LIKE_NEW,
        completeness: payload.completeness,
        handoverTerms: payload.handoverTerms,
        status: ItemStatus.PENDING,
        category: {
          safetyNotice:
            'Категория требует отдельной проверки перед публикацией.',
        },
      },
    });

    const repeated = await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .set('X-Request-Id', clientRequestId)
      .send(payload)
      .expect(201);
    expect(asRecord(asRecord(repeated.body as unknown).data).id).toBe(
      responseData.id,
    );

    await request(httpServer())
      .post('/api/v1/items')
      .set('Authorization', authorization)
      .set('X-Request-Id', clientRequestId)
      .send({ ...payload, title: 'Другой заголовок' })
      .expect(409);
    const createdItem = await prisma.item.findUniqueOrThrow({
      where: { id: responseData.id },
    });
    expect(createdItem).toMatchObject({
      ownerId: user.id,
      listingRulesVersion: payload.listingRulesVersion,
      listingRulesAcceptanceMethod: 'ITEM_CREATE_FORM',
      safetyNoticeSnapshot:
        'Категория требует отдельной проверки перед публикацией.',
    });
    expect(createdItem.listingRulesAcceptedAt).toBeInstanceOf(Date);
    expect(createdItem.depositAmount?.toNumber()).toBe(0);
    await expect(
      prisma.user.findUniqueOrThrow({ where: { id: user.id } }),
    ).resolves.toMatchObject({ role: UserRole.USER, kycStatus: null });
  });

  it('rejects listing changes while an unfinished booking exists', async () => {
    const [owner, borrower] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990000127', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990000128', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Музыкальные инструменты',
        slug: 'music-listing-booking-guard',
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Электронное пианино',
        description: 'Исправное пианино для домашних занятий',
        condition: ItemCondition.GOOD,
        completeness: 'Пианино, стойка, педаль и блок питания',
        handoverTerms: 'Личная передача после проверки комплектации',
        pricePerDay: 1000,
        status: ItemStatus.APPROVED,
        publicArea: 'Северный округ',
        address: 'Москва, приватный адрес, 4',
        latitude: 55.84,
        longitude: 37.6,
      },
    });
    await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: borrower.id,
        lenderId: owner.id,
        startDate: new Date('2026-08-10T00:00:00.000Z'),
        endDate: new Date('2026-08-12T00:00:00.000Z'),
        totalAmount: 3000,
        status: BookingStatus.CONFIRMED,
      },
    });
    const accessToken = await jwt.signAsync(
      {
        sub: owner.id,
        phone: owner.phone,
        role: owner.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      {
        secret: 'e2e-access-secret',
        expiresIn: '15m',
      },
    );
    const authorization = `Bearer ${accessToken}`;

    for (const mutate of [
      () =>
        request(httpServer())
          .patch(`/api/v1/items/${item.id}`)
          .set('Authorization', authorization)
          .send({
            pricePerDay: 1200,
            address: 'Москва, новый приватный адрес',
          }),
      () =>
        request(httpServer())
          .patch(`/api/v1/items/${item.id}/hide`)
          .set('Authorization', authorization),
    ]) {
      const response = await mutate().expect(409);
      expect(response.body).toMatchObject({
        success: false,
        data: null,
        error: {
          code: 'ITEM_HAS_UNFINISHED_BOOKINGS',
        },
      });
    }

    const unchangedItem = await prisma.item.findUniqueOrThrow({
      where: { id: item.id },
    });
    expect(unchangedItem).toMatchObject({
      address: 'Москва, приватный адрес, 4',
      status: ItemStatus.APPROVED,
    });
    expect(unchangedItem.pricePerDay.toNumber()).toBe(1000);
  });

  afterAll(async () => {
    await app?.close();
  });
});
