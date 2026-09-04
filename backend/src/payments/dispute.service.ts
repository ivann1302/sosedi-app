import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, DepositStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { UploadPurpose } from '../upload/upload.types';
import { AddDisputeEvidenceDto } from './dto/add-dispute-evidence.dto';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import {
  DisputeEvidenceResponseDto,
  DisputeResponseDto,
} from './dto/dispute-response.dto';

const disputeInclude = {
  evidence: { orderBy: { createdAt: 'asc' as const } },
};

type DisputeWithEvidence = Prisma.FinancialDisputeGetPayload<{
  include: typeof disputeInclude;
}>;

@Injectable()
export class DisputeService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly upload: UploadService,
  ) {}

  openDispute(
    actorId: string,
    bookingId: string,
    dto: CreateDisputeDto,
    now = new Date(),
  ): Promise<DisputeResponseDto> {
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${bookingId}))`;
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: {
          deposit: true,
          financialDispute: { select: { id: true } },
        },
      });
      if (
        !booking ||
        (booking.borrowerId !== actorId && booking.lenderId !== actorId)
      ) {
        throw new NotFoundException('Бронирование не найдено');
      }
      if (
        booking.status !== BookingStatus.RETURNED ||
        !booking.deposit ||
        booking.deposit.status !== DepositStatus.HELD ||
        !booking.deposit.disputeWindowEndsAt ||
        booking.deposit.disputeWindowEndsAt <= now ||
        booking.financialDispute
      ) {
        throw new ConflictException('Спор нельзя открыть в текущем состоянии');
      }

      const dispute = await tx.financialDispute.create({
        data: {
          bookingId,
          openedById: actorId,
          reason: dto.reason,
          description: dto.description || null,
          openedAt: now,
        },
        include: disputeInclude,
      });
      await tx.bookingDeposit.update({
        where: { id: booking.deposit.id },
        data: { status: DepositStatus.DISPUTED },
      });
      return this.toDisputeResponse(dispute);
    });
  }

  async getDispute(
    actorId: string,
    bookingId: string,
  ): Promise<DisputeResponseDto> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        OR: [{ borrowerId: actorId }, { lenderId: actorId }],
      },
      select: {
        financialDispute: { include: disputeInclude },
      },
    });
    if (!booking?.financialDispute) {
      throw new NotFoundException('Спор не найден');
    }
    return this.toDisputeResponse(booking.financialDispute);
  }

  async addEvidence(
    actorId: string,
    bookingId: string,
    disputeId: string,
    dto: AddDisputeEvidenceDto,
    now = new Date(),
  ): Promise<DisputeEvidenceResponseDto> {
    const verified = await this.upload.verifyDisputeEvidenceIntent(
      actorId,
      disputeId,
      dto.intentId,
    );

    return this.prisma.$transaction(async (tx) => {
      const dispute = await tx.financialDispute.findFirst({
        where: {
          id: disputeId,
          bookingId,
          booking: {
            OR: [{ borrowerId: actorId }, { lenderId: actorId }],
          },
        },
        select: { id: true },
      });
      if (!dispute) {
        throw new NotFoundException('Спор не найден');
      }

      const consumed = await tx.uploadIntent.updateMany({
        where: {
          id: verified.intentId,
          actorId,
          entityId: disputeId,
          purpose: UploadPurpose.DISPUTE_EVIDENCE,
          confirmedAt: null,
          expiresAt: { gt: now },
        },
        data: { confirmedAt: now },
      });
      if (consumed.count !== 1) {
        throw new ConflictException('Upload intent уже использован или истёк');
      }

      const evidence = await tx.disputeEvidence.create({
        data: {
          disputeId,
          uploadIntentId: verified.intentId,
          storageKey: verified.objectKey,
          sha256: verified.sha256,
        },
        select: { id: true, sha256: true, createdAt: true },
      });
      return {
        id: evidence.id,
        sha256: evidence.sha256,
        createdAt: evidence.createdAt,
      };
    });
  }

  getEvidenceDownloadUrl(
    actorId: string,
    bookingId: string,
    disputeId: string,
    evidenceId: string,
  ) {
    return this.upload.getDisputeEvidenceDownloadUrl(
      actorId,
      bookingId,
      disputeId,
      evidenceId,
    );
  }

  private toDisputeResponse(dispute: DisputeWithEvidence): DisputeResponseDto {
    return {
      id: dispute.id,
      bookingId: dispute.bookingId,
      openedById: dispute.openedById,
      reason: dispute.reason,
      description: dispute.description,
      status: dispute.status,
      openedAt: dispute.openedAt,
      resolvedAt: dispute.resolvedAt,
      evidence: dispute.evidence.map(({ id, sha256, createdAt }) => ({
        id,
        sha256,
        createdAt,
      })),
    };
  }
}
