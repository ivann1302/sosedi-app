import { BookingStatus } from '@prisma/client';
import { bookingNextAction } from './booking-next-action';

describe('bookingNextAction', () => {
  it.each([
    [BookingStatus.PENDING, 'BORROWER', 'WAIT_LENDER'],
    [BookingStatus.PENDING, 'LENDER', 'REVIEW_REQUEST'],
    [BookingStatus.CONFIRMED, 'BORROWER', 'PREPARE_HANDOVER'],
    [BookingStatus.ACTIVE, 'LENDER', 'WAIT_RETURN'],
    [BookingStatus.RETURNED, 'LENDER', 'REVIEW_RETURN'],
    [BookingStatus.COMPLETED, 'BORROWER', 'LEAVE_REVIEW'],
    [BookingStatus.CANCELLED, 'BORROWER', 'NONE'],
  ] as const)(
    'derives %s/%s without a mobile-side state machine',
    (status, actorRole, code) => {
      expect(bookingNextAction(status, actorRole)).toMatchObject({ code });
    },
  );
});
