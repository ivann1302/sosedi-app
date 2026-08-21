CREATE TYPE "BookingMessageAuthorRole" AS ENUM (
    'BORROWER',
    'LENDER',
    'SYSTEM'
);

CREATE TABLE "booking_messages" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "authorId" TEXT,
    "authorRole" "BookingMessageAuthorRole" NOT NULL,
    "clientMessageId" TEXT,
    "body" VARCHAR(2000) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_messages_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "booking_messages_authorId_clientMessageId_key"
ON "booking_messages"("authorId", "clientMessageId");

CREATE INDEX "booking_messages_bookingId_createdAt_id_idx"
ON "booking_messages"("bookingId", "createdAt", "id");

CREATE INDEX "booking_messages_authorId_idx"
ON "booking_messages"("authorId");

ALTER TABLE "booking_messages"
ADD CONSTRAINT "booking_messages_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "booking_messages"
ADD CONSTRAINT "booking_messages_authorId_fkey"
FOREIGN KEY ("authorId") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
