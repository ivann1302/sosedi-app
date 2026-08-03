-- Collapse the mutually exclusive prototype roles into one product role.
CREATE TYPE "UserRole_new" AS ENUM ('USER', 'ADMIN');
ALTER TABLE "users" ALTER COLUMN "role" DROP DEFAULT;
ALTER TABLE "users"
  ALTER COLUMN "role" TYPE "UserRole_new"
  USING (
    CASE
      WHEN "role"::text = 'ADMIN' THEN 'ADMIN'
      ELSE 'USER'
    END
  )::"UserRole_new";
DROP TYPE "UserRole";
ALTER TYPE "UserRole_new" RENAME TO "UserRole";
ALTER TABLE "users" ALTER COLUMN "role" SET DEFAULT 'USER';

-- Existing prototype categories remain visible to administrators but cannot
-- receive new listings until a launch-whitelist seed explicitly allows them.
ALTER TABLE "categories"
  ADD COLUMN "isAllowedForListings" BOOLEAN NOT NULL DEFAULT false;

CREATE TYPE "ItemCondition" AS ENUM ('NEW', 'LIKE_NEW', 'GOOD', 'FAIR');
ALTER TABLE "items"
  ADD COLUMN "condition" "ItemCondition" NOT NULL DEFAULT 'GOOD',
  ADD COLUMN "completeness" TEXT NOT NULL DEFAULT 'Комплектация указана в описании',
  ADD COLUMN "handoverTerms" TEXT NOT NULL DEFAULT 'Личная передача по договорённости';
ALTER TABLE "items" ALTER COLUMN "condition" DROP DEFAULT;
ALTER TABLE "items" ALTER COLUMN "completeness" DROP DEFAULT;
ALTER TABLE "items" ALTER COLUMN "handoverTerms" DROP DEFAULT;

ALTER TABLE "items"
  ADD CONSTRAINT "items_completeness_length_check"
    CHECK (char_length("completeness") BETWEEN 3 AND 1000),
  ADD CONSTRAINT "items_handover_terms_length_check"
    CHECK (char_length("handoverTerms") BETWEEN 3 AND 1000);

ALTER TABLE "bookings" RENAME COLUMN "renterId" TO "borrowerId";
ALTER TABLE "bookings" RENAME COLUMN "ownerId" TO "lenderId";
ALTER TABLE "bookings"
  RENAME CONSTRAINT "bookings_renterId_fkey" TO "bookings_borrowerId_fkey";
ALTER TABLE "bookings"
  RENAME CONSTRAINT "bookings_ownerId_fkey" TO "bookings_lenderId_fkey";
ALTER INDEX "bookings_renterId_idx" RENAME TO "bookings_borrowerId_idx";
ALTER INDEX "bookings_ownerId_idx" RENAME TO "bookings_lenderId_idx";
ALTER TABLE "bookings"
  ADD CONSTRAINT "bookings_borrower_not_lender_check"
    CHECK ("borrowerId" <> "lenderId");
