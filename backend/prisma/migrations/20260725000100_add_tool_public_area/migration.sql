-- Public API exposes this moderated district/area label instead of the pickup address.
ALTER TABLE "tools" ADD COLUMN "publicArea" TEXT;

-- Existing approved listings stay private-safe until an owner/admin supplies a district.
UPDATE "tools" SET "publicArea" = 'Район не указан';

ALTER TABLE "tools" ALTER COLUMN "publicArea" SET NOT NULL;
ALTER TABLE "tools"
    ADD CONSTRAINT "tools_public_area_length_check"
    CHECK (char_length("publicArea") BETWEEN 2 AND 120);
