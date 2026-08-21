import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, Prisma, ReviewAuthorRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { ListReviewsQueryDto } from './dto/list-reviews-query.dto';
import {
  ParticipantReviewResponseDto,
  PublicReviewPageResponseDto,
} from './dto/review-response.dto';

export const REVIEW_WINDOW_MS = 14 * 24 * 60 * 60 * 1000;

const REVIEW_SELECT = {
  id: true,
  bookingId: true,
  authorId: true,
  authorRole: true,
  clientReviewId: true,
  rating: true,
  text: true,
  publishAt: true,
  hiddenAt: true,
  createdAt: true,
} satisfies Prisma.ReviewSelect;

type ReviewRow = Prisma.ReviewGetPayload<{ select: typeof REVIEW_SELECT }>;

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    actorId: string,
    bookingId: string,
    dto: CreateReviewDto,
    now = new Date(),
  ): Promise<ParticipantReviewResponseDto> {
    const text = dto.text ?? null;
    assertSafeReviewText(text);
    return this.prisma.$transaction(
      async (tx) => {
        await tx.$executeRaw`
          SELECT pg_advisory_xact_lock(
            hashtextextended(
              ${`review-idempotency:${actorId}:${dto.clientReviewId}`},
              0
            )
          )
        `;
        await tx.$executeRaw`
          SELECT pg_advisory_xact_lock(hashtext(${bookingId}))
        `;
        const booking = await tx.booking.findFirst({
          where: {
            id: bookingId,
            OR: [{ borrowerId: actorId }, { lenderId: actorId }],
          },
          select: {
            id: true,
            borrowerId: true,
            lenderId: true,
            status: true,
          },
        });
        if (!booking) {
          throw new NotFoundException('Бронирование не найдено');
        }
        if (booking.status !== BookingStatus.COMPLETED) {
          throw new ConflictException({
            code: 'REVIEW_BOOKING_NOT_COMPLETED',
            message: 'Отзыв доступен только после завершённой аренды',
          });
        }

        const authorRole =
          booking.borrowerId === actorId
            ? ReviewAuthorRole.BORROWER
            : ReviewAuthorRole.LENDER;
        const targetId =
          authorRole === ReviewAuthorRole.BORROWER
            ? booking.lenderId
            : booking.borrowerId;
        const repeated = await tx.review.findUnique({
          where: {
            authorId_clientReviewId: {
              authorId: actorId,
              clientReviewId: dto.clientReviewId,
            },
          },
          select: REVIEW_SELECT,
        });
        if (repeated) {
          if (
            repeated.bookingId !== bookingId ||
            repeated.rating !== dto.rating ||
            repeated.text !== text
          ) {
            throw new ConflictException({
              code: 'IDEMPOTENCY_KEY_REUSED',
              message: 'Идентификатор отзыва уже использован',
            });
          }
          return this.toParticipantResponse(actorId, repeated, now);
        }

        const completion = await tx.bookingTransitionHistory.findFirst({
          where: { bookingId, newStatus: BookingStatus.COMPLETED },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          select: { createdAt: true },
        });
        if (!completion) {
          throw new ConflictException({
            code: 'REVIEW_COMPLETION_NOT_RECORDED',
            message: 'Завершение аренды не подтверждено историей',
          });
        }
        const deadline = new Date(
          completion.createdAt.getTime() + REVIEW_WINDOW_MS,
        );
        if (now > deadline) {
          throw new ConflictException({
            code: 'REVIEW_WINDOW_CLOSED',
            message: 'Срок публикации отзыва истёк',
          });
        }
        const existing = await tx.review.findUnique({
          where: { bookingId_authorRole: { bookingId, authorRole } },
          select: { id: true },
        });
        if (existing) {
          throw new ConflictException({
            code: 'REVIEW_ALREADY_SUBMITTED',
            message: 'Вы уже оставили отзыв об этой аренде',
          });
        }

        const created = await tx.review.create({
          data: {
            bookingId,
            authorId: actorId,
            targetId,
            authorRole,
            clientReviewId: dto.clientReviewId,
            rating: dto.rating,
            text,
            publishAt: deadline,
          },
          select: REVIEW_SELECT,
        });
        const counterpartExists = await tx.review.findFirst({
          where: { bookingId, authorRole: { not: authorRole } },
          select: { id: true },
        });
        if (!counterpartExists) {
          return this.toParticipantResponse(actorId, created, now);
        }
        await tx.review.updateMany({
          where: { bookingId, publishAt: { gt: now } },
          data: { publishAt: now },
        });
        return this.toParticipantResponse(
          actorId,
          { ...created, publishAt: now },
          now,
        );
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
    );
  }

  async listForBooking(
    actorId: string,
    bookingId: string,
    now = new Date(),
  ): Promise<ParticipantReviewResponseDto[]> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        OR: [{ borrowerId: actorId }, { lenderId: actorId }],
      },
      select: { id: true },
    });
    if (!booking) {
      throw new NotFoundException('Бронирование не найдено');
    }
    const reviews = await this.prisma.review.findMany({
      where: { bookingId },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: REVIEW_SELECT,
    });
    return reviews
      .filter(
        (review) =>
          review.authorId === actorId ||
          (review.publishAt <= now && review.hiddenAt === null),
      )
      .map((review) => this.toParticipantResponse(actorId, review, now));
  }

  async listPublicForUser(
    targetId: string,
    query: ListReviewsQueryDto,
    now = new Date(),
  ): Promise<PublicReviewPageResponseDto> {
    const target = await this.prisma.user.findFirst({
      where: { id: targetId, deletedAt: null, isBlocked: false },
      select: { id: true },
    });
    if (!target) {
      throw new NotFoundException('Профиль не найден');
    }
    const cursor = query.cursor
      ? await this.prisma.review.findFirst({
          where: {
            id: query.cursor,
            targetId,
            hiddenAt: null,
            publishAt: { lte: now },
          },
          select: { id: true, createdAt: true },
        })
      : null;
    if (query.cursor && !cursor) {
      throw new NotFoundException('Курсор отзывов недействителен');
    }
    const visibility = {
      targetId,
      hiddenAt: null,
      publishAt: { lte: now },
    } satisfies Prisma.ReviewWhereInput;
    const [reviews, aggregate] = await Promise.all([
      this.prisma.review.findMany({
        where: {
          ...visibility,
          ...(cursor
            ? {
                OR: [
                  { createdAt: { lt: cursor.createdAt } },
                  { createdAt: cursor.createdAt, id: { lt: cursor.id } },
                ],
              }
            : {}),
        },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: query.limit + 1,
        select: REVIEW_SELECT,
      }),
      this.prisma.review.aggregate({
        where: visibility,
        _avg: { rating: true },
        _count: { _all: true },
      }),
    ]);
    const hasMore = reviews.length > query.limit;
    const page = hasMore ? reviews.slice(0, query.limit) : reviews;
    return {
      summary: {
        average: aggregate._avg.rating,
        count: aggregate._count._all,
      },
      items: page.map((review) => ({
        id: review.id,
        authorRole: review.authorRole,
        rating: review.rating,
        text: review.text,
        verifiedRental: true,
        publishedAt: review.publishAt,
        createdAt: review.createdAt,
      })),
      nextCursor: hasMore ? (page.at(-1)?.id ?? null) : null,
    };
  }

  private toParticipantResponse(
    actorId: string,
    review: ReviewRow,
    now: Date,
  ): ParticipantReviewResponseDto {
    return {
      id: review.id,
      author: review.authorId === actorId ? 'SELF' : 'COUNTERPARTY',
      rating: review.rating,
      text: review.text,
      published: review.publishAt <= now && review.hiddenAt === null,
      hidden: review.hiddenAt !== null,
      publishAt: review.publishAt,
      createdAt: review.createdAt,
    };
  }
}

function assertSafeReviewText(text: string | null): void {
  if (text === null) {
    return;
  }
  for (const character of text) {
    const code = character.codePointAt(0) ?? 0;
    if (
      (code >= 0 && code <= 8) ||
      code === 11 ||
      code === 12 ||
      (code >= 14 && code <= 31) ||
      code === 127
    ) {
      throw new BadRequestException(
        'Текст содержит недопустимые управляющие символы',
      );
    }
  }
}
