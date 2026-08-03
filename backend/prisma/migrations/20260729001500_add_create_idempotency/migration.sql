ALTER TABLE "items"
ADD COLUMN "clientRequestId" TEXT,
ADD COLUMN "clientRequestHash" TEXT;

ALTER TABLE "bookings"
ADD COLUMN "clientRequestId" TEXT,
ADD COLUMN "clientRequestHash" TEXT;

CREATE UNIQUE INDEX "items_ownerId_clientRequestId_key"
ON "items"("ownerId", "clientRequestId");

CREATE UNIQUE INDEX "bookings_borrowerId_clientRequestId_key"
ON "bookings"("borrowerId", "clientRequestId");
