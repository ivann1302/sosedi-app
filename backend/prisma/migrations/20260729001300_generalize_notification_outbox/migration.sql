ALTER TABLE "booking_outbox_events"
RENAME TO "notification_outbox_events";

ALTER TABLE "notification_outbox_events"
ALTER COLUMN "bookingId" DROP NOT NULL,
ADD COLUMN "supportTicketId" TEXT;

ALTER TABLE "inbox_events"
ALTER COLUMN "bookingId" DROP NOT NULL,
ADD COLUMN "supportTicketId" TEXT;

CREATE INDEX "notification_outbox_events_supportTicketId_idx"
ON "notification_outbox_events"("supportTicketId");
CREATE INDEX "inbox_events_supportTicketId_idx"
ON "inbox_events"("supportTicketId");

ALTER TABLE "notification_outbox_events"
ADD CONSTRAINT "notification_outbox_events_supportTicketId_fkey"
FOREIGN KEY ("supportTicketId") REFERENCES "support_tickets"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "inbox_events"
ADD CONSTRAINT "inbox_events_supportTicketId_fkey"
FOREIGN KEY ("supportTicketId") REFERENCES "support_tickets"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "notification_outbox_events"
ADD CONSTRAINT "notification_outbox_events_one_entity"
CHECK (
  (CASE WHEN "bookingId" IS NULL THEN 0 ELSE 1 END) +
  (CASE WHEN "supportTicketId" IS NULL THEN 0 ELSE 1 END) = 1
);
ALTER TABLE "inbox_events"
ADD CONSTRAINT "inbox_events_one_entity"
CHECK (
  (CASE WHEN "bookingId" IS NULL THEN 0 ELSE 1 END) +
  (CASE WHEN "supportTicketId" IS NULL THEN 0 ELSE 1 END) = 1
);
