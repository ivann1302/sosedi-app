import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  BookingStatus,
  KycStatus,
  Prisma,
  ToolStatus,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateToolDto } from './dto/create-tool.dto';
import { ListToolsQueryDto, ToolListSort } from './dto/list-tools-query.dto';
import { UpdateToolDto } from './dto/update-tool.dto';

const MAX_RADIUS_KM = 50;
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

const activeBookingStatuses = [
  BookingStatus.PENDING,
  BookingStatus.CONFIRMED,
  BookingStatus.PAID,
  BookingStatus.ACTIVE,
] as const;

const toolPhotoSelect = {
  id: true,
  originalUrl: true,
  thumbnailUrl: true,
  previewUrl: true,
  sortOrder: true,
  isCover: true,
  createdAt: true,
} as const;

const toolSelect = {
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
      name: true,
      city: true,
      avatarUrl: true,
    },
  },
  photos: {
    orderBy: [{ isCover: 'desc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    select: toolPhotoSelect,
  },
} as const satisfies Prisma.ToolSelect;

type ToolModel = Prisma.ToolGetPayload<{ select: typeof toolSelect }>;

type AvailabilityFilter = {
  from: Date;
  to: Date;
  fromSql: string;
  toSql: string;
};

type GeoFilter = {
  latitude: number;
  longitude: number;
  radiusMeters: number;
};

type ToolDistanceRow = {
  id: string;
  distanceMeters: number | null;
};

export type ToolPhotoResponse = {
  id: string;
  originalUrl: string;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

export type ToolResponse = {
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
  distanceMeters: number | null;
  category: {
    id: string;
    name: string;
    slug: string;
    iconName: string | null;
  };
  owner: {
    id: string;
    name: string | null;
    city: string | null;
    avatarUrl: string | null;
  };
  photos: ToolPhotoResponse[];
  createdAt: Date;
  updatedAt: Date;
};

@Injectable()
export class ToolsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(ownerId: string, dto: CreateToolDto): Promise<ToolResponse> {
    await this.ensureActiveCategory(dto.categoryId);

    const tool = await this.prisma.$transaction(async (tx) => {
      // Первое объявление переводит пользователя в роль владельца для MVP-флоу.
      await tx.user.updateMany({
        where: { id: ownerId, role: UserRole.RENTER },
        data: { role: UserRole.OWNER, kycStatus: KycStatus.PENDING },
      });

      return tx.tool.create({
        data: {
          ownerId,
          categoryId: dto.categoryId,
          title: dto.title,
          description: dto.description,
          pricePerDay: dto.pricePerDay,
          depositAmount: dto.depositAmount ?? null,
          status: ToolStatus.PENDING,
          rejectReason: null,
          address: dto.address,
          latitude: dto.latitude,
          longitude: dto.longitude,
        },
        select: toolSelect,
      });
    });

    return this.toToolResponse(tool);
  }

  async updateOwn(
    ownerId: string,
    id: string,
    dto: UpdateToolDto,
  ): Promise<ToolResponse> {
    const currentTool = await this.findOwnedTool(ownerId, id);
    const data = await this.buildUpdateData(dto);

    if (Object.keys(data).length === 0) {
      return this.toToolResponse(currentTool);
    }

    const tool = await this.prisma.tool.update({
      where: { id },
      data: {
        ...data,
        status: ToolStatus.PENDING,
        rejectReason: null,
      },
      select: toolSelect,
    });

    return this.toToolResponse(tool);
  }

  async hideOwn(ownerId: string, id: string): Promise<ToolResponse> {
    const currentTool = await this.findOwnedTool(ownerId, id);

    if (currentTool.status === ToolStatus.HIDDEN) {
      return this.toToolResponse(currentTool);
    }

    const tool = await this.prisma.tool.update({
      where: { id },
      data: {
        status: ToolStatus.HIDDEN,
        rejectReason: null,
      },
      select: toolSelect,
    });

    return this.toToolResponse(tool);
  }

  async listPublic(query: ListToolsQueryDto): Promise<ToolResponse[]> {
    this.ensurePriceRange(query);
    const availability = this.getAvailabilityFilter(query);
    const geo = this.getGeoFilter(query);
    const limit = this.getLimit(query.limit);
    const offset = this.getOffset(query.offset);

    if (geo) {
      return this.listPublicByGeo(query, geo, availability, limit, offset);
    }

    const tools = await this.prisma.tool.findMany({
      where: this.buildPublicWhere(query, availability),
      orderBy: this.buildOrderBy(query.sort),
      take: limit,
      skip: offset,
      select: toolSelect,
    });

    return tools.map((tool) => this.toToolResponse(tool));
  }

  async getPublicById(id: string): Promise<ToolResponse> {
    const tool = await this.prisma.tool.findFirst({
      where: {
        id,
        status: ToolStatus.APPROVED,
        category: { isActive: true },
        owner: { isBlocked: false, deletedAt: null },
      },
      select: toolSelect,
    });

    if (!tool) {
      throw new NotFoundException('Объявление не найдено');
    }

    return this.toToolResponse(tool);
  }

  private async listPublicByGeo(
    query: ListToolsQueryDto,
    geo: GeoFilter,
    availability: AvailabilityFilter | null,
    limit: number,
    offset: number,
  ): Promise<ToolResponse[]> {
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${geo.longitude}, ${geo.latitude}), 4326)::geography`;
    const conditions = this.buildRawPublicConditions(query, availability);

    conditions.push(Prisma.sql`t."location" IS NOT NULL`);
    conditions.push(
      Prisma.sql`ST_DWithin(t."location", ${point}, ${geo.radiusMeters})`,
    );

    const rows = await this.prisma.$queryRaw<ToolDistanceRow[]>(Prisma.sql`
      SELECT
        t."id",
        ST_Distance(t."location", ${point}) AS "distanceMeters"
      FROM "tools" t
      INNER JOIN "categories" c ON c."id" = t."categoryId"
      INNER JOIN "users" u ON u."id" = t."ownerId"
      WHERE ${Prisma.join(conditions, ' AND ')}
      ORDER BY ${this.buildRawOrderBy(query.sort)}
      LIMIT ${limit}
      OFFSET ${offset}
    `);

    if (rows.length === 0) {
      return [];
    }

    const tools = await this.prisma.tool.findMany({
      where: { id: { in: rows.map((row) => row.id) } },
      select: toolSelect,
    });
    const toolsById = new Map(tools.map((tool) => [tool.id, tool]));

    return rows.flatMap((row) => {
      const tool = toolsById.get(row.id);
      return tool ? [this.toToolResponse(tool, row.distanceMeters)] : [];
    });
  }

  private buildPublicWhere(
    query: ListToolsQueryDto,
    availability: AvailabilityFilter | null,
  ): Prisma.ToolWhereInput {
    const where: Prisma.ToolWhereInput = {
      status: ToolStatus.APPROVED,
      category: { isActive: true },
      owner: { isBlocked: false, deletedAt: null },
    };

    if (query.categoryId) {
      where.categoryId = query.categoryId;
    }

    if (query.minPrice !== undefined || query.maxPrice !== undefined) {
      where.pricePerDay = {
        ...(query.minPrice !== undefined ? { gte: query.minPrice } : {}),
        ...(query.maxPrice !== undefined ? { lte: query.maxPrice } : {}),
      };
    }

    if (availability) {
      where.bookings = {
        none: {
          status: { in: [...activeBookingStatuses] },
          startDate: { lte: availability.to },
          endDate: { gte: availability.from },
        },
      };
    }

    return where;
  }

  private buildRawPublicConditions(
    query: ListToolsQueryDto,
    availability: AvailabilityFilter | null,
  ): Prisma.Sql[] {
    const conditions = [
      Prisma.sql`t."status" = 'APPROVED'::"ToolStatus"`,
      Prisma.sql`c."isActive" = true`,
      Prisma.sql`u."isBlocked" = false`,
      Prisma.sql`u."deletedAt" IS NULL`,
    ];

    if (query.categoryId) {
      conditions.push(Prisma.sql`t."categoryId" = ${query.categoryId}`);
    }

    if (query.minPrice !== undefined) {
      conditions.push(Prisma.sql`t."pricePerDay" >= ${query.minPrice}`);
    }

    if (query.maxPrice !== undefined) {
      conditions.push(Prisma.sql`t."pricePerDay" <= ${query.maxPrice}`);
    }

    if (availability) {
      conditions.push(Prisma.sql`
        NOT EXISTS (
          SELECT 1
          FROM "bookings" b
          WHERE b."toolId" = t."id"
            AND b."status" IN (
              'PENDING'::"BookingStatus",
              'CONFIRMED'::"BookingStatus",
              'PAID'::"BookingStatus",
              'ACTIVE'::"BookingStatus"
            )
            AND b."startDate" <= ${availability.toSql}::date
            AND b."endDate" >= ${availability.fromSql}::date
        )
      `);
    }

    return conditions;
  }

  private buildOrderBy(
    sort: ToolListSort | undefined,
  ): Prisma.ToolOrderByWithRelationInput[] {
    switch (sort) {
      case ToolListSort.PRICE_ASC:
        return [{ pricePerDay: 'asc' }, { createdAt: 'desc' }];
      case ToolListSort.PRICE_DESC:
        return [{ pricePerDay: 'desc' }, { createdAt: 'desc' }];
      case ToolListSort.DISTANCE:
        throw new BadRequestException(
          'Для сортировки по расстоянию укажите координаты',
        );
      case ToolListSort.NEWEST:
      default:
        return [{ createdAt: 'desc' }];
    }
  }

  private buildRawOrderBy(sort: ToolListSort | undefined): Prisma.Sql {
    switch (sort) {
      case ToolListSort.DISTANCE:
        return Prisma.sql`"distanceMeters" ASC, t."createdAt" DESC`;
      case ToolListSort.PRICE_ASC:
        return Prisma.sql`t."pricePerDay" ASC, t."createdAt" DESC`;
      case ToolListSort.PRICE_DESC:
        return Prisma.sql`t."pricePerDay" DESC, t."createdAt" DESC`;
      case ToolListSort.NEWEST:
      default:
        return Prisma.sql`t."createdAt" DESC`;
    }
  }

  private async buildUpdateData(
    dto: UpdateToolDto,
  ): Promise<Prisma.ToolUncheckedUpdateInput> {
    this.rejectNullRequiredUpdateFields(dto as Record<string, unknown>);

    const data: Prisma.ToolUncheckedUpdateInput = {};

    if (Object.hasOwn(dto, 'categoryId')) {
      if (dto.categoryId === undefined) {
        throw new BadRequestException('Категория объявления обязательна');
      }

      await this.ensureActiveCategory(dto.categoryId);
      data.categoryId = dto.categoryId;
    }

    if (Object.hasOwn(dto, 'title')) {
      data.title = dto.title;
    }

    if (Object.hasOwn(dto, 'description')) {
      data.description = dto.description;
    }

    if (Object.hasOwn(dto, 'pricePerDay')) {
      data.pricePerDay = dto.pricePerDay;
    }

    if (Object.hasOwn(dto, 'depositAmount')) {
      data.depositAmount = dto.depositAmount ?? null;
    }

    if (Object.hasOwn(dto, 'address')) {
      data.address = dto.address;
    }

    if (Object.hasOwn(dto, 'latitude')) {
      data.latitude = dto.latitude;
    }

    if (Object.hasOwn(dto, 'longitude')) {
      data.longitude = dto.longitude;
    }

    return data;
  }

  private rejectNullRequiredUpdateFields(dto: Record<string, unknown>): void {
    const requiredFields = [
      'categoryId',
      'title',
      'description',
      'pricePerDay',
      'address',
      'latitude',
      'longitude',
    ];

    if (
      requiredFields.some(
        (field) => Object.hasOwn(dto, field) && dto[field] === null,
      )
    ) {
      throw new BadRequestException(
        'Обязательные поля объявления не могут быть null',
      );
    }
  }

  private async ensureActiveCategory(categoryId: string): Promise<void> {
    const category = await this.prisma.category.findFirst({
      where: { id: categoryId, isActive: true },
      select: { id: true },
    });

    if (!category) {
      throw new NotFoundException('Категория не найдена');
    }
  }

  private async findOwnedTool(ownerId: string, id: string): Promise<ToolModel> {
    const tool = await this.prisma.tool.findUnique({
      where: { id },
      select: toolSelect,
    });

    if (!tool) {
      throw new NotFoundException('Объявление не найдено');
    }

    if (tool.ownerId !== ownerId) {
      throw new ForbiddenException(
        'Можно редактировать только своё объявление',
      );
    }

    return tool;
  }

  private ensurePriceRange(query: ListToolsQueryDto): void {
    if (
      query.minPrice !== undefined &&
      query.maxPrice !== undefined &&
      query.minPrice > query.maxPrice
    ) {
      throw new BadRequestException(
        'Минимальная цена не может быть больше максимальной',
      );
    }
  }

  private getAvailabilityFilter(
    query: ListToolsQueryDto,
  ): AvailabilityFilter | null {
    const hasFrom = query.availableFrom !== undefined;
    const hasTo = query.availableTo !== undefined;

    if (hasFrom !== hasTo) {
      throw new BadRequestException(
        'Для фильтра доступности укажите даты начала и окончания',
      );
    }

    if (!query.availableFrom || !query.availableTo) {
      return null;
    }

    const from = this.parseDateOnly(query.availableFrom, 'availableFrom');
    const to = this.parseDateOnly(query.availableTo, 'availableTo');

    if (from > to) {
      throw new BadRequestException(
        'Дата начала аренды не может быть позже даты окончания',
      );
    }

    return {
      from,
      to,
      fromSql: query.availableFrom,
      toSql: query.availableTo,
    };
  }

  private getGeoFilter(query: ListToolsQueryDto): GeoFilter | null {
    const { latitude, longitude } = query;

    if ((latitude === undefined) !== (longitude === undefined)) {
      throw new BadRequestException('Укажите широту и долготу вместе');
    }

    if (latitude === undefined || longitude === undefined) {
      if (query.radiusKm !== undefined) {
        throw new BadRequestException(
          'Для фильтра по радиусу укажите координаты',
        );
      }

      if (query.sort === ToolListSort.DISTANCE) {
        throw new BadRequestException(
          'Для сортировки по расстоянию укажите координаты',
        );
      }

      return null;
    }

    const radiusKm = query.radiusKm ?? MAX_RADIUS_KM;
    if (radiusKm <= 0 || radiusKm > MAX_RADIUS_KM) {
      throw new BadRequestException('Радиус поиска не может быть больше 50 км');
    }

    return {
      latitude,
      longitude,
      radiusMeters: radiusKm * 1000,
    };
  }

  private getLimit(limit?: number): number {
    const value = limit ?? DEFAULT_LIMIT;

    if (!Number.isInteger(value) || value < 1 || value > MAX_LIMIT) {
      throw new BadRequestException('Лимит списка должен быть от 1 до 50');
    }

    return value;
  }

  private getOffset(offset?: number): number {
    const value = offset ?? 0;

    if (!Number.isInteger(value) || value < 0) {
      throw new BadRequestException(
        'Offset списка не может быть отрицательным',
      );
    }

    return value;
  }

  private parseDateOnly(value: string, field: string): Date {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      throw new BadRequestException(`Некорректная дата ${field}`);
    }

    const date = new Date(`${value}T00:00:00.000Z`);

    if (
      Number.isNaN(date.getTime()) ||
      date.toISOString().slice(0, 10) !== value
    ) {
      throw new BadRequestException(`Некорректная дата ${field}`);
    }

    return date;
  }

  private toToolResponse(
    tool: ToolModel,
    distanceMeters: number | null = null,
  ): ToolResponse {
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
      distanceMeters,
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
