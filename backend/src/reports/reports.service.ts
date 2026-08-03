import {
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminCapability,
  BookingStatus,
  ItemStatus,
  Prisma,
  ReportReason,
  ReportStatus,
  ReportTargetType,
} from '@prisma/client';
import type { AdminAuditContext } from '../admin/admin-audit-context';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { CreateReportDto } from './dto/create-report.dto';
import { DecideReportDto, ReportDecision } from './dto/decide-report.dto';
import { ReportResponseDto } from './dto/report-response.dto';

const REPORT_RATE_LIMIT = 5;
const REPORT_RATE_WINDOW_SECONDS = 60 * 60;
const DUPLICATE_WINDOW_MS = 24 * 60 * 60 * 1000;

const INCR_WITH_EXPIRE_SCRIPT = `
local value = redis.call('INCR', KEYS[1])
if value == 1 then
  redis.call('EXPIRE', KEYS[1], ARGV[1])
end
return value
`;

const REASONS_BY_TARGET: Record<ReportTargetType, ReadonlySet<ReportReason>> = {
  ITEM: new Set([
    ReportReason.PROHIBITED_CATEGORY,
    ReportReason.MISLEADING_LISTING,
    ReportReason.UNSAFE_ITEM,
    ReportReason.SUSPECTED_FRAUD,
    ReportReason.OTHER,
  ]),
  USER: new Set([
    ReportReason.HARASSMENT,
    ReportReason.IMPERSONATION,
    ReportReason.PRIVACY_VIOLATION,
    ReportReason.SUSPECTED_FRAUD,
    ReportReason.OTHER,
  ]),
  BOOKING: new Set([
    ReportReason.NO_SHOW,
    ReportReason.UNSAFE_HANDOVER,
    ReportReason.ITEM_NOT_AS_DESCRIBED,
    ReportReason.HARASSMENT,
    ReportReason.SUSPECTED_FRAUD,
    ReportReason.OTHER,
  ]),
};

export type AdminReportResponse = {
  id: string;
  targetType: ReportTargetType;
  targetId: string;
  reason: ReportReason;
  description: string;
  status: ReportStatus;
  decision: string | null;
  reporter: { id: string; name: string | null };
  target: Record<string, string | boolean | null>;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async create(
    reporterId: string,
    dto: CreateReportDto,
  ): Promise<ReportResponseDto> {
    this.validateReason(dto);
    await this.ensureTargetAccess(reporterId, dto);
    await this.consumeRateLimit(reporterId);

    const description = dto.description.trim();
    return this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`
          SELECT pg_advisory_xact_lock(
            hashtextextended(
              ${`report:${reporterId}:${dto.targetType}:${dto.targetId}`},
              0
            )
          )
        `;
        const duplicate = await tx.userReport.findFirst({
          where: {
            reporterId,
            targetType: dto.targetType,
            targetId: dto.targetId,
            reason: dto.reason,
            createdAt: {
              gte: new Date(Date.now() - DUPLICATE_WINDOW_MS),
            },
          },
          select: { id: true },
        });
        if (duplicate) {
          throw new ConflictException(
            'Такая жалоба уже отправлена за последние 24 часа',
          );
        }

        return tx.userReport.create({
          data: {
            reporterId,
            targetType: dto.targetType,
            targetId: dto.targetId,
            reason: dto.reason,
            description,
          },
          select: REPORT_SELECT,
        });
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
    );
  }

  async listOpenForAdmin(): Promise<AdminReportResponse[]> {
    const reports = await this.prisma.userReport.findMany({
      where: { status: ReportStatus.OPEN },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: ADMIN_REPORT_SELECT,
    });
    return Promise.all(reports.map((report) => this.toAdminResponse(report)));
  }

  async decide(
    adminId: string,
    reportId: string,
    dto: DecideReportDto,
    context: AdminAuditContext,
  ): Promise<AdminReportResponse> {
    const report = await this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`
          SELECT pg_advisory_xact_lock(hashtext(${`report-decision:${reportId}`}))
        `;
        const current = await tx.userReport.findUnique({
          where: { id: reportId },
          select: ADMIN_REPORT_SELECT,
        });
        if (!current) {
          throw new NotFoundException('Жалоба не найдена');
        }
        if (current.status !== ReportStatus.OPEN) {
          throw new ConflictException('Жалоба уже рассмотрена');
        }

        await this.applyDecision(tx, current, dto);
        const nextStatus =
          dto.decision === ReportDecision.DISMISS
            ? ReportStatus.DISMISSED
            : ReportStatus.ACTIONED;
        const updated = await tx.userReport.update({
          where: { id: reportId },
          data: {
            status: nextStatus,
            decision: dto.decision,
            reviewedById: adminId,
            reviewedAt: new Date(),
          },
          select: ADMIN_REPORT_SELECT,
        });
        await tx.adminAuditLog.create({
          data: {
            adminId,
            action: 'REPORT_DECIDED',
            entityType: 'UserReport',
            entityId: reportId,
            capability: AdminCapability.MODERATION,
            reason: dto.reason.trim(),
            requestId: context.requestId,
            ipAddress: context.ipAddress,
            deviceId: context.deviceId,
            before: {
              status: current.status,
              targetType: current.targetType,
              targetId: current.targetId,
            },
            after: { status: nextStatus, decision: dto.decision },
          },
        });
        if (dto.decision === ReportDecision.HIDE_LISTING) {
          const item = await tx.item.findUniqueOrThrow({
            where: { id: current.targetId },
            select: { id: true, ownerId: true },
          });
          await tx.notificationOutboxEvent.create({
            data: {
              recipientId: item.ownerId,
              itemId: item.id,
              eventType: 'ITEM_HIDDEN_BY_REPORT_REVIEW',
              deduplicationKey: `report:${reportId}:item-hidden`,
            },
          });
        }
        return updated;
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
    );
    return this.toAdminResponse(report);
  }

  private validateReason(dto: CreateReportDto): void {
    if (!REASONS_BY_TARGET[dto.targetType].has(dto.reason)) {
      throw new BadRequestException(
        'Причина не подходит для выбранного типа жалобы',
      );
    }
    if (
      dto.reason === ReportReason.OTHER &&
      dto.description.trim().length < 50
    ) {
      throw new BadRequestException(
        'Для причины OTHER нужно описание не короче 50 символов',
      );
    }
  }

  private async ensureTargetAccess(
    reporterId: string,
    dto: CreateReportDto,
  ): Promise<void> {
    let target: { id: string } | null;
    if (dto.targetType === ReportTargetType.ITEM) {
      target = await this.prisma.item.findFirst({
        where: { id: dto.targetId, ownerId: { not: reporterId } },
        select: { id: true },
      });
    } else if (dto.targetType === ReportTargetType.USER) {
      target = await this.prisma.user.findFirst({
        where: {
          id: dto.targetId,
          NOT: { id: reporterId },
          deletedAt: null,
        },
        select: { id: true },
      });
    } else {
      target = await this.prisma.booking.findFirst({
        where: {
          id: dto.targetId,
          OR: [{ borrowerId: reporterId }, { lenderId: reporterId }],
        },
        select: { id: true },
      });
    }
    if (!target) {
      throw new NotFoundException('Объект жалобы не найден');
    }
  }

  private async consumeRateLimit(reporterId: string): Promise<void> {
    const count = Number(
      await this.redis
        .getClient()
        .eval(
          INCR_WITH_EXPIRE_SCRIPT,
          1,
          `report:rate:${reporterId}`,
          REPORT_RATE_WINDOW_SECONDS.toString(),
        ),
    );
    if (count > REPORT_RATE_LIMIT) {
      throw new HttpException(
        'Слишком много жалоб. Попробуйте позже',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async applyDecision(
    tx: Prisma.TransactionClient,
    report: {
      targetType: ReportTargetType;
      targetId: string;
    },
    dto: DecideReportDto,
  ): Promise<void> {
    if (dto.decision === ReportDecision.DISMISS) {
      return;
    }
    if (dto.decision === ReportDecision.HIDE_LISTING) {
      if (report.targetType !== ReportTargetType.ITEM) {
        throw new BadRequestException(
          'HIDE_LISTING применим только к объявлению',
        );
      }
      const updated = await tx.item.updateMany({
        where: { id: report.targetId },
        data: { status: ItemStatus.HIDDEN },
      });
      if (updated.count !== 1) {
        throw new NotFoundException('Объявление не найдено');
      }
      return;
    }
    if (report.targetType !== ReportTargetType.USER) {
      throw new BadRequestException(
        'BLOCK_USER применим только к жалобе на пользователя',
      );
    }
    const activeBooking = await tx.booking.findFirst({
      where: {
        OR: [{ borrowerId: report.targetId }, { lenderId: report.targetId }],
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
    });
    if (activeBooking) {
      throw new ConflictException(
        'Сначала завершите или передайте в support незавершённые бронирования',
      );
    }
    const updated = await tx.user.updateMany({
      where: {
        id: report.targetId,
        isBlocked: false,
        deletedAt: null,
      },
      data: {
        isBlocked: true,
        sessionVersion: { increment: 1 },
      },
    });
    if (updated.count !== 1) {
      throw new ConflictException('Пользователь уже недоступен');
    }
  }

  private async toAdminResponse(
    report: Prisma.UserReportGetPayload<{
      select: typeof ADMIN_REPORT_SELECT;
    }>,
  ): Promise<AdminReportResponse> {
    return {
      ...report,
      target: await this.loadTargetContext(report.targetType, report.targetId),
    };
  }

  private async loadTargetContext(
    targetType: ReportTargetType,
    targetId: string,
  ): Promise<Record<string, string | boolean | null>> {
    if (targetType === ReportTargetType.ITEM) {
      const item = await this.prisma.item.findUnique({
        where: { id: targetId },
        select: {
          id: true,
          title: true,
          status: true,
          owner: { select: { id: true, name: true } },
        },
      });
      return item
        ? {
            id: item.id,
            title: item.title,
            status: item.status,
            ownerId: item.owner.id,
            ownerName: item.owner.name,
          }
        : { id: targetId, unavailable: true };
    }
    if (targetType === ReportTargetType.USER) {
      const user = await this.prisma.user.findUnique({
        where: { id: targetId },
        select: { id: true, name: true, isBlocked: true },
      });
      return user
        ? { id: user.id, name: user.name, isBlocked: user.isBlocked }
        : { id: targetId, unavailable: true };
    }
    const booking = await this.prisma.booking.findUnique({
      where: { id: targetId },
      select: { id: true, status: true, item: { select: { title: true } } },
    });
    return booking
      ? {
          id: booking.id,
          status: booking.status,
          itemTitle: booking.item.title,
        }
      : { id: targetId, unavailable: true };
  }
}

const REPORT_SELECT = {
  id: true,
  targetType: true,
  targetId: true,
  reason: true,
  description: true,
  status: true,
  createdAt: true,
} as const satisfies Prisma.UserReportSelect;

const ADMIN_REPORT_SELECT = {
  id: true,
  targetType: true,
  targetId: true,
  reason: true,
  description: true,
  status: true,
  decision: true,
  createdAt: true,
  updatedAt: true,
  reporter: {
    select: {
      id: true,
      name: true,
    },
  },
} as const satisfies Prisma.UserReportSelect;
