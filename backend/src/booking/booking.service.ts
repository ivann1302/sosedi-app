import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BookingStatus, ItemStatus, Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { TooManyRequestsException } from '../common/http/too-many-requests.exception';
import { hashIdempotentPayload } from '../common/http/idempotency';
import { PrismaService } from '../prisma/prisma.service';
import { parseBookingPeriod } from './booking-period';
import { BookingEventType, bookingEventKey } from './booking-events';
import {
  readBoundBookingTermsSnapshot,
  type BookingTermsSnapshot,
  toSnapshotJson,
} from './booking-terms';
import { BookingResponseDto } from './dto/booking-response.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { ExtendBookingDto } from './dto/extend-booking.dto';
import { ParticipantBookingResponseDto } from './dto/participant-booking-response.dto';

const PENDING_TTL_MS = 15 * 60 * 1000;
export const BOOKING_MAX_ACTIVE_PENDING = 5;
export const BOOKING_COMPETING_CANCELLATION_REASON =
  'COMPETING_REQUEST_CONFIRMED';
export const BOOKING_BORROWER_CANCELLATION_REASON = 'BORROWER_CANCELLED';
export const BOOKING_LENDER_CANCELLATION_REASON = 'LENDER_DECLINED';
const HANDOVER_VISIBLE_STATUSES = new Set<BookingStatus>([
  BookingStatus.CONFIRMED,
  BookingStatus.ACTIVE,
]);

@Injectable()
export class BookingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async create(
    borrowerId: string,
    dto: CreateBookingDto,
    requestId: string = randomUUID(),
  ): Promise<BookingResponseDto> {
    const legalTerms = requireApprovedMarketplaceTerms(this.config);
    requireMarketplaceTermsAcceptance(dto, legalTerms);
    const period = parseBookingPeriod(dto.startDate, dto.endDate);
    const now = new Date();
    const clientRequestHash = hashIdempotentPayload(dto);

    const booking = await this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${borrowerId}))`;

        const repeated = await tx.booking.findUnique({
          where: {
            borrowerId_clientRequestId: {
              borrowerId,
              clientRequestId: requestId,
            },
          },
        });
        if (repeated) {
          if (repeated.clientRequestHash !== clientRequestHash) {
            throw new ConflictException({
              code: 'IDEMPOTENCY_KEY_REUSED',
              message: 'Идентификатор запроса уже использован',
            });
          }
          return repeated;
        }

        const activePendingCount = await tx.booking.count({
          where: {
            borrowerId,
            status: BookingStatus.PENDING,
            expiresAt: { gt: now },
          },
        });
        if (activePendingCount >= BOOKING_MAX_ACTIVE_PENDING) {
          throw new TooManyRequestsException(
            `Можно одновременно ожидать подтверждения не более ${BOOKING_MAX_ACTIVE_PENDING} бронирований`,
          );
        }

        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${dto.itemId}))`;

        const item = await tx.item.findFirst({
          where: {
            id: dto.itemId,
            status: ItemStatus.APPROVED,
            owner: { isBlocked: false, deletedAt: null },
          },
          select: {
            id: true,
            ownerId: true,
            title: true,
            pricePerDay: true,
            depositAmount: true,
            publicArea: true,
            address: true,
            latitude: true,
            longitude: true,
            listingRulesVersion: true,
            updatedAt: true,
            owner: { select: { name: true } },
          },
        });
        if (!item) {
          throw new NotFoundException('Объявление недоступно');
        }
        if (item.ownerId === borrowerId) {
          throw new BadRequestException('Нельзя бронировать собственную вещь');
        }
        if (item.depositAmount && !item.depositAmount.isZero()) {
          throw new ConflictException({
            code: 'ITEM_DEPOSIT_NOT_SUPPORTED',
            message: 'Бронирование с залогом пока недоступно',
          });
        }
        const interactionBlock = await tx.userBlock.findFirst({
          where: {
            OR: [
              { blockerId: borrowerId, blockedId: item.ownerId },
              { blockerId: item.ownerId, blockedId: borrowerId },
            ],
          },
          select: { id: true },
        });
        if (interactionBlock) {
          throw new ConflictException({
            code: 'USER_INTERACTION_BLOCKED',
            message: 'Бронирование недоступно',
          });
        }

        const calendarConflict = await tx.itemUnavailablePeriod.findFirst({
          where: {
            itemId: item.id,
            startDate: { lte: period.endDate },
            endDate: { gte: period.startDate },
          },
          select: { id: true },
        });
        if (calendarConflict) {
          throw new ConflictException({
            code: 'CALENDAR_CONFLICT',
            message: 'Вещь недоступна в выбранный период',
          });
        }

        const conflict = await tx.booking.findFirst({
          where: {
            itemId: item.id,
            startDate: { lte: period.endDate },
            endDate: { gte: period.startDate },
            OR: [
              {
                status: {
                  in: [BookingStatus.CONFIRMED, BookingStatus.ACTIVE],
                },
              },
              {
                status: BookingStatus.PENDING,
                expiresAt: { gt: now },
              },
            ],
          },
          select: { id: true },
        });
        if (conflict) {
          throw new ConflictException({
            code: 'BOOKING_CONFLICT',
            message: 'Выбранный период уже занят',
          });
        }

        const totalAmount = item.pricePerDay.mul(period.days);
        const rentalSubtotal = totalAmount.toNumber();
        const depositAmount = item.depositAmount?.toNumber() ?? null;
        const snapshot: BookingTermsSnapshot = {
          itemTitle: item.title,
          lenderId: item.ownerId,
          lenderDisplayName: item.owner.name,
          pricePerDay: item.pricePerDay.toNumber(),
          days: period.days,
          rentalSubtotal,
          depositAmount,
          platformFee: 0,
          ownerPayout: rentalSubtotal,
          total: rentalSubtotal + (depositAmount ?? 0),
          currency: 'RUB',
          paymentScenario: 'PAY_ON_HANDOVER',
          handover: {
            area: item.publicArea,
            address: item.address,
            latitude: item.latitude,
            longitude: item.longitude,
          },
          listingVersion: [
            item.listingRulesVersion ?? 'legacy',
            item.updatedAt.toISOString(),
          ].join(':'),
          offerVersion: legalTerms.offerVersion,
          cancellationPolicyVersion: legalTerms.cancellationPolicyVersion,
          acceptance: {
            actorId: borrowerId,
            acceptedAt: now.toISOString(),
            method: 'BOOKING_SUBMIT_CHECKBOX',
            offerVersion: legalTerms.offerVersion,
            cancellationPolicyVersion: legalTerms.cancellationPolicyVersion,
          },
        };
        const createdBooking = await tx.booking.create({
          data: {
            itemId: item.id,
            borrowerId,
            lenderId: item.ownerId,
            clientRequestId: requestId,
            clientRequestHash,
            startDate: period.startDate,
            endDate: period.endDate,
            totalAmount,
            status: BookingStatus.PENDING,
            expiresAt: new Date(now.getTime() + PENDING_TTL_MS),
            termsSnapshot: toSnapshotJson(snapshot),
          },
        });
        await tx.bookingTransitionHistory.create({
          data: {
            bookingId: createdBooking.id,
            actorId: borrowerId,
            actorType: 'BORROWER',
            command: 'CREATE',
            oldStatus: null,
            newStatus: BookingStatus.PENDING,
            requestId,
          },
        });
        await tx.notificationOutboxEvent.create({
          data: {
            bookingId: createdBooking.id,
            eventType: BookingEventType.CREATED,
            deduplicationKey: bookingEventKey(
              createdBooking.id,
              BookingEventType.CREATED,
            ),
          },
        });
        return createdBooking;
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted },
    );

    return {
      id: booking.id,
      itemId: booking.itemId,
      borrowerId: booking.borrowerId,
      lenderId: booking.lenderId,
      startDate: booking.startDate,
      endDate: booking.endDate,
      days: period.days,
      totalAmount: booking.totalAmount.toNumber(),
      status: booking.status,
      expiresAt: booking.expiresAt,
      cancellationReason: booking.cancellationReason,
      createdAt: booking.createdAt,
    };
  }

  async confirm(
    lenderId: string,
    bookingId: string,
    requestId: string = randomUUID(),
  ): Promise<BookingResponseDto> {
    const now = new Date();
    const confirmed = await this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
        const candidate = await tx.booking.findFirst({
          where: { id: bookingId, lenderId },
        });
        if (!candidate) {
          throw new NotFoundException('Бронирование не найдено');
        }

        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${candidate.itemId}))`;
        const booking = await tx.booking.findFirst({
          where: { id: bookingId, lenderId },
        });
        if (!booking) {
          throw new NotFoundException('Бронирование не найдено');
        }
        if (
          booking.status !== BookingStatus.PENDING ||
          !booking.expiresAt ||
          booking.expiresAt <= now
        ) {
          throw new ConflictException({
            code: 'INVALID_BOOKING_TRANSITION',
            message: 'Бронирование нельзя подтвердить',
          });
        }

        const competitors = await tx.booking.findMany({
          where: {
            id: { not: booking.id },
            itemId: booking.itemId,
            status: BookingStatus.PENDING,
            expiresAt: { gt: now },
            startDate: { lte: booking.endDate },
            endDate: { gte: booking.startDate },
          },
          select: { id: true },
        });

        const selected = await tx.booking.update({
          where: { id: booking.id },
          data: {
            status: BookingStatus.CONFIRMED,
            cancellationReason: null,
            expiresAt: null,
          },
        });
        if (competitors.length > 0) {
          await tx.booking.updateMany({
            where: {
              id: { in: competitors.map((candidate) => candidate.id) },
              status: BookingStatus.PENDING,
            },
            data: {
              status: BookingStatus.CANCELLED,
              cancellationReason: BOOKING_COMPETING_CANCELLATION_REASON,
            },
          });
        }
        await tx.bookingTransitionHistory.createMany({
          data: [
            {
              bookingId: selected.id,
              actorId: lenderId,
              actorType: 'LENDER',
              command: 'CONFIRM',
              oldStatus: BookingStatus.PENDING,
              newStatus: BookingStatus.CONFIRMED,
              requestId,
            },
            ...competitors.map((candidate) => ({
              bookingId: candidate.id,
              actorId: lenderId,
              actorType: 'LENDER',
              command: 'CANCEL_COMPETING',
              oldStatus: BookingStatus.PENDING,
              newStatus: BookingStatus.CANCELLED,
              reason: BOOKING_COMPETING_CANCELLATION_REASON,
              requestId,
            })),
          ],
        });
        await tx.notificationOutboxEvent.createMany({
          data: [
            {
              bookingId: selected.id,
              eventType: BookingEventType.CONFIRMED,
              deduplicationKey: bookingEventKey(
                selected.id,
                BookingEventType.CONFIRMED,
              ),
            },
            ...competitors.map((candidate) => ({
              bookingId: candidate.id,
              eventType: BookingEventType.COMPETING_CANCELLED,
              deduplicationKey: bookingEventKey(
                candidate.id,
                BookingEventType.COMPETING_CANCELLED,
              ),
            })),
          ],
          skipDuplicates: true,
        });
        return selected;
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted },
    );

    const days =
      Math.floor(
        (confirmed.endDate.getTime() - confirmed.startDate.getTime()) /
          86_400_000,
      ) + 1;
    return {
      id: confirmed.id,
      itemId: confirmed.itemId,
      borrowerId: confirmed.borrowerId,
      lenderId: confirmed.lenderId,
      startDate: confirmed.startDate,
      endDate: confirmed.endDate,
      days,
      totalAmount: confirmed.totalAmount.toNumber(),
      status: confirmed.status,
      expiresAt: confirmed.expiresAt,
      cancellationReason: confirmed.cancellationReason,
      createdAt: confirmed.createdAt,
    };
  }

  async listForParticipant(
    actorId: string,
  ): Promise<ParticipantBookingResponseDto[]> {
    const bookings = await this.prisma.booking.findMany({
      where: {
        OR: [{ borrowerId: actorId }, { lenderId: actorId }],
      },
      include: {
        borrower: { select: { phone: true } },
        lender: { select: { phone: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return bookings.map((booking) =>
      this.toParticipantResponse(actorId, booking),
    );
  }

  async cancelPending(
    actorId: string,
    bookingId: string,
    requestId: string = randomUUID(),
  ): Promise<BookingResponseDto> {
    const cancelled = await this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
      const booking = await tx.booking.findFirst({
        where: {
          id: bookingId,
          OR: [{ borrowerId: actorId }, { lenderId: actorId }],
        },
      });
      if (!booking) {
        throw new NotFoundException('Бронирование не найдено');
      }

      const isBorrower = booking.borrowerId === actorId;
      const reason = isBorrower
        ? BOOKING_BORROWER_CANCELLATION_REASON
        : BOOKING_LENDER_CANCELLATION_REASON;
      if (
        booking.status === BookingStatus.CANCELLED &&
        booking.cancellationReason === reason
      ) {
        return booking;
      }
      if (
        booking.status !== BookingStatus.PENDING ||
        !booking.expiresAt ||
        booking.expiresAt <= new Date()
      ) {
        throw new ConflictException({
          code: 'INVALID_BOOKING_TRANSITION',
          message:
            'До утверждения cancellation policy можно отменить только ожидающую заявку',
        });
      }

      const updated = await tx.booking.update({
        where: { id: booking.id },
        data: {
          status: BookingStatus.CANCELLED,
          cancellationReason: reason,
          expiresAt: null,
        },
      });
      await tx.bookingTransitionHistory.create({
        data: {
          bookingId: booking.id,
          actorId,
          actorType: isBorrower ? 'BORROWER' : 'LENDER',
          command: 'CANCEL',
          oldStatus: BookingStatus.PENDING,
          newStatus: BookingStatus.CANCELLED,
          reason,
          requestId,
        },
      });
      await tx.notificationOutboxEvent.create({
        data: {
          bookingId: booking.id,
          eventType: BookingEventType.CANCELLED,
          deduplicationKey: bookingEventKey(
            booking.id,
            BookingEventType.CANCELLED,
          ),
        },
      });
      return updated;
    });

    const days =
      Math.floor(
        (cancelled.endDate.getTime() - cancelled.startDate.getTime()) /
          86_400_000,
      ) + 1;
    return {
      id: cancelled.id,
      itemId: cancelled.itemId,
      borrowerId: cancelled.borrowerId,
      lenderId: cancelled.lenderId,
      startDate: cancelled.startDate,
      endDate: cancelled.endDate,
      days,
      totalAmount: cancelled.totalAmount.toNumber(),
      status: cancelled.status,
      expiresAt: cancelled.expiresAt,
      cancellationReason: cancelled.cancellationReason,
      createdAt: cancelled.createdAt,
    };
  }

  async getForParticipant(
    actorId: string,
    bookingId: string,
  ): Promise<ParticipantBookingResponseDto> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        OR: [{ borrowerId: actorId }, { lenderId: actorId }],
      },
      include: {
        borrower: { select: { phone: true } },
        lender: { select: { phone: true } },
      },
    });
    if (!booking) {
      throw new NotFoundException('Бронирование не найдено');
    }
    return this.toParticipantResponse(actorId, booking);
  }

  async rejectExtension(
    actorId: string,
    bookingId: string,
    dto: ExtendBookingDto,
  ): Promise<never> {
    void dto.endDate;
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        OR: [{ borrowerId: actorId }, { lenderId: actorId }],
      },
      select: { id: true },
    });
    if (!booking) {
      throw new NotFoundException('Бронирование не найдено');
    }
    throw new ConflictException({
      code: 'BOOKING_EXTENSION_NOT_SUPPORTED',
      message: 'Продление бронирования не поддерживается в MVP',
    });
  }

  private toParticipantResponse(
    actorId: string,
    booking: Prisma.BookingGetPayload<{
      include: {
        borrower: { select: { phone: true } };
        lender: { select: { phone: true } };
      };
    }>,
  ): ParticipantBookingResponseDto {
    const days =
      Math.floor(
        (booking.endDate.getTime() - booking.startDate.getTime()) / 86_400_000,
      ) + 1;
    const snapshot = readBoundBookingTermsSnapshot(booking.termsSnapshot, {
      borrowerId: booking.borrowerId,
      lenderId: booking.lenderId,
      days,
      totalAmount: booking.totalAmount.toNumber(),
    });
    const canSeeHandover = HANDOVER_VISIBLE_STATUSES.has(booking.status);
    const isBorrower = booking.borrowerId === actorId;

    return {
      id: booking.id,
      itemId: booking.itemId,
      actorRole: isBorrower ? 'BORROWER' : 'LENDER',
      startDate: booking.startDate,
      endDate: booking.endDate,
      status: booking.status,
      expiresAt: booking.expiresAt,
      cancellationReason: booking.cancellationReason,
      terms: snapshot
        ? {
            itemTitle: snapshot.itemTitle,
            lenderDisplayName: snapshot.lenderDisplayName,
            pricePerDay: snapshot.pricePerDay,
            days: snapshot.days,
            rentalSubtotal: snapshot.rentalSubtotal,
            depositAmount: snapshot.depositAmount,
            platformFee: snapshot.platformFee,
            ownerPayout: snapshot.ownerPayout,
            total: snapshot.total,
            currency: snapshot.currency,
            paymentScenario: snapshot.paymentScenario,
            listingVersion: snapshot.listingVersion,
            offerVersion: snapshot.offerVersion,
            cancellationPolicyVersion: snapshot.cancellationPolicyVersion,
          }
        : null,
      handover: canSeeHandover && snapshot ? snapshot.handover : null,
      counterpartyContact: canSeeHandover
        ? isBorrower
          ? booking.lender.phone
          : booking.borrower.phone
        : null,
      createdAt: booking.createdAt,
    };
  }
}

function requireApprovedMarketplaceTerms(config: ConfigService): {
  offerVersion: string;
  cancellationPolicyVersion: string;
} {
  const offerVersion = config.get<string>('MARKETPLACE_OFFER_VERSION')?.trim();
  const cancellationPolicyVersion = config
    .get<string>('MARKETPLACE_CANCELLATION_POLICY_VERSION')
    ?.trim();
  if (
    !isApprovedDocumentVersion(offerVersion) ||
    !isApprovedDocumentVersion(cancellationPolicyVersion)
  ) {
    throw new ServiceUnavailableException({
      code: 'BOOKING_LEGAL_GATE_CLOSED',
      message: 'Бронирование временно недоступно',
    });
  }
  return { offerVersion, cancellationPolicyVersion };
}

function isApprovedDocumentVersion(
  version: string | undefined,
): version is string {
  return (
    version !== undefined &&
    /^[a-z0-9][a-z0-9._-]{0,63}$/i.test(version) &&
    !version.toLowerCase().includes('draft')
  );
}

function requireMarketplaceTermsAcceptance(
  dto: CreateBookingDto,
  terms: {
    offerVersion: string;
    cancellationPolicyVersion: string;
  },
): void {
  if (
    dto.offerAccepted !== true ||
    dto.rentalRulesAccepted !== true ||
    dto.offerVersion !== terms.offerVersion ||
    dto.cancellationPolicyVersion !== terms.cancellationPolicyVersion
  ) {
    throw new ConflictException({
      code: 'BOOKING_TERMS_ACCEPTANCE_REQUIRED',
      message: 'Подтвердите актуальные условия аренды',
    });
  }
}
