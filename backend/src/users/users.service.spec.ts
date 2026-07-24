import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from './users.service';

type TestUser = {
  id: string;
  phone: string;
  name: string | null;
  city: string | null;
  avatarUrl: string | null;
  role: UserRole;
  kycStatus: null;
  isBlocked: boolean;
  deletedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

function createService(overrides: Partial<TestUser> = {}) {
  const user: TestUser = {
    id: 'user-1',
    phone: '+79991234567',
    name: 'Иван',
    city: 'Москва',
    avatarUrl: null,
    role: UserRole.RENTER,
    kycStatus: null,
    isBlocked: false,
    deletedAt: null,
    createdAt: new Date('2026-06-01T10:00:00.000Z'),
    updatedAt: new Date('2026-06-01T10:00:00.000Z'),
    ...overrides,
  };

  const prisma = {
    user: {
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(where.id === user.id ? user : null);
      }),
      update: jest.fn(
        ({
          where,
          data,
        }: {
          where: { id: string };
          data: Partial<TestUser>;
        }) => {
          if (where.id !== user.id) {
            return Promise.resolve(null);
          }

          Object.assign(user, data, {
            updatedAt: new Date('2026-06-01T11:00:00.000Z'),
          });
          return Promise.resolve(user);
        },
      ),
    },
  } as unknown as PrismaService;

  return {
    service: new UsersService(prisma),
    prisma,
    user,
  };
}

describe('UsersService', () => {
  it('returns current profile', async () => {
    const { service } = createService({
      avatarUrl: 'https://example.ru/a.png',
    });

    await expect(service.getMe('user-1')).resolves.toMatchObject({
      id: 'user-1',
      phone: '+79991234567',
      name: 'Иван',
      city: 'Москва',
      avatarUrl: 'https://example.ru/a.png',
      role: UserRole.RENTER,
    });
  });

  it('updates editable profile fields', async () => {
    const { service, user } = createService();

    const result = await service.updateMe('user-1', {
      name: 'Петр',
      city: null,
      avatarUrl: 'https://example.ru/avatar.jpg',
    });

    expect(result).toMatchObject({
      name: 'Петр',
      city: null,
      avatarUrl: 'https://example.ru/avatar.jpg',
    });
    expect(user.phone).toBe('+79991234567');
    expect(user.role).toBe(UserRole.RENTER);
  });

  it('soft deletes account without removing related data', async () => {
    const { service, user } = createService();

    await expect(service.deleteMe('user-1')).resolves.toEqual({
      deleted: true,
    });

    expect(user.phone).toBe('deleted:user-1');
    expect(user.name).toBeNull();
    expect(user.city).toBeNull();
    expect(user.avatarUrl).toBeNull();
    expect(user.deletedAt).toBeInstanceOf(Date);
  });

  it('rejects deleted and blocked users', async () => {
    await expect(
      createService({ deletedAt: new Date() }).service.getMe('user-1'),
    ).rejects.toBeInstanceOf(NotFoundException);

    await expect(
      createService({ isBlocked: true }).service.getMe('user-1'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
