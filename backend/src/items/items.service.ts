import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import {
  BookingStatus,
  CategoryListingPolicy,
  ItemStatus,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { minorToDecimal } from '../payments/money-minor';
import { PaymentPolicyService } from '../payments/payment-policy.service';
import {
  hashIdempotentPayload,
  isUniqueConstraintError,
} from '../common/http/idempotency';
import { CreateItemDto } from './dto/create-item.dto';
import { ListItemsQueryDto, ItemListSort } from './dto/list-items-query.dto';
import {
  DistanceBucket,
  FavoriteMutationResponseDto,
  PrivateItemResponseDto,
  PublicLocationPrecision,
  PublicItemResponseDto,
} from './dto/item-response.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import {
  ITEM_LISTING_RULES_ACCEPTANCE_METHOD,
  ITEM_LISTING_RULES_VERSION,
} from './items.constants';

const MAX_RADIUS_KM = 50;
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;
const SPARSE_COARSE_CELL_DEGREES = 0.1;

const activeBookingStatuses = [
  BookingStatus.PENDING,
  BookingStatus.CONFIRMED,
  BookingStatus.ACTIVE,
] as const;

const listingMutationBlockingBookingStatuses = [
  ...activeBookingStatuses,
  BookingStatus.RETURNED,
] as const;

const itemCategorySelect = {
  id: true,
  name: true,
  slug: true,
  iconName: true,
  safetyNotice: true,
} as const;

const itemOwnerSelect = {
  id: true,
  name: true,
  city: true,
  avatarUrl: true,
} as const;

const privateItemPhotoSelect = {
  id: true,
  originalUrl: true,
  thumbnailUrl: true,
  previewUrl: true,
  sortOrder: true,
  isCover: true,
  createdAt: true,
} as const;

const publicItemPhotoSelect = {
  id: true,
  thumbnailUrl: true,
  previewUrl: true,
  sortOrder: true,
  isCover: true,
  createdAt: true,
} as const;

const privateItemSelect = {
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
  address: true,
  latitude: true,
  longitude: true,
  createdAt: true,
  updatedAt: true,
  category: { select: itemCategorySelect },
  owner: { select: itemOwnerSelect },
  photos: {
    orderBy: [{ isCover: 'desc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    select: privateItemPhotoSelect,
  },
} as const satisfies Prisma.ItemSelect;

const publicItemSelect = {
  id: true,
  title: true,
  description: true,
  condition: true,
  completeness: true,
  handoverTerms: true,
  pricePerDay: true,
  depositAmount: true,
  publicArea: true,
  latitude: true,
  longitude: true,
  createdAt: true,
  updatedAt: true,
  category: { select: itemCategorySelect },
  owner: { select: itemOwnerSelect },
  photos: {
    orderBy: [{ isCover: 'desc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    select: publicItemPhotoSelect,
  },
} as const satisfies Prisma.ItemSelect;

const favoriteItemSelect = {
  item: { select: publicItemSelect },
} as const satisfies Prisma.FavoriteSelect;

type PrivateItemModel = Prisma.ItemGetPayload<{
  select: typeof privateItemSelect;
}>;
type PublicItemModel = Prisma.ItemGetPayload<{
  select: typeof publicItemSelect;
}>;

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

type ItemDistanceRow = {
  id: string;
  distanceMeters: number | null;
};

@Injectable()
export class ItemsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly paymentPolicy: PaymentPolicyService,
  ) {}

  async create(
    ownerId: string,
    dto: CreateItemDto,
    clientRequestId: string = randomUUID(),
  ): Promise<PrivateItemResponseDto> {
    const depositAmount = this.resolveDepositAmount(dto);
    const category = await this.ensureActiveCategory(dto.categoryId);
    const clientRequestHash = hashIdempotentPayload(dto);

    try {
      const item = await this.prisma.item.create({
        data: {
          ownerId,
          clientRequestId,
          clientRequestHash,
          categoryId: dto.categoryId,
          title: dto.title,
          description: dto.description,
          condition: dto.condition,
          completeness: dto.completeness,
          handoverTerms: dto.handoverTerms,
          pricePerDay: dto.pricePerDay,
          depositAmount,
          status: ItemStatus.PENDING,
          rejectReason: null,
          publicArea: dto.publicArea,
          address: dto.address,
          latitude: dto.latitude,
          longitude: dto.longitude,
          listingRulesVersion: ITEM_LISTING_RULES_VERSION,
          listingRulesAcceptedAt: new Date(),
          listingRulesAcceptanceMethod: ITEM_LISTING_RULES_ACCEPTANCE_METHOD,
          safetyNoticeSnapshot: category.safetyNotice,
        },
        select: privateItemSelect,
      });

      return this.toPrivateItemResponse(item);
    } catch (error) {
      if (!isUniqueConstraintError(error)) {
        throw error;
      }

      const existing = await this.prisma.item.findUnique({
        where: { ownerId_clientRequestId: { ownerId, clientRequestId } },
        select: { ...privateItemSelect, clientRequestHash: true },
      });
      if (!existing || existing.clientRequestHash !== clientRequestHash) {
        throw new ConflictException({
          code: 'IDEMPOTENCY_KEY_REUSED',
          message: 'Идентификатор запроса уже использован',
        });
      }

      return this.toPrivateItemResponse(existing);
    }
  }

  async updateOwn(
    ownerId: string,
    id: string,
    dto: UpdateItemDto,
  ): Promise<PrivateItemResponseDto> {
    const currentItem = await this.findOwnedItem(ownerId, id);
    const data = await this.buildUpdateData(dto);

    if (Object.keys(data).length === 0) {
      return this.toPrivateItemResponse(currentItem);
    }

    await this.ensureNoUnfinishedBookings(id);

    const item = await this.prisma.item.update({
      where: { id },
      data: {
        ...data,
        status: ItemStatus.PENDING,
        rejectReason: null,
      },
      select: privateItemSelect,
    });

    return this.toPrivateItemResponse(item);
  }

  async hideOwn(ownerId: string, id: string): Promise<PrivateItemResponseDto> {
    const currentItem = await this.findOwnedItem(ownerId, id);

    if (currentItem.status === ItemStatus.HIDDEN) {
      return this.toPrivateItemResponse(currentItem);
    }

    await this.ensureNoUnfinishedBookings(id);

    const item = await this.prisma.item.update({
      where: { id },
      data: {
        status: ItemStatus.HIDDEN,
        rejectReason: null,
      },
      select: privateItemSelect,
    });

    return this.toPrivateItemResponse(item);
  }

  async listPublic(query: ListItemsQueryDto): Promise<PublicItemResponseDto[]> {
    this.ensurePriceRange(query);
    const availability = this.getAvailabilityFilter(query);
    const geo = this.getGeoFilter(query);
    const limit = this.getLimit(query.limit);
    const offset = this.getOffset(query.offset);

    if (geo) {
      return this.listPublicByGeo(query, geo, availability, limit, offset);
    }

    const items = await this.prisma.item.findMany({
      where: this.buildPublicWhere(query, availability),
      orderBy: this.buildOrderBy(query.sort),
      take: limit,
      skip: offset,
      select: publicItemSelect,
    });

    return items.map((item) => this.toPublicItemResponse(item));
  }

  async listPublicAreas(): Promise<string[]> {
    const areas = await this.prisma.item.groupBy({
      by: ['publicArea'],
      where: this.buildPublicWhere({}, null),
      orderBy: { publicArea: 'asc' },
    });

    return areas.map((area) => area.publicArea);
  }

  async listFavorites(userId: string): Promise<PublicItemResponseDto[]> {
    const favorites = await this.prisma.favorite.findMany({
      where: {
        userId,
        item: this.buildPublicWhere({}, null),
      },
      orderBy: [{ createdAt: 'desc' }, { itemId: 'desc' }],
      select: favoriteItemSelect,
    });

    return favorites.map((favorite) =>
      this.toPublicItemResponse(favorite.item),
    );
  }

  async addFavorite(
    userId: string,
    itemId: string,
  ): Promise<FavoriteMutationResponseDto> {
    await this.getPublicById(itemId);
    await this.prisma.favorite.upsert({
      where: { userId_itemId: { userId, itemId } },
      create: { userId, itemId },
      update: {},
      select: { itemId: true },
    });
    return { itemId };
  }

  async removeFavorite(
    userId: string,
    itemId: string,
  ): Promise<FavoriteMutationResponseDto> {
    await this.prisma.favorite.deleteMany({ where: { userId, itemId } });
    return { itemId };
  }

  async listOwn(ownerId: string): Promise<PrivateItemResponseDto[]> {
    const items = await this.prisma.item.findMany({
      where: { ownerId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      select: privateItemSelect,
    });

    return items.map((item) => this.toPrivateItemResponse(item));
  }

  async getPublicById(id: string): Promise<PublicItemResponseDto> {
    const item = await this.prisma.item.findFirst({
      where: {
        id,
        status: ItemStatus.APPROVED,
        category: {
          isActive: true,
          isAllowedForListings: true,
          listingPolicy: CategoryListingPolicy.ALLOWED,
        },
        owner: { isBlocked: false, deletedAt: null },
      },
      select: publicItemSelect,
    });

    if (!item) {
      throw new NotFoundException('Объявление не найдено');
    }

    return this.toPublicItemResponse(item);
  }

  private async listPublicByGeo(
    query: ListItemsQueryDto,
    geo: GeoFilter,
    availability: AvailabilityFilter | null,
    limit: number,
    offset: number,
  ): Promise<PublicItemResponseDto[]> {
    const point = Prisma.sql`ST_SetSRID(ST_MakePoint(${geo.longitude}, ${geo.latitude}), 4326)::geography`;
    const publicItemPoint = this.buildRawPublicItemPoint();
    const conditions = this.buildRawPublicConditions(query, availability);

    conditions.push(
      Prisma.sql`ST_DWithin(${publicItemPoint}, ${point}, ${geo.radiusMeters})`,
    );

    const rows = await this.prisma.$queryRaw<ItemDistanceRow[]>(Prisma.sql`
      SELECT
        t."id",
        ST_Distance(${publicItemPoint}, ${point}) AS "distanceMeters"
      FROM "items" t
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

    const items = await this.prisma.item.findMany({
      where: {
        ...this.buildPublicWhere(query, availability),
        id: { in: rows.map((row) => row.id) },
      },
      select: publicItemSelect,
    });
    const itemsById = new Map(items.map((item) => [item.id, item]));

    return rows.flatMap((row) => {
      const item = itemsById.get(row.id);
      return item ? [this.toPublicItemResponse(item, row.distanceMeters)] : [];
    });
  }

  private buildPublicWhere(
    query: ListItemsQueryDto,
    availability: AvailabilityFilter | null,
  ): Prisma.ItemWhereInput {
    const search = query.search?.trim();
    const where: Prisma.ItemWhereInput = {
      status: ItemStatus.APPROVED,
      category: {
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
      owner: { isBlocked: false, deletedAt: null },
    };

    if (query.categoryId) {
      where.categoryId = query.categoryId;
    }

    if (query.area) {
      where.publicArea = query.area;
    }

    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
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
    query: ListItemsQueryDto,
    availability: AvailabilityFilter | null,
  ): Prisma.Sql[] {
    const search = query.search?.trim();
    const conditions = [
      Prisma.sql`t."status" = 'APPROVED'::"ItemStatus"`,
      Prisma.sql`c."isActive" = true`,
      Prisma.sql`c."isAllowedForListings" = true`,
      Prisma.sql`c."listingPolicy" = 'ALLOWED'::"CategoryListingPolicy"`,
      Prisma.sql`u."isBlocked" = false`,
      Prisma.sql`u."deletedAt" IS NULL`,
    ];

    if (query.categoryId) {
      conditions.push(Prisma.sql`t."categoryId" = ${query.categoryId}`);
    }

    if (query.area) {
      conditions.push(Prisma.sql`t."publicArea" = ${query.area}`);
    }

    if (search) {
      const pattern = `%${this.escapeLikePattern(search)}%`;
      conditions.push(
        Prisma.sql`(t."title" ILIKE ${pattern} ESCAPE '\' OR t."description" ILIKE ${pattern} ESCAPE '\')`,
      );
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
          WHERE b."itemId" = t."id"
            AND b."status" IN (
              'PENDING'::"BookingStatus",
              'CONFIRMED'::"BookingStatus",
              'ACTIVE'::"BookingStatus"
            )
            AND b."startDate" <= ${availability.toSql}::date
            AND b."endDate" >= ${availability.fromSql}::date
        )
      `);
    }

    return conditions;
  }

  private buildRawPublicItemPoint(): Prisma.Sql {
    const halfCell = SPARSE_COARSE_CELL_DEGREES / 2;
    const minLatitude = -90;
    const maxLatitude = 90;
    const minLongitude = -180;
    const maxLongitude = 180;

    return Prisma.sql`
      ST_SetSRID(
        ST_MakePoint(
          LEAST(
            ${maxLongitude - halfCell},
            GREATEST(
              ${minLongitude + halfCell},
              ${minLongitude}
                + FLOOR(
                  (t."longitude" - ${minLongitude})
                  / ${SPARSE_COARSE_CELL_DEGREES}
                ) * ${SPARSE_COARSE_CELL_DEGREES}
                + ${halfCell}
            )
          ),
          LEAST(
            ${maxLatitude - halfCell},
            GREATEST(
              ${minLatitude + halfCell},
              ${minLatitude}
                + FLOOR(
                  (t."latitude" - ${minLatitude})
                  / ${SPARSE_COARSE_CELL_DEGREES}
                ) * ${SPARSE_COARSE_CELL_DEGREES}
                + ${halfCell}
            )
          )
        ),
        4326
      )::geography
    `;
  }

  private escapeLikePattern(value: string): string {
    return value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
  }

  private buildOrderBy(
    sort: ItemListSort | undefined,
  ): Prisma.ItemOrderByWithRelationInput[] {
    switch (sort) {
      case ItemListSort.PRICE_ASC:
        return [{ pricePerDay: 'asc' }, { createdAt: 'desc' }, { id: 'desc' }];
      case ItemListSort.PRICE_DESC:
        return [{ pricePerDay: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }];
      case ItemListSort.DISTANCE:
        throw new BadRequestException(
          'Для сортировки по расстоянию укажите координаты',
        );
      case ItemListSort.NEWEST:
      default:
        return [{ createdAt: 'desc' }, { id: 'desc' }];
    }
  }

  private buildRawOrderBy(sort: ItemListSort | undefined): Prisma.Sql {
    switch (sort) {
      case ItemListSort.DISTANCE:
        return Prisma.sql`"distanceMeters" ASC, t."createdAt" DESC, t."id" DESC`;
      case ItemListSort.PRICE_ASC:
        return Prisma.sql`t."pricePerDay" ASC, t."createdAt" DESC, t."id" DESC`;
      case ItemListSort.PRICE_DESC:
        return Prisma.sql`t."pricePerDay" DESC, t."createdAt" DESC, t."id" DESC`;
      case ItemListSort.NEWEST:
      default:
        return Prisma.sql`t."createdAt" DESC, t."id" DESC`;
    }
  }

  private async buildUpdateData(
    dto: UpdateItemDto,
  ): Promise<Prisma.ItemUncheckedUpdateInput> {
    this.rejectNullRequiredUpdateFields(dto as Record<string, unknown>);

    const data: Prisma.ItemUncheckedUpdateInput = {};

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

    if (Object.hasOwn(dto, 'condition')) {
      data.condition = dto.condition;
    }

    if (Object.hasOwn(dto, 'completeness')) {
      data.completeness = dto.completeness;
    }

    if (Object.hasOwn(dto, 'handoverTerms')) {
      data.handoverTerms = dto.handoverTerms;
    }

    if (Object.hasOwn(dto, 'pricePerDay')) {
      data.pricePerDay = dto.pricePerDay;
    }

    if (
      dto.depositAmount !== undefined ||
      dto.depositAmountMinor !== undefined
    ) {
      data.depositAmount = this.resolveDepositAmount(dto);
    }

    if (Object.hasOwn(dto, 'publicArea')) {
      data.publicArea = dto.publicArea;
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

  private resolveDepositAmount(
    dto: Pick<CreateItemDto, 'depositAmount' | 'depositAmountMinor'>,
  ): Prisma.Decimal | null {
    const hasLegacy = dto.depositAmount !== undefined;
    const hasMinor = dto.depositAmountMinor !== undefined;
    if (hasLegacy && hasMinor) {
      throw new BadRequestException('Укажите только один формат суммы залога');
    }

    if (hasLegacy && dto.depositAmount !== null && dto.depositAmount !== 0) {
      throw new BadRequestException(
        'Legacy depositAmount поддерживает только null или 0',
      );
    }

    const minorValue = hasMinor ? (dto.depositAmountMinor ?? null) : 0;
    if (
      minorValue !== null &&
      (!Number.isSafeInteger(minorValue) ||
        minorValue < 0 ||
        minorValue > 3_000_000_000)
    ) {
      throw new BadRequestException('Некорректная сумма залога');
    }

    const minor = BigInt(minorValue ?? 0);
    this.paymentPolicy.assertDepositAllowed(minor);
    if (
      (hasLegacy && dto.depositAmount === null) ||
      (hasMinor && minorValue === null)
    ) {
      return null;
    }

    return hasLegacy || hasMinor ? minorToDecimal(minor) : null;
  }

  private rejectNullRequiredUpdateFields(dto: Record<string, unknown>): void {
    const requiredFields = [
      'categoryId',
      'title',
      'description',
      'condition',
      'completeness',
      'handoverTerms',
      'pricePerDay',
      'publicArea',
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

  private async ensureActiveCategory(
    categoryId: string,
  ): Promise<{ safetyNotice: string }> {
    const category = await this.prisma.category.findFirst({
      where: {
        id: categoryId,
        isActive: true,
        isAllowedForListings: true,
        listingPolicy: CategoryListingPolicy.ALLOWED,
      },
      select: { safetyNotice: true },
    });

    if (!category) {
      throw new NotFoundException('Категория не найдена');
    }

    return category;
  }

  private async ensureNoUnfinishedBookings(itemId: string): Promise<void> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        itemId,
        status: { in: [...listingMutationBlockingBookingStatuses] },
      },
      select: { id: true },
    });

    if (booking) {
      throw new ConflictException({
        code: 'ITEM_HAS_UNFINISHED_BOOKINGS',
        message:
          'Нельзя изменить или скрыть объявление до завершения связанных бронирований',
      });
    }
  }

  private async findOwnedItem(
    ownerId: string,
    id: string,
  ): Promise<PrivateItemModel> {
    const item = await this.prisma.item.findFirst({
      where: { id, ownerId },
      select: privateItemSelect,
    });

    if (!item) {
      throw new NotFoundException('Объявление не найдено');
    }

    return item;
  }

  private ensurePriceRange(query: ListItemsQueryDto): void {
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
    query: ListItemsQueryDto,
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

  private getGeoFilter(query: ListItemsQueryDto): GeoFilter | null {
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

      if (query.sort === ItemListSort.DISTANCE) {
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

  private toPrivateItemResponse(
    item: PrivateItemModel,
  ): PrivateItemResponseDto {
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
      address: item.address,
      latitude: item.latitude,
      longitude: item.longitude,
      category: item.category,
      owner: item.owner,
      photos: item.photos,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  private toPublicItemResponse(
    item: PublicItemModel,
    distanceMeters: number | null = null,
  ): PublicItemResponseDto {
    return {
      id: item.id,
      title: item.title,
      description: item.description,
      condition: item.condition,
      completeness: item.completeness,
      handoverTerms: item.handoverTerms,
      pricePerDay: this.decimalToNumber(item.pricePerDay),
      depositAmount: this.nullableDecimalToNumber(item.depositAmount),
      area: item.publicArea,
      approximateLocation: {
        latitude: this.toSparseCellCenter(item.latitude, -90, 90),
        longitude: this.toSparseCellCenter(item.longitude, -180, 180),
        precision: PublicLocationPrecision.SPARSE,
      },
      distanceBucket: this.toDistanceBucket(distanceMeters),
      category: item.category,
      owner: item.owner,
      photos: item.photos.map((photo) => ({
        id: photo.id,
        thumbnailUrl: photo.thumbnailUrl,
        previewUrl: photo.previewUrl,
        sortOrder: photo.sortOrder,
        isCover: photo.isCover,
        createdAt: photo.createdAt,
      })),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }

  private toSparseCellCenter(value: number, min: number, max: number): number {
    // Until a trusted density source exists, every public response uses the
    // conservative sparse-area grid. The deterministic cell prevents averaging
    // attacks caused by per-request random jitter.
    const halfCell = SPARSE_COARSE_CELL_DEGREES / 2;
    const cellIndex = Math.floor((value - min) / SPARSE_COARSE_CELL_DEGREES);
    const cellCenter = min + cellIndex * SPARSE_COARSE_CELL_DEGREES + halfCell;
    const boundedCenter = Math.min(
      max - halfCell,
      Math.max(min + halfCell, cellCenter),
    );

    return Number(boundedCenter.toFixed(4));
  }

  private toDistanceBucket(
    distanceMeters: number | null,
  ): DistanceBucket | null {
    if (distanceMeters === null) {
      return null;
    }

    if (distanceMeters < 1_000) {
      return DistanceBucket.UNDER_1_KM;
    }
    if (distanceMeters < 3_000) {
      return DistanceBucket.FROM_1_TO_3_KM;
    }
    if (distanceMeters < 5_000) {
      return DistanceBucket.FROM_3_TO_5_KM;
    }
    if (distanceMeters < 10_000) {
      return DistanceBucket.FROM_5_TO_10_KM;
    }
    if (distanceMeters < 25_000) {
      return DistanceBucket.FROM_10_TO_25_KM;
    }
    if (distanceMeters <= 50_000) {
      return DistanceBucket.FROM_25_TO_50_KM;
    }

    return DistanceBucket.OVER_50_KM;
  }

  private decimalToNumber(value: Prisma.Decimal): number {
    return Number(value.toString());
  }

  private nullableDecimalToNumber(value: Prisma.Decimal | null): number | null {
    return value === null ? null : this.decimalToNumber(value);
  }
}
