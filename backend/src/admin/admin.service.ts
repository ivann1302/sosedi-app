import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminCapability,
  BookingStatus,
  ItemCondition,
  ItemStatus,
  KycStatus,
  Prisma,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import type { AdminAuditContext } from './admin-audit-context';
import { BlockUserDto } from './dto/block-user.dto';
import { RejectItemDto } from './dto/reject-item.dto';

const ADMIN_LIST_LIMIT = 100;

const adminUserSelect = {
  id: true,
  phone: true,
  name: true,
  city: true,
  avatarUrl: true,
  role: true,
  kycStatus: true,
  isBlocked: true,
  sessionVersion: true,
  deletedAt: true,
  createdAt: true,
  updatedAt: true,
} as const satisfies Prisma.UserSelect;

const adminItemPhotoSelect = {
  id: true,
  originalUrl: true,
  thumbnailUrl: true,
  previewUrl: true,
  sortOrder: true,
  isCover: true,
  createdAt: true,
} as const;

const adminItemSelect = {
  id: true,
  ownerId: true,
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
  createdAt: true,
  updatedAt: true,
  category: {
    select: {
      id: true,
      name: true,
      slug: true,
      iconName: true,
    },
  },
  owner: {
    select: {
      id: true,
      name: true,
      isBlocked: true,
      deletedAt: true,
    },
  },
  photos: {
    orderBy: [{ isCover: 'desc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    select: adminItemPhotoSelect,
  },
} as const satisfies Prisma.ItemSelect;

type AdminUserModel = Prisma.UserGetPayload<{ select: typeof adminUserSelect }>;
type AdminItemModel = Prisma.ItemGetPayload<{ select: typeof adminItemSelect }>;
type ModerationAction = 'ITEM_APPROVED' | 'ITEM_REJECTED';

export type AdminUserResponse = {
  id: string;
  phone: string;
  name: string | null;
  city: string | null;
  avatarUrl: string | null;
  role: UserRole;
  kycStatus: KycStatus | null;
  isBlocked: boolean;
  deletedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

export type AdminItemPhotoResponse = {
  id: string;
  originalUrl: string | null;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

export type AdminItemResponse = {
  id: string;
  title: string;
  description: string;
  condition: ItemCondition;
  completeness: string;
  handoverTerms: string;
  pricePerDay: number;
  depositAmount: number | null;
  status: ItemStatus;
  rejectReason: string | null;
  publicArea: string;
  category: {
    id: string;
    name: string;
    slug: string;
    iconName: string | null;
  };
  owner: {
    id: string;
    name: string | null;
    isBlocked: boolean;
    deletedAt: Date | null;
  };
  photos: AdminItemPhotoResponse[];
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async listUsers(): Promise<AdminUserResponse[]> {
    const users = await this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      take: ADMIN_LIST_LIMIT,
      select: adminUserSelect,
    });

    return users.map((user) => this.toUserResponse(user));
  }

  async getUser(id: string): Promise<AdminUserResponse> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: adminUserSelect,
    });

    if (!user) {
      throw new NotFoundException('Пользователь не найден');
    }

    return this.toUserResponse(user);
  }

  async listPendingItems(): Promise<AdminItemResponse[]> {
    const items = await this.prisma.item.findMany({
      where: { status: ItemStatus.PENDING },
      orderBy: { createdAt: 'asc' },
      take: ADMIN_LIST_LIMIT,
      select: adminItemSelect,
    });

    return items.map((item) => this.toItemResponse(item));
  }

  async blockUser(
    adminId: string,
    userId: string,
    dto: BlockUserDto,
    context: AdminAuditContext,
  ): Promise<AdminUserResponse> {
    if (adminId === userId) {
      throw new ConflictException('Администратор не может заблокировать себя');
    }

    const user = await this.prisma.$transaction(async (tx) => {
      const unfinishedBooking = await tx.booking.findFirst({
        where: {
          OR: [{ borrowerId: userId }, { lenderId: userId }],
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
      if (unfinishedBooking) {
        throw new ConflictException({
          code: 'USER_HAS_UNFINISHED_BOOKINGS',
          message:
            'Сначала завершите или передайте в support незавершённые бронирования',
        });
      }

      const result = await tx.user.updateMany({
        where: {
          id: userId,
          isBlocked: false,
          deletedAt: null,
        },
        data: {
          isBlocked: true,
          sessionVersion: { increment: 1 },
        },
      });

      const updatedUser = await tx.user.findUnique({
        where: { id: userId },
        select: adminUserSelect,
      });
      if (!updatedUser || updatedUser.deletedAt) {
        throw new NotFoundException('Пользователь не найден');
      }
      if (result.count !== 1) {
        throw new ConflictException('Пользователь уже заблокирован');
      }

      await tx.adminAuditLog.create({
        data: {
          adminId,
          action: 'USER_BLOCKED',
          entityType: 'User',
          entityId: userId,
          capability: AdminCapability.MODERATION,
          reason: dto.reason,
          requestId: context.requestId,
          ipAddress: context.ipAddress,
          deviceId: context.deviceId,
          before: {
            isBlocked: false,
            sessionVersion: updatedUser.sessionVersion - 1,
          },
          after: {
            isBlocked: true,
            sessionVersion: updatedUser.sessionVersion,
          },
        },
      });

      return updatedUser;
    });

    return this.toUserResponse(user);
  }

  async approveItem(
    adminId: string,
    itemId: string,
    context: AdminAuditContext,
  ): Promise<AdminItemResponse> {
    const item = await this.prisma.$transaction(async (tx) => {
      const currentItem = await this.findModeratableItem(tx, itemId);
      const updatedItem = await tx.item.update({
        where: { id: itemId },
        data: {
          status: ItemStatus.APPROVED,
          rejectReason: null,
        },
        select: adminItemSelect,
      });

      await this.logItemModeration(tx, {
        adminId,
        action: 'ITEM_APPROVED',
        itemId,
        previousStatus: currentItem.status,
        context,
      });
      await this.enqueueItemModeration(tx, updatedItem, 'ITEM_APPROVED');

      return updatedItem;
    });

    return this.toItemResponse(item);
  }

  async rejectItem(
    adminId: string,
    itemId: string,
    dto: RejectItemDto,
    context: AdminAuditContext,
  ): Promise<AdminItemResponse> {
    const item = await this.prisma.$transaction(async (tx) => {
      const currentItem = await this.findModeratableItem(tx, itemId);
      const updatedItem = await tx.item.update({
        where: { id: itemId },
        data: {
          status: ItemStatus.REJECTED,
          rejectReason: dto.reason,
        },
        select: adminItemSelect,
      });

      await this.logItemModeration(tx, {
        adminId,
        action: 'ITEM_REJECTED',
        itemId,
        previousStatus: currentItem.status,
        rejectReason: dto.reason,
        context,
      });
      await this.enqueueItemModeration(tx, updatedItem, 'ITEM_REJECTED');

      return updatedItem;
    });

    return this.toItemResponse(item);
  }

  private async findModeratableItem(
    tx: Prisma.TransactionClient,
    itemId: string,
  ): Promise<{ id: string; status: ItemStatus }> {
    const item = await tx.item.findUnique({
      where: { id: itemId },
      select: {
        id: true,
        status: true,
      },
    });

    if (!item) {
      throw new NotFoundException('Объявление не найдено');
    }

    if (item.status !== ItemStatus.PENDING) {
      throw new ConflictException(
        'Модерировать можно только объявление в статусе PENDING',
      );
    }

    return item;
  }

  private async logItemModeration(
    tx: Prisma.TransactionClient,
    params: {
      adminId: string;
      action: ModerationAction;
      itemId: string;
      previousStatus: ItemStatus;
      rejectReason?: string;
      context: AdminAuditContext;
    },
  ): Promise<void> {
    // Аудит нужен для разбора спорных решений модерации и требований РФ.
    await tx.adminAuditLog.create({
      data: {
        adminId: params.adminId,
        action: params.action,
        entityType: 'Item',
        entityId: params.itemId,
        capability: AdminCapability.MODERATION,
        reason: params.rejectReason ?? null,
        requestId: params.context.requestId,
        ipAddress: params.context.ipAddress,
        deviceId: params.context.deviceId,
        before: {
          status: params.previousStatus,
        },
        after: {
          status:
            params.action === 'ITEM_APPROVED'
              ? ItemStatus.APPROVED
              : ItemStatus.REJECTED,
          rejectReason: params.rejectReason ?? null,
        },
      },
    });
  }

  private async enqueueItemModeration(
    tx: Prisma.TransactionClient,
    item: AdminItemModel,
    eventType: ModerationAction,
  ): Promise<void> {
    await tx.notificationOutboxEvent.create({
      data: {
        recipientId: item.ownerId,
        itemId: item.id,
        eventType,
        deduplicationKey: [
          'item',
          item.id,
          eventType,
          item.updatedAt.toISOString(),
        ].join(':'),
      },
    });
  }

  private toUserResponse(user: AdminUserModel): AdminUserResponse {
    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      city: user.city,
      avatarUrl: user.avatarUrl,
      role: user.role,
      kycStatus: user.kycStatus,
      isBlocked: user.isBlocked,
      deletedAt: user.deletedAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private toItemResponse(item: AdminItemModel): AdminItemResponse {
    return {
      id: item.id,
      title: item.title,
      description: item.description,
      condition: item.condition,
      completeness: item.completeness,
      handoverTerms: item.handoverTerms,
      pricePerDay: this.decimalToNumber(item.pricePerDay),
      depositAmount: this.nullableDecimalToNumber(item.depositAmount),
      status: item.status,
      rejectReason: item.rejectReason,
      publicArea: item.publicArea,
      category: item.category,
      owner: {
        id: item.owner.id,
        name: item.owner.name,
        isBlocked: item.owner.isBlocked,
        deletedAt: item.owner.deletedAt,
      },
      photos: item.photos,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  private decimalToNumber(value: Prisma.Decimal): number {
    return Number(value.toString());
  }

  private nullableDecimalToNumber(value: Prisma.Decimal | null): number | null {
    return value === null ? null : this.decimalToNumber(value);
  }
}
