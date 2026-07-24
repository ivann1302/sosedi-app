import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Category, Prisma } from '@prisma/client';
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
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async listActive(): Promise<CategoryResponse[]> {
    const categories = await this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
      select: this.categorySelect(),
    });

    return categories.map((category) => this.toCategoryResponse(category));
  }

  async getBySlug(slug: string): Promise<CategoryResponse> {
    const category = await this.prisma.category.findFirst({
      where: { slug, isActive: true },
      select: this.categorySelect(),
    });

    if (!category) {
      throw new NotFoundException('Категория не найдена');
    }

    return this.toCategoryResponse(category);
  }

  async create(dto: CreateCategoryDto): Promise<CategoryResponse> {
    try {
      const category = await this.prisma.category.create({
        data: {
          name: dto.name,
          slug: dto.slug,
          iconName: dto.iconName ?? null,
          sortOrder: dto.sortOrder ?? 0,
          isActive: dto.isActive ?? true,
        },
        select: this.categorySelect(),
      });

      return this.toCategoryResponse(category);
    } catch (error) {
      this.throwKnownPrismaError(error);
      throw error;
    }
  }

  async update(id: string, dto: UpdateCategoryDto): Promise<CategoryResponse> {
    const data = this.buildUpdateData(dto);
    const currentCategory = await this.findById(id);

    if (Object.keys(data).length === 0) {
      return this.toCategoryResponse(currentCategory);
    }

    try {
      const category = await this.prisma.category.update({
        where: { id },
        data,
        select: this.categorySelect(),
      });

      return this.toCategoryResponse(category);
    } catch (error) {
      this.throwKnownPrismaError(error);
      throw error;
    }
  }

  async disable(id: string): Promise<CategoryResponse> {
    await this.findById(id);

    const category = await this.prisma.category.update({
      where: { id },
      data: { isActive: false },
      select: this.categorySelect(),
    });

    return this.toCategoryResponse(category);
  }

  private async findById(id: string): Promise<CategoryModel> {
    const category = await this.prisma.category.findUnique({
      where: { id },
      select: this.categorySelect(),
    });

    if (!category) {
      throw new NotFoundException('Категория не найдена');
    }

    return category;
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

    if (Object.hasOwn(dto, 'isActive')) {
      data.isActive = dto.isActive;
    }

    return data;
  }

  private rejectNullRequiredUpdateFields(dto: Record<string, unknown>): void {
    const requiredFields = ['name', 'slug', 'sortOrder', 'isActive'];

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
      createdAt: true,
      updatedAt: true,
    } as const;
  }
}
