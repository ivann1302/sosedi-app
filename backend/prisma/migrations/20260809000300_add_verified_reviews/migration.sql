CREATE TYPE "ReviewAuthorRole" AS ENUM ('BORROWER', 'LENDER');

CREATE TABLE "reviews" (
  "id" TEXT NOT NULL,
  "bookingId" TEXT NOT NULL,
  "authorId" TEXT,
  "targetId" TEXT NOT NULL,
  "authorRole" "ReviewAuthorRole" NOT NULL,
  "clientReviewId" TEXT,
  "rating" INTEGER NOT NULL,
  "text" VARCHAR(1000),
  "publishAt" TIMESTAMP(3) NOT NULL,
  "hiddenAt" TIMESTAMP(3),
  "hiddenById" TEXT,
  "hiddenReason" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "reviews_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "reviews_rating_range" CHECK ("rating" BETWEEN 1 AND 5),
  CONSTRAINT "reviews_text_length" CHECK (
    "text" IS NULL OR char_length("text") BETWEEN 10 AND 1000
  )
);

CREATE UNIQUE INDEX "reviews_bookingId_authorRole_key"
ON "reviews"("bookingId", "authorRole");

CREATE UNIQUE INDEX "reviews_authorId_clientReviewId_key"
ON "reviews"("authorId", "clientReviewId");

CREATE INDEX "reviews_targetId_publishAt_createdAt_id_idx"
ON "reviews"("targetId", "publishAt", "createdAt", "id");

CREATE INDEX "reviews_bookingId_createdAt_idx"
ON "reviews"("bookingId", "createdAt");

CREATE INDEX "reviews_authorId_idx" ON "reviews"("authorId");
CREATE INDEX "reviews_hiddenById_idx" ON "reviews"("hiddenById");

ALTER TABLE "reviews"
ADD CONSTRAINT "reviews_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "reviews"
ADD CONSTRAINT "reviews_authorId_fkey"
FOREIGN KEY ("authorId") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "reviews"
ADD CONSTRAINT "reviews_targetId_fkey"
FOREIGN KEY ("targetId") REFERENCES "users"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "reviews"
ADD CONSTRAINT "reviews_hiddenById_fkey"
FOREIGN KEY ("hiddenById") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
