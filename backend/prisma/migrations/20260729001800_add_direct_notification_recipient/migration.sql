ALTER TABLE "notification_outbox_events"
ADD COLUMN "recipientId" TEXT,
ADD COLUMN "itemId" TEXT;

ALTER TABLE "inbox_events"
ADD COLUMN "itemId" TEXT;

CREATE INDEX "notification_outbox_events_recipientId_idx"
ON "notification_outbox_events"("recipientId");

CREATE INDEX "notification_outbox_events_itemId_idx"
ON "notification_outbox_events"("itemId");

CREATE INDEX "inbox_events_itemId_idx"
ON "inbox_events"("itemId");

ALTER TABLE "notification_outbox_events"
ADD CONSTRAINT "notification_outbox_events_recipientId_fkey"
FOREIGN KEY ("recipientId") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "notification_outbox_events"
ADD CONSTRAINT "notification_outbox_events_itemId_fkey"
FOREIGN KEY ("itemId") REFERENCES "items"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "inbox_events"
ADD CONSTRAINT "inbox_events_itemId_fkey"
FOREIGN KEY ("itemId") REFERENCES "items"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
