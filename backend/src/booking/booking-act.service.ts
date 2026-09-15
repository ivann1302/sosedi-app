import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingActStage,
  BookingMessageAuthorRole,
  BookingStatus,
  DepositStatus,
  PaymentStatus,
  Prisma,
} from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { completeBookingAfterReturnInTransaction } from '../payments/deposit.service';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { BookingEventType, bookingEventKey } from './booking-events';
import { readBoundBookingTermsSnapshot } from './booking-terms';
import {
  BookingActResponseDto,
  BookingReadinessResponseDto,
} from './dto/booking-act-response.dto';
import { CreateBookingActDto } from './dto/create-booking-act.dto';

const actInclude = {
  evidence: {
    select: { id: true, sha256: true, createdAt: true },
    orderBy: { createdAt: 'asc' as const },
  },
} satisfies Prisma.BookingActInclude;

type BookingActRecord = Prisma.BookingActGetPayload<{
  include: typeof actInclude;
}>;

@Injectable()
export class BookingActService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly upload: UploadService,
  ) {}

  async list(
    actorId: string,
    bookingId: string,
  ): Promise<BookingActResponseDto[]> {
    await this.requireParticipant(actorId, bookingId);
    const acts = await this.prisma.bookingAct.findMany({
      where: { bookingId },
      include: actInclude,
      orderBy: { createdAt: 'asc' },
    });
    return acts.map((act) => this.toResponse(act));
  }

  async create(
    actorId: string,
    bookingId: string,
    dto: CreateBookingActDto,
  ): Promise<BookingActResponseDto> {
    const replay = await this.prisma.bookingAct.findFirst({
      where: {
        bookingId,
        authorId: actorId,
        stage: dto.stage,
        evidence: { some: { uploadIntentId: dto.intentId } },
      },
      include: actInclude,
    });
    if (replay) {
      return this.toResponse(replay);
    }

    this.ensureReadiness(dto);

    const verified = await this.upload.verifyBookingEvidenceIntent(
      actorId,
      bookingId,
      dto.intentId,
    );
    try {
      return await this.prisma
        .$transaction(
          async (tx) => {
            await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
            const booking = await tx.booking.findFirst({
              where: {
                id: bookingId,
                OR: [{ borrowerId: actorId }, { lenderId: actorId }],
              },
              select: {
                id: true,
                status: true,
                borrowerId: true,
                lenderId: true,
              },
            });
            if (!booking) {
              throw new NotFoundException('Бронирование не найдено');
            }
            this.ensureStageState(dto.stage, booking.status);
            this.ensureStageActor(dto.stage, actorId, booking);

            const consumed = await tx.uploadIntent.updateMany({
              where: {
                id: verified.intentId,
                actorId,
                entityId: bookingId,
                confirmedAt: null,
                expiresAt: { gt: new Date() },
              },
              data: { confirmedAt: new Date() },
            });
            if (consumed.count !== 1) {
              throw new ConflictException('Upload intent уже использован');
            }

            const declaredAt = new Date();
            return tx.bookingAct.create({
              data: {
                bookingId,
                authorId: actorId,
                stage: dto.stage,
                readinessIsWorking: dto.readiness?.isWorking,
                readinessIsComplete: dto.readiness?.isComplete,
                readinessVisibleDefects:
                  dto.readiness?.visibleDefects.trim() ?? undefined,
                readinessDeclaredAt:
                  dto.stage === BookingActStage.HANDOVER
                    ? declaredAt
                    : undefined,
                evidence: {
                  create: {
                    uploadIntentId: verified.intentId,
                    storageKey: verified.objectKey,
                    sha256: verified.sha256,
                  },
                },
              },
              include: actInclude,
            });
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted },
        )
        .then((act) => this.toResponse(act));
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Акт этого этапа уже создан');
      }
      throw error;
    }
  }

  async confirm(
    actorId: string,
    bookingId: string,
    actId: string,
    requestId: string = randomUUID(),
  ): Promise<BookingActResponseDto> {
    return this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
        const act = await tx.bookingAct.findFirst({
          where: {
            id: actId,
            bookingId,
            booking: {
              OR: [{ borrowerId: actorId }, { lenderId: actorId }],
            },
          },
          include: {
            ...actInclude,
            booking: {
              select: {
                status: true,
                borrowerId: true,
                lenderId: true,
                startDate: true,
                endDate: true,
                totalAmount: true,
                termsSnapshot: true,
                payment: { select: { status: true } },
                deposit: { select: { id: true, status: true } },
              },
            },
          },
        });
        if (!act) {
          throw new NotFoundException('Акт не найден');
        }
        if (act.authorId === actorId) {
          throw new ConflictException(
            'Автор не может подтвердить собственный акт',
          );
        }
        if (act.confirmedAt) {
          if (act.confirmedById === actorId) {
            return this.toResponse(act);
          }
          throw new ConflictException('Акт уже подтверждён');
        }
        this.ensureStageState(act.stage, act.booking.status);

        const days =
          Math.floor(
            (act.booking.endDate.getTime() - act.booking.startDate.getTime()) /
              86_400_000,
          ) + 1;
        const snapshot = readBoundBookingTermsSnapshot(
          act.booking.termsSnapshot,
          {
            borrowerId: act.booking.borrowerId,
            lenderId: act.booking.lenderId,
            days,
            totalAmount: act.booking.totalAmount.toNumber(),
          },
        );
        if (act.booking.termsSnapshot !== null && !snapshot) {
          throw new ConflictException('Условия бронирования недействительны');
        }
        if (
          act.stage === BookingActStage.HANDOVER &&
          snapshot?.paymentScenario === 'FAKE_SAFE_DEAL'
        ) {
          if (act.booking.payment?.status !== PaymentStatus.SUCCEEDED) {
            throw new ConflictException(
              'Передача недоступна до успешной оплаты',
            );
          }
          if (
            snapshot.moneyMinor.deposit > 0 &&
            act.booking.deposit?.status !== DepositStatus.HELD
          ) {
            throw new ConflictException(
              'Передача недоступна до удержания залога',
            );
          }
        }

        const nextStatus =
          act.stage === BookingActStage.HANDOVER
            ? BookingStatus.ACTIVE
            : BookingStatus.RETURNED;
        const eventType =
          act.stage === BookingActStage.HANDOVER
            ? BookingEventType.HANDOVER_CONFIRMED
            : BookingEventType.RETURN_CONFIRMED;
        const confirmedAt = new Date();
        const confirmed = await tx.bookingAct.update({
          where: { id: act.id },
          data: { confirmedById: actorId, confirmedAt },
          include: actInclude,
        });
        if (
          act.stage === BookingActStage.RETURN &&
          snapshot?.paymentScenario === 'FAKE_SAFE_DEAL' &&
          snapshot.depositTerms &&
          act.booking.deposit
        ) {
          await tx.bookingDeposit.update({
            where: { id: act.booking.deposit.id },
            data: {
              disputeWindowEndsAt: new Date(
                confirmedAt.getTime() +
                  snapshot.depositTerms.disputeWindowSeconds * 1000,
              ),
            },
          });
        }
        await tx.booking.update({
          where: { id: bookingId },
          data: { status: nextStatus },
        });
        await tx.bookingMessage.create({
          data: {
            bookingId,
            authorRole: BookingMessageAuthorRole.SYSTEM,
            body:
              nextStatus === BookingStatus.ACTIVE
                ? 'Передача подтверждена обеими сторонами. Аренда началась.'
                : 'Возврат подтверждён обеими сторонами.',
          },
        });
        await tx.bookingTransitionHistory.create({
          data: {
            bookingId,
            actorId,
            actorType:
              act.stage === BookingActStage.HANDOVER
                ? 'HANDOVER_CONFIRMER'
                : 'RETURN_CONFIRMER',
            command:
              act.stage === BookingActStage.HANDOVER
                ? 'CONFIRM_HANDOVER'
                : 'CONFIRM_RETURN',
            oldStatus: act.booking.status,
            newStatus: nextStatus,
            requestId,
          },
        });
        await tx.notificationOutboxEvent.create({
          data: {
            bookingId,
            eventType,
            deduplicationKey: bookingEventKey(bookingId, eventType),
          },
        });
        if (
          act.stage === BookingActStage.RETURN &&
          snapshot?.moneyMinor.deposit === 0
        ) {
          await completeBookingAfterReturnInTransaction(
            tx,
            bookingId,
            confirmedAt,
            'ZERO_DEPOSIT_RETURN',
          );
        }
        return this.toResponse(confirmed);
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted },
    );
  }

  async getEvidenceDownload(
    actorId: string,
    bookingId: string,
    evidenceId: string,
  ) {
    return this.upload.getBookingEvidenceDownloadUrl(
      actorId,
      bookingId,
      evidenceId,
    );
  }

  private async requireParticipant(
    actorId: string,
    bookingId: string,
  ): Promise<void> {
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
  }

  private ensureStageState(
    stage: BookingActStage,
    status: BookingStatus,
  ): void {
    const expected =
      stage === BookingActStage.HANDOVER
        ? BookingStatus.CONFIRMED
        : BookingStatus.ACTIVE;
    if (status !== expected) {
      throw new ConflictException({
        code: 'INVALID_BOOKING_TRANSITION',
        message: 'Акт недоступен в текущем состоянии бронирования',
      });
    }
  }

  private ensureReadiness(dto: CreateBookingActDto): void {
    if (dto.stage === BookingActStage.HANDOVER && !dto.readiness) {
      throw new BadRequestException(
        'Перед передачей владелец должен заполнить чек-лист',
      );
    }
    if (dto.stage === BookingActStage.RETURN && dto.readiness) {
      throw new BadRequestException(
        'Чек-лист готовности доступен только для передачи',
      );
    }
  }

  private ensureStageActor(
    stage: BookingActStage,
    actorId: string,
    booking: { borrowerId: string; lenderId: string },
  ): void {
    const expectedActorId =
      stage === BookingActStage.HANDOVER
        ? booking.lenderId
        : booking.borrowerId;
    if (actorId !== expectedActorId) {
      throw new ForbiddenException(
        stage === BookingActStage.HANDOVER
          ? 'Акт передачи создаёт владелец'
          : 'Акт возврата создаёт арендатор',
      );
    }
  }

  private toResponse(act: BookingActRecord): BookingActResponseDto {
    let readiness: BookingReadinessResponseDto | null = null;
    if (
      act.readinessIsWorking != null &&
      act.readinessIsComplete != null &&
      act.readinessVisibleDefects != null &&
      act.readinessDeclaredAt != null
    ) {
      readiness = {
        isWorking: act.readinessIsWorking,
        isComplete: act.readinessIsComplete,
        visibleDefects: act.readinessVisibleDefects,
        declaredAt: act.readinessDeclaredAt,
        declaration: 'LENDER_SELF_DECLARATION',
      };
    }
    return {
      id: act.id,
      bookingId: act.bookingId,
      authorId: act.authorId,
      stage: act.stage,
      createdAt: act.createdAt,
      confirmedById: act.confirmedById,
      confirmedAt: act.confirmedAt,
      evidence: act.evidence,
      readiness,
    };
  }
}
