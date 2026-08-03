ALTER TABLE "notification_outbox_events"
  RENAME CONSTRAINT "booking_outbox_events_pkey"
  TO "notification_outbox_events_pkey";

ALTER TABLE "notification_outbox_events"
  RENAME CONSTRAINT "booking_outbox_events_bookingId_fkey"
  TO "notification_outbox_events_bookingId_fkey";

ALTER INDEX "booking_outbox_events_bookingId_idx"
  RENAME TO "notification_outbox_events_bookingId_idx";

ALTER INDEX "booking_outbox_events_deduplicationKey_key"
  RENAME TO "notification_outbox_events_deduplicationKey_key";

ALTER INDEX "booking_outbox_events_processedAt_createdAt_idx"
  RENAME TO "notification_outbox_events_processedAt_createdAt_idx";
