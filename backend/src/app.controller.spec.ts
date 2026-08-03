import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { RedisService } from './redis/redis.service';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        AppService,
        ConfigService,
        {
          provide: PrismaService,
          useValue: { $queryRaw: jest.fn() },
        },
        {
          provide: RedisService,
          useValue: { getClient: jest.fn() },
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('health', () => {
    it('should return API health response', () => {
      expect(appController.getHealth()).toEqual({
        success: true,
        data: { status: 'ok' },
        error: null,
      });
    });

    it('should return API liveness without dependency checks', () => {
      expect(appController.getLiveness()).toEqual({
        success: true,
        data: { status: 'ok' },
        error: null,
      });
    });
  });
});
