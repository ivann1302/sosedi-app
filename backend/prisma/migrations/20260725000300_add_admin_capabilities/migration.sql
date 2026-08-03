CREATE TYPE "AdminCapability" AS ENUM (
  'MODERATION',
  'SUPPORT',
  'KYC_REVIEW',
  'FINANCE'
);

ALTER TABLE "users"
  ADD COLUMN "adminCapabilities" "AdminCapability"[]
  NOT NULL
  DEFAULT ARRAY[]::"AdminCapability"[];
