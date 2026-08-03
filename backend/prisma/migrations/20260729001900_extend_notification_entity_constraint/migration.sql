ALTER TABLE "notification_outbox_events"
DROP CONSTRAINT "notification_outbox_events_one_entity";

ALTER TABLE "notification_outbox_events"
ADD CONSTRAINT "notification_outbox_events_one_entity"
CHECK (
  (CASE WHEN "bookingId" IS NULL THEN 0 ELSE 1 END) +
  (CASE WHEN "supportTicketId" IS NULL THEN 0 ELSE 1 END) +
  (CASE WHEN "itemId" IS NULL THEN 0 ELSE 1 END) = 1
);

ALTER TABLE "inbox_events"
DROP CONSTRAINT "inbox_events_one_entity";

ALTER TABLE "inbox_events"
ADD CONSTRAINT "inbox_events_one_entity"
CHECK (
  (CASE WHEN "bookingId" IS NULL THEN 0 ELSE 1 END) +
  (CASE WHEN "supportTicketId" IS NULL THEN 0 ELSE 1 END) +
  (CASE WHEN "itemId" IS NULL THEN 0 ELSE 1 END) = 1
);
