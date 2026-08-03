ALTER TABLE "support_tickets"
DROP CONSTRAINT "support_tickets_booking_issue_pair";

ALTER TABLE "support_tickets"
ADD CONSTRAINT "support_tickets_booking_issue_pair"
CHECK (
  (
    "type" = 'GENERAL' AND (
      ("bookingId" IS NULL AND "bookingIssueReason" IS NULL) OR
      ("bookingId" IS NOT NULL AND "bookingIssueReason" IS NOT NULL)
    )
  ) OR (
    "type" = 'DISPUTE' AND
    "bookingId" IS NOT NULL AND
    "bookingIssueReason" IS NULL
  )
);
