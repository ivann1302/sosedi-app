import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { KycStatus, Prisma, ToolStatus, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RejectToolDto } from './dto/reject-tool.dto';

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
  deletedAt: true,
  createdAt: true,
  updatedAt: true,
} as const satisfies Prisma.UserSelect;

const adminToolPhotoSelect = {
  id: true,
  originalUrl: true,
  thumbnailUrl: true,
  previewUrl: true,
  sortOrder: true,
  isCover: true,
  createdAt: true,
} as const;

const adminToolSelect = {
  id: true,
  ownerId: true,
  title: true,
  description: true,
  pricePerDay: true,
  depositAmount: true,
  status: true,
  rejectReason: true,
  address: true,
  latitude: true,
  longitude: true,
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
      phone: true,
      name: true,
      city: true,
      avatarUrl: true,
      isBlocked: true,
      deletedAt: true,
    },
  },
  photos: {
    orderBy: [{ isCover: 'desc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    select: adminToolPhotoSelect,
  },
} as const satisfies Prisma.ToolSelect;

type AdminUserModel = Prisma.UserGetPayload<{ select: typeof adminUserSelect }>;
type AdminToolModel = Prisma.ToolGetPayload<{ select: typeof adminToolSelect }>;
type ModerationAction = 'TOOL_APPROVED' | 'TOOL_REJECTED';

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

export type AdminToolPhotoResponse = {
  id: string;
  originalUrl: string;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

export type AdminToolResponse = {
  id: string;
  title: string;
  description: string;
  pricePerDay: number;
  depositAmount: number | null;
  status: ToolStatus;
  rejectReason: string | null;
  address: string;
  latitude: number;
  longitude: number;
  category: {
    id: string;
    name: string;
    slug: string;
    iconName: string | null;
  };
  owner: {
    id: string;
    phone: string;
    name: string | null;
    city: string | null;
    avatarUrl: string | null;
    isBlocked: boolean;
    deletedAt: Date | null;
  };
  photos: AdminToolPhotoResponse[];
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

  async listPendingTools(): Promise<AdminToolResponse[]> {
    const tools = await this.prisma.tool.findMany({
      where: { status: ToolStatus.PENDING },
      orderBy: { createdAt: 'asc' },
      take: ADMIN_LIST_LIMIT,
      select: adminToolSelect,
    });

    return tools.map((tool) => this.toToolResponse(tool));
  }

  async approveTool(
    adminId: string,
    toolId: string,
    ipAddress?: string,
  ): Promise<AdminToolResponse> {
    const tool = await this.prisma.$transaction(async (tx) => {
      const currentTool = await this.findModeratableTool(tx, toolId);
      const updatedTool = await tx.tool.update({
        where: { id: toolId },
        data: {
          status: ToolStatus.APPROVED,
          rejectReason: null,
        },
        select: adminToolSelect,
      });

      await this.logToolModeration(tx, {
        adminId,
        action: 'TOOL_APPROVED',
        toolId,
        previousStatus: currentTool.status,
        ipAddress,
      });

      return updatedTool;
    });

    return this.toToolResponse(tool);
  }

  async rejectTool(
    adminId: string,
    toolId: string,
    dto: RejectToolDto,
    ipAddress?: string,
  ): Promise<AdminToolResponse> {
    const tool = await this.prisma.$transaction(async (tx) => {
      const currentTool = await this.findModeratableTool(tx, toolId);
      const updatedTool = await tx.tool.update({
        where: { id: toolId },
        data: {
          status: ToolStatus.REJECTED,
          rejectReason: dto.reason,
        },
        select: adminToolSelect,
      });

      await this.logToolModeration(tx, {
        adminId,
        action: 'TOOL_REJECTED',
        toolId,
        previousStatus: currentTool.status,
        rejectReason: dto.reason,
        ipAddress,
      });

      return updatedTool;
    });

    return this.toToolResponse(tool);
  }

  private async findModeratableTool(
    tx: Prisma.TransactionClient,
    toolId: string,
  ): Promise<{ id: string; status: ToolStatus }> {
    const tool = await tx.tool.findUnique({
      where: { id: toolId },
      select: {
        id: true,
        status: true,
      },
    });

    if (!tool) {
      throw new NotFoundException('Объявление не найдено');
    }

    if (tool.status === ToolStatus.HIDDEN) {
      throw new BadRequestException(
        'Скрытое владельцем объявление нельзя модерировать',
      );
    }

    return tool;
  }

  private async logToolModeration(
    tx: Prisma.TransactionClient,
    params: {
      adminId: string;
      action: ModerationAction;
      toolId: string;
      previousStatus: ToolStatus;
      rejectReason?: string;
      ipAddress?: string;
    },
  ): Promise<void> {
    // Аудит нужен для разбора спорных решений модерации и требований РФ.
    await tx.adminAuditLog.create({
      data: {
        adminId: params.adminId,
        action: params.action,
        entityType: 'Tool',
        entityId: params.toolId,
        metadata: {
          previousStatus: params.previousStatus,
          ...(params.rejectReason ? { rejectReason: params.rejectReason } : {}),
        },
        ipAddress: params.ipAddress ?? null,
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

  private toToolResponse(tool: AdminToolModel): AdminToolResponse {
    return {
      id: tool.id,
      title: tool.title,
      description: tool.description,
      pricePerDay: this.decimalToNumber(tool.pricePerDay),
      depositAmount: this.nullableDecimalToNumber(tool.depositAmount),
      status: tool.status,
      rejectReason: tool.rejectReason,
      address: tool.address,
      latitude: tool.latitude,
      longitude: tool.longitude,
      category: tool.category,
      owner: tool.owner,
      photos: tool.photos,
      createdAt: tool.createdAt,
      updatedAt: tool.updatedAt,
    };
  }

  private decimalToNumber(value: Prisma.Decimal): number {
    return Number(value.toString());
  }

  private nullableDecimalToNumber(value: Prisma.Decimal | null): number | null {
    return value === null ? null : this.decimalToNumber(value);
  }
}
