import {
  DepositOperationKind,
  DepositStatus,
  ItemCondition,
  ItemStatus,
  PrismaClient,
} from '@prisma/client';

describe('deposit money constraints (e2e)', () => {
  const prisma = new PrismaClient();
  let bookingId: string;
  let itemId: string;
  let categoryId: string;
  let lenderId: string;
  let borrowerId: string;

  beforeAll(async () => {
    const suffix = Date.now().toString().slice(-9);
    const [lender, borrower] = await Promise.all([
      prisma.user.create({ data: { phone: `+7901${suffix}` } }),
      prisma.user.create({ data: { phone: `+7902${suffix}` } }),
    ]);
    lenderId = lender.id;
    borrowerId = borrower.id;

    const category = await prisma.category.create({
      data: {
        name: `Deposit constraints ${suffix}`,
        slug: `deposit-constraints-${suffix}`,
      },
    });
    categoryId = category.id;

    const item = await prisma.item.create({
      data: {
        ownerId: lender.id,
        categoryId: category.id,
        title: 'Тестовая вещь с залогом',
        description: 'Проверка ограничений денежных значений в базе данных',
        condition: ItemCondition.GOOD,
        completeness: 'Полный комплект',
        handoverTerms: 'Личная передача',
        pricePerDay: 100,
        depositAmount: 50,
        status: ItemStatus.APPROVED,
        publicArea: 'Тестовый округ',
        address: 'Тестовый адрес',
        latitude: 54.7,
        longitude: 20.5,
      },
    });
    itemId = item.id;

    const booking = await prisma.booking.create({
      data: {
        itemId: item.id,
        borrowerId: borrower.id,
        lenderId: lender.id,
        startDate: new Date('2026-09-10T00:00:00.000Z'),
        endDate: new Date('2026-09-11T00:00:00.000Z'),
        totalAmount: 100,
      },
    });
    bookingId = booking.id;
  });

  afterEach(async () => {
    await prisma.depositOperation.deleteMany({
      where: { deposit: { bookingId } },
    });
    await prisma.bookingDeposit.deleteMany({ where: { bookingId } });
  });

  it('rejects a non-positive deposit amount', async () => {
    await expect(createDeposit({ amount: 0 })).rejects.toThrow();
  });

  it('rejects a deposit in a currency other than RUB', async () => {
    await expect(createDeposit({ currency: 'USD' })).rejects.toThrow();
  });

  it('rejects a non-positive deposit operation amount', async () => {
    const deposit = await createDeposit();

    await expect(
      prisma.depositOperation.create({
        data: {
          depositId: deposit.id,
          kind: DepositOperationKind.REFUND,
          amount: 0,
          idempotencyKey: `zero-operation-${deposit.id}`,
        },
      }),
    ).rejects.toThrow();
  });

  it('rejects a negative resolved amount', async () => {
    await expect(createDeposit({ refundedAmount: -1 })).rejects.toThrow();
  });

  it('rejects resolved amounts exceeding the deposit', async () => {
    await expect(
      createDeposit({ refundedAmount: 30, releasedToLenderAmount: 21 }),
    ).rejects.toThrow();
  });

  it('rejects RESOLVED when the amounts do not equal the deposit', async () => {
    await expect(
      createDeposit({
        status: DepositStatus.RESOLVED,
        refundedAmount: 49,
      }),
    ).rejects.toThrow();
  });

  afterAll(async () => {
    await prisma.booking.delete({ where: { id: bookingId } });
    await prisma.item.delete({ where: { id: itemId } });
    await prisma.category.delete({ where: { id: categoryId } });
    await prisma.user.deleteMany({
      where: { id: { in: [lenderId, borrowerId] } },
    });
    await prisma.$disconnect();
  });

  function createDeposit(
    data: Partial<{
      amount: number;
      currency: string;
      status: DepositStatus;
      refundedAmount: number;
      releasedToLenderAmount: number;
    }> = {},
  ) {
    return prisma.bookingDeposit.create({
      data: {
        bookingId,
        amount: 50,
        policyVersion: 'e2e-deposit-policy-v1',
        disputeWindowSeconds: 86_400,
        ...data,
      },
    });
  }
});
