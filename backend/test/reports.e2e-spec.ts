import { type INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import {
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
import { S3StorageService } from './../src/upload/s3-storage.service';
import { resetTestState } from './support/test-state';

describe('Reports (e2e)', () => {
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
    })
      .overrideProvider(S3StorageService)
      .useValue({})
      .compile();
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

  it('serializes duplicate reports, rate-limits mass reports and never mutates the item', async () => {
    const [owner, reporter, concurrentReporter] = await Promise.all([
      prisma.user.create({
        data: { phone: '+79990009001', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009002', role: UserRole.USER },
      }),
      prisma.user.create({
        data: { phone: '+79990009003', role: UserRole.USER },
      }),
    ]);
    const category = await prisma.category.create({
      data: {
        name: 'Report tests',
        slug: 'report-tests',
        listingPolicy: CategoryListingPolicy.ALLOWED,
        isAllowedForListings: true,
      },
    });
    const item = await prisma.item.create({
      data: {
        ownerId: owner.id,
        categoryId: category.id,
        title: 'Объявление для жалобы',
        description: 'Описание объявления для проверки очереди жалоб',
        condition: ItemCondition.GOOD,
        completeness: 'Полный комплект',
        handoverTerms: 'Личная передача',
        pricePerDay: 500,
        status: ItemStatus.APPROVED,
        publicArea: 'Центральный округ',
        address: 'Москва, приватный адрес',
        latitude: 55.75,
        longitude: 37.61,
      },
    });

    const authorization = await bearerToken(reporter);
    const concurrentAuthorization = await bearerToken(concurrentReporter);
    const duplicatePayload = {
      targetType: 'ITEM',
      targetId: item.id,
      reason: 'SUSPECTED_FRAUD',
      description: 'Подробное описание подозрительного поведения объявления.',
    };
    const duplicateResponses = await Promise.all([
      request(httpServer())
        .post('/api/v1/reports')
        .set('Authorization', concurrentAuthorization)
        .send(duplicatePayload),
      request(httpServer())
        .post('/api/v1/reports')
        .set('Authorization', concurrentAuthorization)
        .send(duplicatePayload),
    ]);
    expect(
      duplicateResponses.map((response) => response.status).sort(),
    ).toEqual([201, 409]);

    const reasons = [
      'PROHIBITED_CATEGORY',
      'MISLEADING_LISTING',
      'UNSAFE_ITEM',
      'SUSPECTED_FRAUD',
      'OTHER',
    ];
    for (const reason of reasons) {
      await request(httpServer())
        .post('/api/v1/reports')
        .set('Authorization', authorization)
        .send({
          targetType: 'ITEM',
          targetId: item.id,
          reason,
          description:
            'Подробное описание проблемы с объявлением, достаточное для ручной проверки.',
        })
        .expect(201);
    }
    await request(httpServer())
      .post('/api/v1/reports')
      .set('Authorization', authorization)
      .send({
        targetType: 'ITEM',
        targetId: item.id,
        reason: 'UNSAFE_ITEM',
        description: 'Повторная массовая жалоба после исчерпания лимита.',
      })
      .expect(429);

    await expect(
      prisma.item.findUniqueOrThrow({ where: { id: item.id } }),
    ).resolves.toMatchObject({ status: ItemStatus.APPROVED });
  });

  async function bearerToken(user: {
    id: string;
    phone: string;
    role: UserRole;
  }): Promise<string> {
    return `Bearer ${await jwt.signAsync(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        tokenType: 'access',
        sessionVersion: 0,
      },
      { secret: 'e2e-access-secret', expiresIn: '15m' },
    )}`;
  }

  afterAll(async () => {
    await app?.close();
  });
});
