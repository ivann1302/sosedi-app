CREATE TYPE "BookingActStage" AS ENUM ('HANDOVER', 'RETURN');

CREATE TABLE "booking_acts" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "stage" "BookingActStage" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "confirmedById" TEXT,
    "confirmedAt" TIMESTAMP(3),

    CONSTRAINT "booking_acts_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "booking_evidence" (
    "id" TEXT NOT NULL,
    "actId" TEXT NOT NULL,
    "uploadIntentId" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "sha256" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_evidence_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "booking_acts_bookingId_stage_key"
ON "booking_acts"("bookingId", "stage");
CREATE INDEX "booking_acts_authorId_idx" ON "booking_acts"("authorId");
CREATE INDEX "booking_acts_confirmedById_idx"
ON "booking_acts"("confirmedById");
CREATE UNIQUE INDEX "booking_evidence_uploadIntentId_key"
ON "booking_evidence"("uploadIntentId");
CREATE INDEX "booking_evidence_actId_idx" ON "booking_evidence"("actId");

ALTER TABLE "booking_acts"
ADD CONSTRAINT "booking_acts_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "booking_acts"
ADD CONSTRAINT "booking_acts_authorId_fkey"
FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "booking_acts"
ADD CONSTRAINT "booking_acts_confirmedById_fkey"
FOREIGN KEY ("confirmedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "booking_evidence"
ADD CONSTRAINT "booking_evidence_actId_fkey"
FOREIGN KEY ("actId") REFERENCES "booking_acts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "booking_evidence"
ADD CONSTRAINT "booking_evidence_uploadIntentId_fkey"
FOREIGN KEY ("uploadIntentId") REFERENCES "upload_intents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
