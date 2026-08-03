ALTER TABLE "items"
  ADD COLUMN "listingRulesVersion" TEXT,
  ADD COLUMN "listingRulesAcceptedAt" TIMESTAMP(3),
  ADD COLUMN "listingRulesAcceptanceMethod" TEXT,
  ADD COLUMN "safetyNoticeSnapshot" TEXT;

ALTER TABLE "items"
  ADD CONSTRAINT "items_listing_rules_acceptance_check"
    CHECK (
      (
        "listingRulesVersion" IS NULL
        AND "listingRulesAcceptedAt" IS NULL
        AND "listingRulesAcceptanceMethod" IS NULL
        AND "safetyNoticeSnapshot" IS NULL
      )
      OR
      (
        char_length("listingRulesVersion") BETWEEN 1 AND 64
        AND "listingRulesAcceptedAt" IS NOT NULL
        AND "listingRulesAcceptanceMethod" = 'ITEM_CREATE_FORM'
        AND char_length("safetyNoticeSnapshot") BETWEEN 10 AND 500
      )
    );
