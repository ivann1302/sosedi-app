import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  USER_DATA_EXPORT_SCHEMA_VERSION,
  UserDataExportService,
} from './user-data-export.service';

const createdAt = new Date('2026-07-01T10:00:00.000Z');
const updatedAt = new Date('2026-07-02T10:00:00.000Z');

function createService() {
  const tx = {
    user: {
      findFirst: jest.fn().mockResolvedValue({
        id: 'user-1',
        phone: '+79991234567',
        name: 'Иван',
        city: 'Москва',
        avatarUrl: 'https://private-storage/avatar?signature=secret',
        role: 'USER',
        kycStatus: null,
        createdAt,
        updatedAt,
      }),
    },
    item: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'item-1',
          title: 'Перфоратор',
          description: 'Рабочий',
          condition: 'GOOD',
          completeness: 'Кейс',
          handoverTerms: 'Проверить',
          pricePerDay: new Prisma.Decimal('100.00'),
          depositAmount: null,
          status: 'APPROVED',
          rejectReason: null,
          publicArea: 'Хамовники',
          address: 'Москва, свой адрес, 1',
          latitude: 55.7,
          longitude: 37.6,
          listingRulesVersion: '2026-07-28',
          listingRulesAcceptedAt: createdAt,
          listingRulesAcceptanceMethod: 'ITEM_CREATE_FORM',
          safetyNoticeSnapshot: 'Использовать очки',
          createdAt,
          updatedAt,
          category: { name: 'Инструменты', slug: 'tools' },
          photos: [
            {
              id: 'photo-1',
              sortOrder: 0,
              isCover: true,
              createdAt,
            },
          ],
        },
      ]),
    },
    booking: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'booking-1',
          borrowerId: 'user-1',
          lenderId: 'owner-secret-id',
          startDate: createdAt,
          endDate: updatedAt,
          totalAmount: new Prisma.Decimal('200.00'),
          status: 'CONFIRMED',
          expiresAt: null,
          cancellationReason: null,
          termsSnapshot: {
            itemTitle: 'Чужая вещь',
            lenderId: 'owner-secret-id',
            lenderDisplayName: 'Чужое имя',
            pricePerDay: 100,
            days: 2,
            rentalSubtotal: 200,
            depositAmount: null,
            platformFee: 0,
            ownerPayout: 200,
            total: 200,
            currency: 'RUB',
            paymentScenario: 'PAY_ON_HANDOVER',
            handover: {
              area: 'Хамовники',
              address: 'Чужой точный адрес',
              latitude: 55.8,
              longitude: 37.7,
            },
            listingVersion: '2026-07-28',
            offerVersion: 'offer-v1',
            cancellationPolicyVersion: 'rules-v1',
            acceptance: {
              actorId: 'user-1',
              acceptedAt: createdAt.toISOString(),
              method: 'BOOKING_SUBMIT_CHECKBOX',
              offerVersion: 'offer-v1',
              cancellationPolicyVersion: 'rules-v1',
            },
          },
          createdAt,
          updatedAt,
          payment: {
            amount: new Prisma.Decimal('200.00'),
            status: 'PENDING',
            createdAt,
            updatedAt,
            rawPayload: { secret: 'provider-secret' },
          },
          transitions: [
            {
              actorId: 'owner-secret-id',
              actorType: 'USER',
              command: 'CONFIRM',
              oldStatus: 'PENDING',
              newStatus: 'CONFIRMED',
              reason: null,
              createdAt,
            },
          ],
          acts: [
            {
              id: 'act-self',
              authorId: 'user-1',
              stage: 'HANDOVER',
              createdAt,
              confirmedById: 'owner-secret-id',
              confirmedAt: updatedAt,
              evidence: [
                { id: 'evidence-self', sha256: 'a'.repeat(64), createdAt },
              ],
            },
            {
              id: 'act-other',
              authorId: 'owner-secret-id',
              stage: 'RETURN',
              createdAt,
              confirmedById: null,
              confirmedAt: null,
              evidence: [
                { id: 'evidence-other', sha256: 'b'.repeat(64), createdAt },
              ],
            },
          ],
          messages: [
            {
              id: 'booking-message-self',
              authorId: 'user-1',
              authorRole: 'BORROWER',
              body: 'Когда удобно встретиться?',
              createdAt,
            },
            {
              id: 'booking-message-other',
              authorId: 'owner-secret-id',
              authorRole: 'LENDER',
              body: 'После 18:00',
              createdAt: updatedAt,
            },
          ],
          reviews: [
            {
              id: 'review-self',
              authorId: 'user-1',
              rating: 5,
              text: 'Отличная аренда.',
              publishAt: updatedAt,
              hiddenAt: null,
              createdAt,
            },
            {
              id: 'review-unpublished-counterparty',
              authorId: 'owner-secret-id',
              rating: 1,
              text: 'Скрыто double-blind до deadline.',
              publishAt: new Date('2030-08-01T00:00:00.000Z'),
              hiddenAt: null,
              createdAt,
            },
          ],
        },
      ]),
    },
    inboxEvent: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'inbox-1',
          eventType: 'BOOKING_CONFIRMED',
          readAt: null,
          createdAt,
        },
      ]),
    },
    supportTicket: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'ticket-1',
          type: 'GENERAL',
          subject: 'Вопрос',
          message: 'Помогите',
          status: 'OPEN',
          bookingIssueReason: null,
          adminResponse: 'Ответ',
          respondedAt: updatedAt,
          createdAt,
          updatedAt,
          messages: [
            {
              id: 'message-self',
              authorId: 'user-1',
              authorRole: 'USER',
              body: 'Мой текст',
              createdAt,
              attachments: [
                { id: 'support-self', sha256: 'c'.repeat(64), createdAt },
              ],
            },
            {
              id: 'message-admin',
              authorId: 'admin-secret-id',
              authorRole: 'ADMIN',
              body: 'Ответ поддержки',
              createdAt: updatedAt,
              attachments: [
                { id: 'support-admin', sha256: 'd'.repeat(64), createdAt },
              ],
            },
          ],
        },
      ]),
    },
    userReport: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'report-1',
          targetType: 'USER',
          targetId: 'reported-secret-id',
          reason: 'FRAUD',
          description: 'Описание',
          status: 'OPEN',
          decision: null,
          reviewedAt: null,
          createdAt,
          updatedAt,
        },
      ]),
    },
    userBlock: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'block-1',
          blockedId: 'blocked-secret-id',
          createdAt,
        },
      ]),
    },
    favorite: {
      findMany: jest.fn().mockResolvedValue([
        {
          itemId: 'item-favorite',
          createdAt,
        },
      ]),
    },
  };
  const transaction = jest.fn(
    (callback: (client: typeof tx) => Promise<unknown>) => callback(tx),
  );
  const prisma = { $transaction: transaction } as unknown as PrismaService;

  return { service: new UserDataExportService(prisma), transaction };
}

describe('UserDataExportService', () => {
  it('exports self data while excluding secrets and third-party details', async () => {
    const { service, transaction } = createService();

    const result = await service.create(
      'user-1',
      new Date('2026-07-30T10:00:00.000Z'),
    );
    const serialized = JSON.stringify(result);

    expect(result.schemaVersion).toBe(USER_DATA_EXPORT_SCHEMA_VERSION);
    expect(result.profile).toMatchObject({
      phone: '+79991234567',
      avatarPresent: true,
    });
    expect(result.listings[0]).toMatchObject({
      location: { address: 'Москва, свой адрес, 1' },
    });
    expect(result.favorites).toEqual([
      {
        itemId: 'item-favorite',
        createdAt: createdAt.toISOString(),
      },
    ]);
    expect(result.bookings[0]).toMatchObject({
      actorRole: 'BORROWER',
      terms: { handoverArea: 'Хамовники' },
      messages: [
        { author: 'SELF', body: 'Когда удобно встретиться?' },
        { author: 'COUNTERPARTY', body: 'После 18:00' },
      ],
      reviews: [
        expect.objectContaining({
          author: 'SELF',
          rating: 5,
          published: true,
        }),
      ],
    });
    expect(result.fileManifest).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ fileId: 'photo-1' }),
        expect.objectContaining({ fileId: 'evidence-self' }),
        expect.objectContaining({ fileId: 'support-self' }),
      ]),
    );
    expect(serialized).not.toContain('private-storage');
    expect(serialized).not.toContain('owner-secret-id');
    expect(serialized).not.toContain('admin-secret-id');
    expect(serialized).not.toContain('reported-secret-id');
    expect(serialized).not.toContain('blocked-secret-id');
    expect(serialized).not.toContain('Чужой точный адрес');
    expect(serialized).not.toContain('provider-secret');
    expect(serialized).not.toContain('evidence-other');
    expect(serialized).not.toContain('support-admin');
    expect(serialized).not.toContain('Скрыто double-blind');
    expect(transaction).toHaveBeenCalledWith(
      expect.any(Function),
      expect.objectContaining({
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      }),
    );
  });
});
