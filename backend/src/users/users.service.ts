import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import {
  BookingMessageAuthorRole,
  BookingStatus,
  KycStatus,
  Prisma,
  SupportTicketStatus,
  SupportTicketType,
  User,
  UserRole,
} from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { BookingEventType, bookingEventKey } from '../booking/booking-events';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UserBlockResponseDto } from './dto/user-block-response.dto';

type UserProfileModel = Pick<
  User,
  | 'id'
  | 'phone'
  | 'name'
  | 'city'
  | 'avatarUrl'
  | 'role'
  | 'kycStatus'
  | 'isBlocked'
  | 'deletedAt'
  | 'createdAt'
  | 'updatedAt'
>;

export type UserProfileResponse = {
  id: string;
  phone: string;
  name: string | null;
  city: string | null;
  avatarUrl: string | null;
  role: UserRole;
  kycStatus: KycStatus | null;
  isBlocked: boolean;
  createdAt: Date;
  updatedAt: Date;
};

export type AccountClosureResponse = {
  status: 'PENDING_OBLIGATIONS' | 'ANONYMIZED';
  requestedAt: Date;
  anonymizedAt: Date | null;
};

export type UserUnblockResponse = {
  blockedUserId: string;
  blocked: false;
};

export const BOOKING_PARTICIPANT_BLOCKED_REASON = 'PARTICIPANT_BLOCKED';

@Injectable()
export class UsersService implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(UsersService.name);
  private closureFinalizerTimer: NodeJS.Timeout | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap(): Promise<void> {
    if (process.env.NODE_ENV === 'test') {
      return;
    }

    await this.runClosureFinalizer();
    this.closureFinalizerTimer = setInterval(
      () => void this.runClosureFinalizer(),
      15 * 60 * 1000,
    );
    this.closureFinalizerTimer.unref();
  }

  onModuleDestroy(): void {
    if (this.closureFinalizerTimer) {
      clearInterval(this.closureFinalizerTimer);
    }
  }

  async getMe(userId: string): Promise<UserProfileResponse> {
    const user = await this.findActiveUser(userId);
    return this.toProfileResponse(user);
  }

  async updateMe(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<UserProfileResponse> {
    const currentUser = await this.findActiveUser(userId);
    const data = this.buildProfileUpdateData(dto);

    if (Object.keys(data).length === 0) {
      return this.toProfileResponse(currentUser);
    }

    const user = await this.prisma.user.update({
      where: { id: userId },
      data,
      select: this.userProfileSelect(),
    });

    return this.toProfileResponse(user);
  }

  listBlockedUsers(userId: string): Promise<UserBlockResponseDto[]> {
    return this.prisma.userBlock.findMany({
      where: { blockerId: userId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      select: USER_BLOCK_SELECT,
    });
  }

  async blockUser(
    blockerId: string,
    blockedId: string,
  ): Promise<UserBlockResponseDto> {
    if (blockerId === blockedId) {
      throw new BadRequestException('Нельзя заблокировать себя');
    }
    const pairKey = [blockerId, blockedId].sort().join(':');
    const requestId = randomUUID();
    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`
        SELECT pg_advisory_xact_lock(
          hashtextextended(${`user-block-pair:${pairKey}`}, 0)
        )
      `;
      const target = await tx.user.findFirst({
        where: {
          id: blockedId,
          deletedAt: null,
          isBlocked: false,
        },
        select: { id: true },
      });
      if (!target) {
        throw new NotFoundException('Пользователь не найден');
      }

      const block = await tx.userBlock.upsert({
        where: {
          blockerId_blockedId: { blockerId, blockedId },
        },
        create: { blockerId, blockedId },
        update: {},
        select: USER_BLOCK_SELECT,
      });
      const now = new Date();
      const candidates = await tx.booking.findMany({
        where: {
          status: BookingStatus.PENDING,
          expiresAt: { gt: now },
          OR: [
            { borrowerId: blockerId, lenderId: blockedId },
            { borrowerId: blockedId, lenderId: blockerId },
          ],
        },
        select: { id: true },
        orderBy: { id: 'asc' },
      });
      for (const candidate of candidates) {
        await tx.$executeRaw`
          SELECT pg_advisory_xact_lock(hashtext(${candidate.id}))
        `;
      }
      const cancellable = await tx.booking.findMany({
        where: {
          id: { in: candidates.map((candidate) => candidate.id) },
          status: BookingStatus.PENDING,
          expiresAt: { gt: now },
        },
        select: { id: true },
      });
      if (cancellable.length > 0) {
        const bookingIds = cancellable.map((booking) => booking.id);
        await tx.booking.updateMany({
          where: { id: { in: bookingIds }, status: BookingStatus.PENDING },
          data: {
            status: BookingStatus.CANCELLED,
            cancellationReason: BOOKING_PARTICIPANT_BLOCKED_REASON,
            expiresAt: null,
          },
        });
        await tx.bookingMessage.createMany({
          data: bookingIds.map((bookingId) => ({
            bookingId,
            authorRole: BookingMessageAuthorRole.SYSTEM,
            body: 'Один из участников заблокировал другого. Заявка отменена.',
          })),
        });
        await tx.bookingTransitionHistory.createMany({
          data: bookingIds.map((bookingId) => ({
            bookingId,
            actorId: blockerId,
            actorType: 'PARTICIPANT',
            command: 'BLOCK_COUNTERPARTY',
            oldStatus: BookingStatus.PENDING,
            newStatus: BookingStatus.CANCELLED,
            reason: BOOKING_PARTICIPANT_BLOCKED_REASON,
            requestId,
          })),
        });
        await tx.notificationOutboxEvent.createMany({
          data: bookingIds.map((bookingId) => ({
            bookingId,
            eventType: BookingEventType.CANCELLED,
            deduplicationKey: bookingEventKey(
              bookingId,
              BookingEventType.CANCELLED,
            ),
          })),
        });
      }
      return block;
    });
  }

  async unblockUser(
    blockerId: string,
    blockedId: string,
  ): Promise<UserUnblockResponse> {
    await this.prisma.userBlock.deleteMany({
      where: { blockerId, blockedId },
    });
    return { blockedUserId: blockedId, blocked: false };
  }

  async deleteMe(userId: string): Promise<AccountClosureResponse> {
    await this.findActiveUser(userId);

    return this.prisma.$transaction(
      async (tx) => {
        const hasBlockers = await this.hasAccountDeletionBlockers(tx, userId);
        const requestedAt = new Date();
        const anonymizedAt = hasBlockers ? null : requestedAt;

        await tx.user.update({
          where: { id: userId },
          data: {
            sessionVersion: { increment: 1 },
            deletedAt: requestedAt,
            ...(anonymizedAt
              ? this.buildAnonymizationData(userId, anonymizedAt)
              : {}),
          },
        });

        return {
          status: anonymizedAt ? 'ANONYMIZED' : 'PENDING_OBLIGATIONS',
          requestedAt,
          anonymizedAt,
        };
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
    );
  }

  async finalizeEligibleAccountClosures(): Promise<number> {
    const candidates = await this.prisma.user.findMany({
      where: {
        deletedAt: { not: null },
        anonymizedAt: null,
      },
      select: { id: true },
    });
    let finalizedCount = 0;

    for (const candidate of candidates) {
      finalizedCount += await this.prisma.$transaction(
        async (tx) => {
          if (await this.hasAccountDeletionBlockers(tx, candidate.id)) {
            return 0;
          }

          const anonymizedAt = new Date();
          const result = await tx.user.updateMany({
            where: {
              id: candidate.id,
              deletedAt: { not: null },
              anonymizedAt: null,
            },
            data: this.buildAnonymizationData(candidate.id, anonymizedAt),
          });

          return result.count;
        },
        { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
      );
    }

    return finalizedCount;
  }

  private async hasAccountDeletionBlockers(
    tx: Prisma.TransactionClient,
    userId: string,
  ): Promise<boolean> {
    const participantBooking = {
      OR: [{ borrowerId: userId }, { lenderId: userId }],
    };
    const [activeBooking, openDispute, paymentRecord, kycRecord] =
      await Promise.all([
        tx.booking.findFirst({
          where: {
            ...participantBooking,
            status: {
              in: [
                BookingStatus.PENDING,
                BookingStatus.CONFIRMED,
                BookingStatus.ACTIVE,
                BookingStatus.RETURNED,
              ],
            },
          },
          select: { id: true },
        }),
        tx.supportTicket.findFirst({
          where: {
            type: SupportTicketType.DISPUTE,
            status: {
              in: [SupportTicketStatus.OPEN, SupportTicketStatus.IN_PROGRESS],
            },
            OR: [
              { userId },
              {
                booking: {
                  is: participantBooking,
                },
              },
            ],
          },
          select: { id: true },
        }),
        tx.payment.findFirst({
          where: {
            OR: [
              { userId },
              {
                booking: {
                  is: participantBooking,
                },
              },
            ],
          },
          select: { id: true },
        }),
        tx.kycDocument.findFirst({
          where: { userId },
          select: { id: true },
        }),
      ]);

    return Boolean(activeBooking || openDispute || paymentRecord || kycRecord);
  }

  private buildAnonymizationData(
    userId: string,
    anonymizedAt: Date,
  ): Prisma.UserUpdateInput {
    return {
      phone: `deleted:${userId}`,
      name: null,
      city: null,
      avatarUrl: null,
      anonymizedAt,
    };
  }

  private async runClosureFinalizer(): Promise<void> {
    try {
      await this.finalizeEligibleAccountClosures();
    } catch (error) {
      this.logger.error('Не удалось завершить anonymization аккаунтов', error);
    }
  }

  private async findActiveUser(userId: string): Promise<UserProfileModel> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: this.userProfileSelect(),
    });

    if (!user || user.deletedAt) {
      throw new NotFoundException('Пользователь не найден');
    }

    if (user.isBlocked) {
      throw new ForbiddenException('Пользователь заблокирован');
    }

    return user;
  }

  private buildProfileUpdateData(
    dto: UpdateProfileDto,
  ): Prisma.UserUpdateInput {
    const data: Prisma.UserUpdateInput = {};

    if (Object.hasOwn(dto, 'name')) {
      data.name = dto.name;
    }

    if (Object.hasOwn(dto, 'city')) {
      data.city = dto.city;
    }

    return data;
  }

  private toProfileResponse(user: UserProfileModel): UserProfileResponse {
    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      city: user.city,
      avatarUrl: user.avatarUrl,
      role: user.role,
      kycStatus: user.kycStatus,
      isBlocked: user.isBlocked,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private userProfileSelect() {
    return {
      id: true,
      phone: true,
      name: true,
      city: true,
      avatarUrl: true,
      role: true,
      kycStatus: true,
      isBlocked: true,
      deletedAt: true,
      createdAt: true,
      updatedAt: true,
    } as const;
  }
}

const USER_BLOCK_SELECT = {
  id: true,
  blocked: {
    select: {
      id: true,
      name: true,
    },
  },
  createdAt: true,
} as const satisfies Prisma.UserBlockSelect;
