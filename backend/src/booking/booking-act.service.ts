import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingActStage, BookingStatus, Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { BookingEventType, bookingEventKey } from './booking-events';
import { BookingActResponseDto } from './dto/booking-act-response.dto';
import { CreateBookingActDto } from './dto/create-booking-act.dto';

const actInclude = {
  evidence: {
    select: { id: true, sha256: true, createdAt: true },
    orderBy: { createdAt: 'asc' as const },
  },
} satisfies Prisma.BookingActInclude;

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
    return this.prisma.bookingAct.findMany({
      where: { bookingId },
      include: actInclude,
      orderBy: { createdAt: 'asc' },
    });
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
      return replay;
    }

    const verified = await this.upload.verifyBookingEvidenceIntent(
      actorId,
      bookingId,
      dto.intentId,
    );
    try {
      return await this.prisma.$transaction(
        async (tx) => {
          await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
          const booking = await tx.booking.findFirst({
            where: {
              id: bookingId,
              OR: [{ borrowerId: actorId }, { lenderId: actorId }],
            },
            select: { id: true, status: true },
          });
          if (!booking) {
            throw new NotFoundException('Бронирование не найдено');
          }
          this.ensureStageState(dto.stage, booking.status);

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

          return tx.bookingAct.create({
            data: {
              bookingId,
              authorId: actorId,
              stage: dto.stage,
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
      );
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
            booking: { select: { status: true } },
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
            return act;
          }
          throw new ConflictException('Акт уже подтверждён');
        }
        this.ensureStageState(act.stage, act.booking.status);

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
        await tx.booking.update({
          where: { id: bookingId },
          data: { status: nextStatus },
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
        return confirmed;
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
}
