CREATE TABLE "booking_outbox_events" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "deduplicationKey" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMP(3),

    CONSTRAINT "booking_outbox_events_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "inbox_events" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "recipientId" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inbox_events_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "booking_outbox_events_deduplicationKey_key"
ON "booking_outbox_events"("deduplicationKey");
CREATE INDEX "booking_outbox_events_processedAt_createdAt_idx"
ON "booking_outbox_events"("processedAt", "createdAt");
CREATE INDEX "booking_outbox_events_bookingId_idx"
ON "booking_outbox_events"("bookingId");

CREATE UNIQUE INDEX "inbox_events_eventId_recipientId_key"
ON "inbox_events"("eventId", "recipientId");
CREATE INDEX "inbox_events_recipientId_createdAt_idx"
ON "inbox_events"("recipientId", "createdAt");
CREATE INDEX "inbox_events_bookingId_idx"
ON "inbox_events"("bookingId");

ALTER TABLE "booking_outbox_events"
ADD CONSTRAINT "booking_outbox_events_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "inbox_events"
ADD CONSTRAINT "inbox_events_eventId_fkey"
FOREIGN KEY ("eventId") REFERENCES "booking_outbox_events"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "inbox_events"
ADD CONSTRAINT "inbox_events_recipientId_fkey"
FOREIGN KEY ("recipientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "inbox_events"
ADD CONSTRAINT "inbox_events_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
