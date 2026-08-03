CREATE TYPE "CategoryListingPolicy" AS ENUM (
  'ALLOWED',
  'RESTRICTED',
  'PROHIBITED'
);

ALTER TABLE "categories"
  ADD COLUMN "listingPolicy" "CategoryListingPolicy" NOT NULL DEFAULT 'RESTRICTED',
  ADD COLUMN "safetyNotice" TEXT NOT NULL DEFAULT 'Категория требует отдельной проверки перед публикацией.';

UPDATE "categories"
SET
  "listingPolicy" = 'ALLOWED',
  "safetyNotice" = 'Перед передачей проверьте комплектность и исправность вещи.'
WHERE "isAllowedForListings" = true;

ALTER TABLE "categories"
  ADD CONSTRAINT "categories_listing_policy_allowed_check"
    CHECK (
      ("listingPolicy" = 'ALLOWED' AND "isAllowedForListings" = true)
      OR
      ("listingPolicy" <> 'ALLOWED' AND "isAllowedForListings" = false)
    ),
  ADD CONSTRAINT "categories_safety_notice_length_check"
    CHECK (char_length("safetyNotice") BETWEEN 10 AND 500);
