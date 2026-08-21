import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, ItemStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { parseBookingPeriod } from './booking-period';
import { CreateUnavailablePeriodDto } from './dto/create-unavailable-period.dto';
import { ItemAvailabilityResponseDto } from './dto/item-availability-response.dto';
import { UnavailablePeriodResponseDto } from './dto/unavailable-period-response.dto';

@Injectable()
export class BookingAvailabilityService {
  constructor(private readonly prisma: PrismaService) {}

  async check(
    itemId: string,
    dto: CreateUnavailablePeriodDto,
  ): Promise<ItemAvailabilityResponseDto> {
    const period = parseBookingPeriod(dto.startDate, dto.endDate);
    const item = await this.prisma.item.findFirst({
      where: { id: itemId, status: ItemStatus.APPROVED },
      select: { id: true },
    });
    if (!item) {
      throw new NotFoundException('Объявление не найдено');
    }

    const [bookingConflict, calendarConflict] = await Promise.all([
      this.prisma.booking.findFirst({
        where: {
          itemId,
          startDate: { lte: period.endDate },
          endDate: { gte: period.startDate },
          status: {
            in: [
              BookingStatus.CONFIRMED,
              BookingStatus.ACTIVE,
              BookingStatus.RETURNED,
            ],
          },
        },
        select: { id: true },
      }),
      this.prisma.itemUnavailablePeriod.findFirst({
        where: {
          itemId,
          startDate: { lte: period.endDate },
          endDate: { gte: period.startDate },
        },
        select: { id: true },
      }),
    ]);

    return { available: !bookingConflict && !calendarConflict };
  }

  async listOwn(
    ownerId: string,
    itemId: string,
  ): Promise<UnavailablePeriodResponseDto[]> {
    await this.requireOwnedItem(this.prisma, ownerId, itemId);
    return this.prisma.itemUnavailablePeriod.findMany({
      where: { itemId },
      orderBy: [{ startDate: 'asc' }, { createdAt: 'asc' }],
    });
  }

  async create(
    ownerId: string,
    itemId: string,
    dto: CreateUnavailablePeriodDto,
  ): Promise<UnavailablePeriodResponseDto> {
    const period = parseBookingPeriod(dto.startDate, dto.endDate);
    return this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${itemId}))`;
        await this.requireOwnedItem(tx, ownerId, itemId);

        const bookingConflict = await tx.booking.findFirst({
          where: {
            itemId,
            startDate: { lte: period.endDate },
            endDate: { gte: period.startDate },
            status: {
              in: [
                BookingStatus.CONFIRMED,
                BookingStatus.ACTIVE,
                BookingStatus.RETURNED,
              ],
            },
          },
          select: { id: true },
        });
        if (bookingConflict) {
          throw new ConflictException({
            code: 'BOOKING_CONFLICT',
            message: 'Период пересекается с существующим бронированием',
          });
        }

        const calendarConflict = await tx.itemUnavailablePeriod.findFirst({
          where: {
            itemId,
            startDate: { lte: period.endDate },
            endDate: { gte: period.startDate },
          },
          select: { id: true },
        });
        if (calendarConflict) {
          throw new ConflictException({
            code: 'CALENDAR_CONFLICT',
            message: 'Период уже отмечен как недоступный',
          });
        }

        return tx.itemUnavailablePeriod.create({
          data: {
            itemId,
            startDate: period.startDate,
            endDate: period.endDate,
          },
        });
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted },
    );
  }

  async remove(
    ownerId: string,
    itemId: string,
    periodId: string,
  ): Promise<void> {
    await this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${itemId}))`;
        await this.requireOwnedItem(tx, ownerId, itemId);
        const deleted = await tx.itemUnavailablePeriod.deleteMany({
          where: { id: periodId, itemId },
        });
        if (deleted.count === 0) {
          throw new NotFoundException('Период недоступности не найден');
        }
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted },
    );
  }

  private async requireOwnedItem(
    db: Pick<PrismaService, 'item'>,
    ownerId: string,
    itemId: string,
  ): Promise<void> {
    const item = await db.item.findFirst({
      where: { id: itemId, ownerId },
      select: { id: true },
    });
    if (!item) {
      throw new NotFoundException('Объявление не найдено');
    }
  }
}
