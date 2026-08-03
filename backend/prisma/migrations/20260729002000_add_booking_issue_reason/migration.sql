CREATE TYPE "BookingIssueReason" AS ENUM (
  'OWNER_NO_SHOW',
  'BORROWER_NO_SHOW',
  'ITEM_FAULTY',
  'EARLY_RETURN',
  'LATE_RETURN',
  'ITEM_DAMAGED',
  'ITEM_LOST'
);

ALTER TABLE "support_tickets"
ADD COLUMN "bookingIssueReason" "BookingIssueReason";

CREATE INDEX "support_tickets_bookingIssueReason_idx"
ON "support_tickets"("bookingIssueReason");

ALTER TABLE "support_tickets"
ADD CONSTRAINT "support_tickets_booking_issue_pair"
CHECK (
  ("bookingId" IS NULL AND "bookingIssueReason" IS NULL) OR
  ("bookingId" IS NOT NULL AND "bookingIssueReason" IS NOT NULL)
);
