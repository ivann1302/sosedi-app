ALTER TABLE "bookings"
ADD COLUMN "expiresAt" TIMESTAMP(3);

CREATE INDEX "bookings_expiresAt_idx" ON "bookings"("expiresAt");
