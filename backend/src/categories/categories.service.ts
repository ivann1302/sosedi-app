import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AdminCapability,
  Category,
  CategoryListingPolicy,
  Prisma,
} from '@prisma/client';
import type { AdminAuditContext } from '../admin/admin-audit-context';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

type CategoryModel = Pick<
  Category,
  | 'id'
  | 'name'
  | 'slug'
  | 'iconName'
  | 'sortOrder'
  | 'isActive'
  | 'isAllowedForListings'
  | 'listingPolicy'
  | 'safetyNotice'
  | 'createdAt'
  | 'updatedAt'
>;

export type CategoryResponse = {
  id: string;
  name: string;
  slug: string;
  iconName: string | null;
  sortOrder: number;
  isActive: boolean;
  isAllowedForListings: boolean;
  listingPolicy: CategoryListingPolicy;
  safetyNotice: string;
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async listActive(): Promise<CategoryResponse[]> {
    const categories = await this.prisma.category.findMany({
      where: {
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      select: this.categorySelect(),
    });

    return categories.map((category) => this.toCategoryResponse(category));
  }

  async getBySlug(slug: string): Promise<CategoryResponse> {
    const category = await this.prisma.category.findFirst({
      where: {
        slug,
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
      select: this.categorySelect(),
    });

    if (!category) {
      throw new NotFoundException('Категория не найдена');
    }

    return this.toCategoryResponse(category);
  }

  async create(
    adminId: string,
    dto: CreateCategoryDto,
    context: AdminAuditContext,
  ): Promise<CategoryResponse> {
    try {
      const category = await this.prisma.$transaction(async (tx) => {
        const created = await tx.category.create({
          data: {
            name: dto.name,
            slug: dto.slug,
            iconName: dto.iconName ?? null,
            sortOrder: dto.sortOrder ?? 0,
            isActive: dto.isActive ?? true,
            isAllowedForListings: false,
            listingPolicy: CategoryListingPolicy.RESTRICTED,
            safetyNotice:
              'Категория требует отдельной проверки перед публикацией.',
          },
          select: this.categorySelect(),
        });
        await this.writeAudit(tx, {
          adminId,
          action: 'CATEGORY_CREATED',
          categoryId: created.id,
          context,
          before: { exists: false },
          after: this.auditSnapshot(created),
        });
        return created;
      });

      return this.toCategoryResponse(category);
    } catch (error) {
      this.throwKnownPrismaError(error);
      throw error;
    }
  }

  async update(
    adminId: string,
    id: string,
    dto: UpdateCategoryDto,
    context: AdminAuditContext,
  ): Promise<CategoryResponse> {
    const data = this.buildUpdateData(dto);

    try {
      const category = await this.prisma.$transaction(async (tx) => {
        const current = await this.findById(id, tx);
        if (Object.keys(data).length === 0) {
          return current;
        }

        const updated = await tx.category.update({
          where: { id },
          data,
          select: this.categorySelect(),
        });
        await this.writeAudit(tx, {
          adminId,
          action: 'CATEGORY_UPDATED',
          categoryId: id,
          context,
          before: this.auditSnapshot(current),
          after: this.auditSnapshot(updated),
        });
        return updated;
      });

      return this.toCategoryResponse(category);
    } catch (error) {
      this.throwKnownPrismaError(error);
      throw error;
    }
  }

  async disable(
    adminId: string,
    id: string,
    context: AdminAuditContext,
  ): Promise<CategoryResponse> {
    const category = await this.prisma.$transaction(async (tx) => {
      const current = await this.findById(id, tx);
      const updated = await tx.category.update({
        where: { id },
        data: { isActive: false },
        select: this.categorySelect(),
      });
      await this.writeAudit(tx, {
        adminId,
        action: 'CATEGORY_DISABLED',
        categoryId: id,
        context,
        before: { isActive: current.isActive },
        after: { isActive: updated.isActive },
      });
      return updated;
    });

    return this.toCategoryResponse(category);
  }

  private async findById(
    id: string,
    client: Prisma.TransactionClient | PrismaService = this.prisma,
  ): Promise<CategoryModel> {
    const category = await client.category.findUnique({
      where: { id },
      select: this.categorySelect(),
    });

    if (!category) {
      throw new NotFoundException('Категория не найдена');
    }

    return category;
  }

  private writeAudit(
    tx: Prisma.TransactionClient,
    input: {
      adminId: string;
      action: string;
      categoryId: string;
      context: AdminAuditContext;
      before: Prisma.InputJsonObject;
      after: Prisma.InputJsonObject;
    },
  ) {
    return tx.adminAuditLog.create({
      data: {
        adminId: input.adminId,
        action: input.action,
        entityType: 'Category',
        entityId: input.categoryId,
        capability: AdminCapability.MODERATION,
        requestId: input.context.requestId,
        ipAddress: input.context.ipAddress,
        deviceId: input.context.deviceId,
        before: input.before,
        after: input.after,
      },
    });
  }

  private auditSnapshot(category: CategoryModel): Prisma.InputJsonObject {
    return {
      name: category.name,
      slug: category.slug,
      iconName: category.iconName,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      isAllowedForListings: category.isAllowedForListings,
      listingPolicy: category.listingPolicy,
    };
  }

  private buildUpdateData(dto: UpdateCategoryDto): Prisma.CategoryUpdateInput {
    this.rejectNullRequiredUpdateFields(dto as Record<string, unknown>);

    const data: Prisma.CategoryUpdateInput = {};

    if (Object.hasOwn(dto, 'name')) {
      data.name = dto.name;
    }

    if (Object.hasOwn(dto, 'slug')) {
      data.slug = dto.slug;
    }

    if (Object.hasOwn(dto, 'iconName')) {
      data.iconName = dto.iconName ?? null;
    }

    if (Object.hasOwn(dto, 'sortOrder')) {
      data.sortOrder = dto.sortOrder;
    }

    return data;
  }

  private rejectNullRequiredUpdateFields(dto: Record<string, unknown>): void {
    const requiredFields = ['name', 'slug', 'sortOrder'];

    if (
      requiredFields.some(
        (field) => Object.hasOwn(dto, field) && dto[field] === null,
      )
    ) {
      throw new BadRequestException(
        'Обязательные поля категории не могут быть null',
      );
    }
  }

  private throwKnownPrismaError(error: unknown): never | void {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException('Категория с таким именем или slug уже есть');
    }
  }

  private toCategoryResponse(category: CategoryModel): CategoryResponse {
    return {
      id: category.id,
      name: category.name,
      slug: category.slug,
      iconName: category.iconName,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      isAllowedForListings: category.isAllowedForListings,
      listingPolicy: category.listingPolicy,
      safetyNotice: category.safetyNotice,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    };
  }

  private categorySelect() {
    return {
      id: true,
      name: true,
      slug: true,
      iconName: true,
      sortOrder: true,
      isActive: true,
      isAllowedForListings: true,
      listingPolicy: true,
      safetyNotice: true,
      createdAt: true,
      updatedAt: true,
    } as const;
  }
}
