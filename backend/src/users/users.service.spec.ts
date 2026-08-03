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
  sessionVersion: number;
  deletedAt: Date | null;
  anonymizedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

type DeleteBlockers = {
  activeBooking?: boolean;
  openDispute?: boolean;
  paymentRecord?: boolean;
  kycRecord?: boolean;
};

function createService(
  overrides: Partial<TestUser> = {},
  blockers: DeleteBlockers = {},
) {
  const user: TestUser = {
    id: 'user-1',
    phone: '+79991234567',
    name: 'Иван',
    city: 'Москва',
    avatarUrl: null,
    role: UserRole.USER,
    kycStatus: null,
    isBlocked: false,
    sessionVersion: 0,
    deletedAt: null,
    anonymizedAt: null,
    createdAt: new Date('2026-06-01T10:00:00.000Z'),
    updatedAt: new Date('2026-06-01T10:00:00.000Z'),
    ...overrides,
  };

  type UserUpdateData = Omit<Partial<TestUser>, 'sessionVersion'> & {
    sessionVersion?: { increment: number };
  };
  const applyUserUpdate = (data: UserUpdateData) => {
    const { sessionVersion, ...simpleData } = data;
    Object.assign(user, simpleData, {
      updatedAt: new Date('2026-06-01T11:00:00.000Z'),
    });
    if (sessionVersion) {
      user.sessionVersion += sessionVersion.increment;
    }
  };
  const updateUser = jest.fn(
    ({ where, data }: { where: { id: string }; data: UserUpdateData }) => {
      if (where.id !== user.id) {
        return Promise.resolve(null);
      }

      applyUserUpdate(data);
      return Promise.resolve(user);
    },
  );
  const transactionClient = {
    user: {
      update: updateUser,
      updateMany: jest.fn(
        ({
          where,
          data,
        }: {
          where: {
            id: string;
            deletedAt: { not: null };
            anonymizedAt: null;
          };
          data: UserUpdateData;
        }) => {
          if (
            where.id !== user.id ||
            user.deletedAt === null ||
            user.anonymizedAt !== null
          ) {
            return Promise.resolve({ count: 0 });
          }

          applyUserUpdate(data);
          return Promise.resolve({ count: 1 });
        },
      ),
    },
    booking: {
      findFirst: jest.fn(() =>
        Promise.resolve(blockers.activeBooking ? { id: 'booking-1' } : null),
      ),
    },
    supportTicket: {
      findFirst: jest.fn(() =>
        Promise.resolve(blockers.openDispute ? { id: 'dispute-1' } : null),
      ),
    },
    payment: {
      findFirst: jest.fn(() =>
        Promise.resolve(blockers.paymentRecord ? { id: 'payment-1' } : null),
      ),
    },
    kycDocument: {
      findFirst: jest.fn(() =>
        Promise.resolve(blockers.kycRecord ? { id: 'kyc-1' } : null),
      ),
    },
  };
  const prisma = {
    user: {
      findUnique: jest.fn(({ where }: { where: { id: string } }) => {
        return Promise.resolve(where.id === user.id ? user : null);
      }),
      findMany: jest.fn(() =>
        Promise.resolve(
          user.deletedAt && !user.anonymizedAt ? [{ id: user.id }] : [],
        ),
      ),
      update: updateUser,
    },
    $transaction: jest.fn(
      (callback: (tx: typeof transactionClient) => Promise<unknown>) =>
        callback(transactionClient),
    ),
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
      role: UserRole.USER,
    });
  });

  it('updates editable profile fields without replacing the avatar URL', async () => {
    const { service, user } = createService({
      avatarUrl: 'https://example.ru/existing-avatar.jpg',
    });

    const result = await service.updateMe('user-1', {
      name: 'Петр',
      city: null,
    });

    expect(result).toMatchObject({
      name: 'Петр',
      city: null,
      avatarUrl: 'https://example.ru/existing-avatar.jpg',
    });
    expect(user.phone).toBe('+79991234567');
    expect(user.role).toBe(UserRole.USER);
  });

  it('closes and anonymizes an account without obligations', async () => {
    const { service, user } = createService();

    const result = await service.deleteMe('user-1');

    expect(result.status).toBe('ANONYMIZED');
    expect(result.requestedAt).toBeInstanceOf(Date);
    expect(result.anonymizedAt).toBeInstanceOf(Date);
    expect(user.phone).toBe('deleted:user-1');
    expect(user.name).toBeNull();
    expect(user.city).toBeNull();
    expect(user.avatarUrl).toBeNull();
    expect(user.sessionVersion).toBe(1);
    expect(user.deletedAt).toBeInstanceOf(Date);
    expect(user.anonymizedAt).toBeInstanceOf(Date);
  });

  it.each([
    ['active booking', { activeBooking: true }],
    ['open dispute', { openDispute: true }],
    ['payment retention', { paymentRecord: true }],
    ['KYC retention', { kycRecord: true }],
  ] satisfies [string, DeleteBlockers][])(
    'closes the account but defers anonymization for %s',
    async (_label, blockers) => {
      const { service, user } = createService({}, blockers);

      const result = await service.deleteMe('user-1');

      expect(result.status).toBe('PENDING_OBLIGATIONS');
      expect(result.requestedAt).toBeInstanceOf(Date);
      expect(result.anonymizedAt).toBeNull();
      expect(user.phone).toBe('+79991234567');
      expect(user.name).toBe('Иван');
      expect(user.sessionVersion).toBe(1);
      expect(user.deletedAt).toBeInstanceOf(Date);
      expect(user.anonymizedAt).toBeNull();
    },
  );

  it('anonymizes a closed account after its obligations are complete', async () => {
    const blockers: DeleteBlockers = { activeBooking: true };
    const { service, user } = createService({}, blockers);
    await service.deleteMe('user-1');

    blockers.activeBooking = false;

    await expect(service.finalizeEligibleAccountClosures()).resolves.toBe(1);
    expect(user.phone).toBe('deleted:user-1');
    expect(user.name).toBeNull();
    expect(user.city).toBeNull();
    expect(user.avatarUrl).toBeNull();
    expect(user.anonymizedAt).toBeInstanceOf(Date);
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
