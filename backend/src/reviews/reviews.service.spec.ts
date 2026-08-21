import { ConflictException } from '@nestjs/common';
import { BookingStatus, ReviewAuthorRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { REVIEW_WINDOW_MS, ReviewsService } from './reviews.service';

const completedAt = new Date('2026-08-01T12:00:00.000Z');
const now = new Date('2026-08-02T12:00:00.000Z');
const dto = {
  clientReviewId: '11111111-1111-4111-8111-111111111151',
  rating: 5,
  text: 'Всё прошло отлично.',
};

function createService(status = BookingStatus.COMPLETED) {
  const booking = {
    id: 'booking-1',
    borrowerId: 'borrower-1',
    lenderId: 'lender-1',
    status,
  };
  const created = {
    id: 'review-1',
    bookingId: booking.id,
    authorId: booking.borrowerId,
    authorRole: ReviewAuthorRole.BORROWER,
    clientReviewId: dto.clientReviewId,
    rating: dto.rating,
    text: dto.text,
    publishAt: new Date(completedAt.getTime() + REVIEW_WINDOW_MS),
    hiddenAt: null,
    createdAt: now,
  };
  const reviewFindUnique = jest.fn(
    ({ where }: { where: Record<string, unknown> }) =>
      Promise.resolve(
        'authorId_clientReviewId' in where
          ? null
          : 'bookingId_authorRole' in where
            ? null
            : null,
      ),
  );
  const tx = {
    $executeRaw: jest.fn().mockResolvedValue(1),
    booking: { findFirst: jest.fn().mockResolvedValue(booking) },
    bookingTransitionHistory: {
      findFirst: jest.fn().mockResolvedValue({ createdAt: completedAt }),
    },
    review: {
      findUnique: reviewFindUnique,
      create: jest.fn().mockResolvedValue(created),
      findFirst: jest.fn().mockResolvedValue(null),
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
    },
  };
  const prisma = {
    $transaction: jest.fn(<T>(callback: (client: typeof tx) => Promise<T>) =>
      callback(tx),
    ),
  };
  return {
    service: new ReviewsService(prisma as unknown as PrismaService),
    tx,
  };
}

describe('ReviewsService', () => {
  it('uses the completion transition for the 14-day publication deadline', async () => {
    const { service, tx } = createService();

    await expect(
      service.create('borrower-1', 'booking-1', dto, now),
    ).resolves.toMatchObject({
      author: 'SELF',
      rating: 5,
      published: false,
      publishAt: new Date(completedAt.getTime() + REVIEW_WINDOW_MS),
    });
    expect(tx.review.create).toHaveBeenCalledTimes(1);
    const createCalls = tx.review.create.mock.calls as unknown as Array<
      [{ data: Record<string, unknown> }]
    >;
    expect(createCalls[0]?.[0].data).toMatchObject({
      authorId: 'borrower-1',
      targetId: 'lender-1',
      authorRole: ReviewAuthorRole.BORROWER,
    });
  });

  it('rejects a review before the booking is completed', async () => {
    const { service, tx } = createService(BookingStatus.RETURNED);

    await expect(
      service.create('borrower-1', 'booking-1', dto, now),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.review.create).not.toHaveBeenCalled();
  });

  it('rejects submission after the server-derived review window', async () => {
    const { service, tx } = createService();
    const afterDeadline = new Date(
      completedAt.getTime() + REVIEW_WINDOW_MS + 1,
    );

    await expect(
      service.create('borrower-1', 'booking-1', dto, afterDeadline),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.review.create).not.toHaveBeenCalled();
  });
});
