CREATE TYPE "PushDeliveryStatus" AS ENUM (
  'PENDING',
  'PROCESSING',
  'RETRY',
  'DELIVERED'
);

CREATE TABLE "push_deliveries" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "tokenId" TEXT NOT NULL,
    "status" "PushDeliveryStatus" NOT NULL DEFAULT 'PENDING',
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "nextAttemptAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processingUntil" TIMESTAMP(3),
    "deliveredAt" TIMESTAMP(3),
    "lastErrorCode" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "push_deliveries_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "push_deliveries_eventId_tokenId_key"
ON "push_deliveries"("eventId", "tokenId");

CREATE INDEX "push_deliveries_status_nextAttemptAt_idx"
ON "push_deliveries"("status", "nextAttemptAt");

CREATE INDEX "push_deliveries_processingUntil_idx"
ON "push_deliveries"("processingUntil");

ALTER TABLE "push_deliveries"
ADD CONSTRAINT "push_deliveries_eventId_fkey"
FOREIGN KEY ("eventId") REFERENCES "notification_outbox_events"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "push_deliveries"
ADD CONSTRAINT "push_deliveries_tokenId_fkey"
FOREIGN KEY ("tokenId") REFERENCES "device_push_tokens"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
