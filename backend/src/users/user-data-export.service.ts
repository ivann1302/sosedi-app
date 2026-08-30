import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { readBookingTermsSnapshot } from '../booking/booking-terms';
import { PrismaService } from '../prisma/prisma.service';

export const USER_DATA_EXPORT_SCHEMA_VERSION = '2026-08-30.1';
export const USER_DATA_RETENTION_POLICY_VERSION = 'ADR-0002/2026-07-27';

export type UserDataExport = {
  schemaVersion: string;
  generatedAt: string;
  retentionPolicyVersion: string;
  profile: Record<string, unknown>;
  listings: Record<string, unknown>[];
  bookings: Record<string, unknown>[];
  inbox: Record<string, unknown>[];
  support: Record<string, unknown>[];
  reports: Record<string, unknown>[];
  blocks: Record<string, unknown>[];
  favorites: Record<string, unknown>[];
  documentAcceptances: Record<string, unknown>[];
  financialHistory: Record<string, unknown>[];
  fileManifest: Record<string, unknown>[];
  processing: {
    categories: Record<string, string>[];
    excluded: string[];
  };
};

@Injectable()
export class UserDataExportService {
  constructor(private readonly prisma: PrismaService) {}

  create(userId: string, now = new Date()): Promise<UserDataExport> {
    return this.prisma.$transaction(
      async (tx) => {
        const [user, items, bookings, inbox, support, reports, blocks] =
          await Promise.all([
            tx.user.findFirst({
              where: { id: userId, deletedAt: null, isBlocked: false },
              select: {
                id: true,
                phone: true,
                name: true,
                city: true,
                avatarUrl: true,
                role: true,
                kycStatus: true,
                createdAt: true,
                updatedAt: true,
              },
            }),
            tx.item.findMany({
              where: { ownerId: userId },
              orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
              select: {
                id: true,
                title: true,
                description: true,
                condition: true,
                completeness: true,
                handoverTerms: true,
                pricePerDay: true,
                depositAmount: true,
                status: true,
                rejectReason: true,
                publicArea: true,
                address: true,
                latitude: true,
                longitude: true,
                listingRulesVersion: true,
                listingRulesAcceptedAt: true,
                listingRulesAcceptanceMethod: true,
                safetyNoticeSnapshot: true,
                createdAt: true,
                updatedAt: true,
                category: { select: { name: true, slug: true } },
                photos: {
                  orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }],
                  select: {
                    id: true,
                    sortOrder: true,
                    isCover: true,
                    createdAt: true,
                  },
                },
              },
            }),
            tx.booking.findMany({
              where: {
                OR: [{ borrowerId: userId }, { lenderId: userId }],
              },
              orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
              select: {
                id: true,
                borrowerId: true,
                lenderId: true,
                startDate: true,
                endDate: true,
                totalAmount: true,
                status: true,
                expiresAt: true,
                cancellationReason: true,
                termsSnapshot: true,
                createdAt: true,
                updatedAt: true,
                payment: {
                  select: {
                    amount: true,
                    status: true,
                    createdAt: true,
                    updatedAt: true,
                  },
                },
                transitions: {
                  orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
                  select: {
                    actorId: true,
                    actorType: true,
                    command: true,
                    oldStatus: true,
                    newStatus: true,
                    reason: true,
                    createdAt: true,
                  },
                },
                acts: {
                  orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
                  select: {
                    id: true,
                    authorId: true,
                    stage: true,
                    createdAt: true,
                    confirmedById: true,
                    confirmedAt: true,
                    evidence: {
                      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
                      select: {
                        id: true,
                        sha256: true,
                        createdAt: true,
                      },
                    },
                  },
                },
                messages: {
                  orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
                  select: {
                    id: true,
                    authorId: true,
                    authorRole: true,
                    body: true,
                    createdAt: true,
                  },
                },
                reviews: {
                  orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
                  select: {
                    id: true,
                    authorId: true,
                    rating: true,
                    text: true,
                    publishAt: true,
                    hiddenAt: true,
                    createdAt: true,
                  },
                },
              },
            }),
            tx.inboxEvent.findMany({
              where: { recipientId: userId },
              orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
              select: {
                id: true,
                eventType: true,
                readAt: true,
                createdAt: true,
              },
            }),
            tx.supportTicket.findMany({
              where: { userId },
              orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
              select: {
                id: true,
                type: true,
                subject: true,
                message: true,
                status: true,
                bookingIssueReason: true,
                adminResponse: true,
                respondedAt: true,
                createdAt: true,
                updatedAt: true,
                messages: {
                  orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
                  select: {
                    id: true,
                    authorId: true,
                    authorRole: true,
                    body: true,
                    createdAt: true,
                    attachments: {
                      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
                      select: {
                        id: true,
                        sha256: true,
                        createdAt: true,
                      },
                    },
                  },
                },
              },
            }),
            tx.userReport.findMany({
              where: { reporterId: userId },
              orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
              select: {
                id: true,
                targetType: true,
                reason: true,
                description: true,
                status: true,
                decision: true,
                reviewedAt: true,
                createdAt: true,
                updatedAt: true,
              },
            }),
            tx.userBlock.findMany({
              where: { blockerId: userId },
              orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
              select: { id: true, createdAt: true },
            }),
          ]);
        const favorites = await tx.favorite.findMany({
          where: { userId },
          orderBy: [{ createdAt: 'asc' }, { itemId: 'asc' }],
          select: { itemId: true, createdAt: true },
        });

        if (!user) {
          throw new NotFoundException('Пользователь не найден');
        }

        const documentAcceptances: Record<string, unknown>[] = [];
        const fileManifest: Record<string, unknown>[] = [];
        const financialHistory: Record<string, unknown>[] = [];

        const exportedItems = items.map((item) => {
          if (
            item.listingRulesVersion &&
            item.listingRulesAcceptedAt &&
            item.listingRulesAcceptanceMethod
          ) {
            documentAcceptances.push({
              context: 'LISTING',
              entityId: item.id,
              version: item.listingRulesVersion,
              acceptedAt: item.listingRulesAcceptedAt.toISOString(),
              method: item.listingRulesAcceptanceMethod,
            });
          }
          for (const photo of item.photos) {
            fileManifest.push({
              category: 'ITEM_PHOTO',
              fileId: photo.id,
              entityId: item.id,
              createdAt: photo.createdAt.toISOString(),
            });
          }
          return {
            id: item.id,
            title: item.title,
            description: item.description,
            condition: item.condition,
            completeness: item.completeness,
            handoverTerms: item.handoverTerms,
            pricePerDay: Number(item.pricePerDay),
            depositAmount:
              item.depositAmount === null ? null : Number(item.depositAmount),
            status: item.status,
            moderationReason: item.rejectReason,
            category: item.category,
            location: {
              publicArea: item.publicArea,
              address: item.address,
              latitude: item.latitude,
              longitude: item.longitude,
            },
            safetyNotice: item.safetyNoticeSnapshot,
            photos: item.photos.map((photo) => ({
              id: photo.id,
              sortOrder: photo.sortOrder,
              isCover: photo.isCover,
              createdAt: photo.createdAt.toISOString(),
            })),
            createdAt: item.createdAt.toISOString(),
            updatedAt: item.updatedAt.toISOString(),
          };
        });

        const exportedBookings = bookings.map((booking) => {
          const actorRole =
            booking.borrowerId === userId ? 'BORROWER' : 'LENDER';
          const terms = readBookingTermsSnapshot(booking.termsSnapshot);
          if (terms?.acceptance?.actorId === userId) {
            documentAcceptances.push({
              context: 'BOOKING',
              entityId: booking.id,
              offerVersion: terms.acceptance.offerVersion,
              cancellationPolicyVersion:
                terms.acceptance.cancellationPolicyVersion,
              acceptedAt: terms.acceptance.acceptedAt,
              method: terms.acceptance.method,
            });
          }
          if (booking.payment) {
            financialHistory.push({
              bookingId: booking.id,
              amount: Number(booking.payment.amount),
              currency: 'RUB',
              status: booking.payment.status,
              createdAt: booking.payment.createdAt.toISOString(),
              updatedAt: booking.payment.updatedAt.toISOString(),
            });
          }
          for (const act of booking.acts) {
            if (act.authorId !== userId) {
              continue;
            }
            for (const evidence of act.evidence) {
              fileManifest.push({
                category: 'BOOKING_EVIDENCE',
                fileId: evidence.id,
                entityId: booking.id,
                sha256: evidence.sha256,
                createdAt: evidence.createdAt.toISOString(),
              });
            }
          }
          return {
            id: booking.id,
            actorRole,
            startDate: booking.startDate.toISOString(),
            endDate: booking.endDate.toISOString(),
            totalAmount: Number(booking.totalAmount),
            currency: 'RUB',
            status: booking.status,
            expiresAt: booking.expiresAt?.toISOString() ?? null,
            cancellationReason: booking.cancellationReason,
            terms: terms
              ? {
                  itemTitle: terms.itemTitle,
                  pricePerDay: terms.pricePerDay,
                  days: terms.days,
                  rentalSubtotal: terms.rentalSubtotal,
                  depositAmount: terms.depositAmount,
                  platformFee: terms.platformFee,
                  ownerPayout: terms.ownerPayout,
                  total: terms.total,
                  currency: terms.currency,
                  paymentScenario: terms.paymentScenario,
                  handoverArea: terms.handover.area,
                  listingVersion: terms.listingVersion,
                  offerVersion: terms.offerVersion,
                  cancellationPolicyVersion: terms.cancellationPolicyVersion,
                }
              : null,
            transitions: booking.transitions.map((transition) => ({
              actor:
                transition.actorId === null
                  ? 'SYSTEM'
                  : transition.actorId === userId
                    ? 'SELF'
                    : 'COUNTERPARTY',
              actorType: transition.actorType,
              command: transition.command,
              oldStatus: transition.oldStatus,
              newStatus: transition.newStatus,
              reason: transition.reason,
              createdAt: transition.createdAt.toISOString(),
            })),
            acts: booking.acts.map((act) => ({
              id: act.id,
              author: act.authorId === userId ? 'SELF' : 'COUNTERPARTY',
              stage: act.stage,
              createdAt: act.createdAt.toISOString(),
              confirmedBy:
                act.confirmedById === null
                  ? null
                  : act.confirmedById === userId
                    ? 'SELF'
                    : 'COUNTERPARTY',
              confirmedAt: act.confirmedAt?.toISOString() ?? null,
              evidenceCount: act.evidence.length,
            })),
            messages: booking.messages.map((message) => ({
              id: message.id,
              author:
                message.authorRole === 'SYSTEM'
                  ? 'SYSTEM'
                  : message.authorId === userId
                    ? 'SELF'
                    : 'COUNTERPARTY',
              body: message.body,
              createdAt: message.createdAt.toISOString(),
            })),
            reviews: booking.reviews
              .filter(
                (review) =>
                  review.authorId === userId || review.publishAt <= now,
              )
              .map((review) => ({
                id: review.id,
                author: review.authorId === userId ? 'SELF' : 'COUNTERPARTY',
                rating: review.rating,
                text: review.text,
                published: review.publishAt <= now,
                hidden: review.hiddenAt !== null,
                publishAt: review.publishAt.toISOString(),
                createdAt: review.createdAt.toISOString(),
              })),
            createdAt: booking.createdAt.toISOString(),
            updatedAt: booking.updatedAt.toISOString(),
          };
        });

        const exportedSupport = support.map((ticket) => {
          for (const message of ticket.messages) {
            if (message.authorId !== userId) {
              continue;
            }
            for (const attachment of message.attachments) {
              fileManifest.push({
                category: 'SUPPORT_ATTACHMENT',
                fileId: attachment.id,
                entityId: ticket.id,
                sha256: attachment.sha256,
                createdAt: attachment.createdAt.toISOString(),
              });
            }
          }
          return {
            id: ticket.id,
            type: ticket.type,
            subject: ticket.subject,
            initialMessage: ticket.message,
            status: ticket.status,
            bookingIssueReason: ticket.bookingIssueReason,
            response: ticket.adminResponse,
            respondedAt: ticket.respondedAt?.toISOString() ?? null,
            messages: ticket.messages.map((message) => ({
              id: message.id,
              author: message.authorId === userId ? 'SELF' : 'SUPPORT',
              authorRole: message.authorRole,
              body: message.body,
              createdAt: message.createdAt.toISOString(),
              attachmentCount: message.attachments.length,
            })),
            createdAt: ticket.createdAt.toISOString(),
            updatedAt: ticket.updatedAt.toISOString(),
          };
        });

        return {
          schemaVersion: USER_DATA_EXPORT_SCHEMA_VERSION,
          generatedAt: now.toISOString(),
          retentionPolicyVersion: USER_DATA_RETENTION_POLICY_VERSION,
          profile: {
            id: user.id,
            phone: user.phone,
            name: user.name,
            city: user.city,
            avatarPresent: user.avatarUrl !== null,
            role: user.role,
            kycStatus: user.kycStatus,
            createdAt: user.createdAt.toISOString(),
            updatedAt: user.updatedAt.toISOString(),
          },
          listings: exportedItems,
          bookings: exportedBookings,
          inbox: inbox.map((event) => ({
            id: event.id,
            eventType: event.eventType,
            readAt: event.readAt?.toISOString() ?? null,
            createdAt: event.createdAt.toISOString(),
          })),
          support: exportedSupport,
          reports: reports.map((report) => ({
            id: report.id,
            targetType: report.targetType,
            reason: report.reason,
            description: report.description,
            status: report.status,
            decision: report.decision,
            reviewedAt: report.reviewedAt?.toISOString() ?? null,
            createdAt: report.createdAt.toISOString(),
            updatedAt: report.updatedAt.toISOString(),
          })),
          blocks: blocks.map((block) => ({
            id: block.id,
            target: 'WITHHELD_THIRD_PARTY',
            createdAt: block.createdAt.toISOString(),
          })),
          favorites: favorites.map((favorite) => ({
            itemId: favorite.itemId,
            createdAt: favorite.createdAt.toISOString(),
          })),
          documentAcceptances,
          financialHistory,
          fileManifest,
          processing: {
            categories: PROCESSING_CATEGORIES,
            excluded: EXCLUDED_EXPORT_DATA,
          },
        };
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead },
    );
  }
}

const PROCESSING_CATEGORIES = [
  {
    category: 'PROFILE_AND_LISTINGS',
    purpose: 'Аккаунт и публикация вещей',
    retention: 'До закрытия и завершения законных blocker',
  },
  {
    category: 'BOOKING_AND_ACCEPTANCE',
    purpose: 'Исполнение аренды и доказательство условий',
    retention: 'По ADR-0002 после завершения сделки/претензии',
  },
  {
    category: 'SUPPORT_AND_SAFETY',
    purpose: 'Поддержка, жалобы и безопасность',
    retention: 'По типу записи согласно ADR-0002',
  },
  {
    category: 'FINANCIAL_HISTORY',
    purpose: 'Расчёты и обязательный учёт',
    retention: 'Не менее срока из ADR-0002 и применимого закона',
  },
] satisfies Record<string, string>[];

const EXCLUDED_EXPORT_DATA = [
  'OTP, JWT, refresh и step-up tokens',
  'Антифрод-правила и внутренние admin notes',
  'Чужие контакты и идентификаторы пользователей',
  'Точный чужой pickup address вне отдельного access window',
  'Provider secrets, raw payment payload и storage keys/URLs',
];
