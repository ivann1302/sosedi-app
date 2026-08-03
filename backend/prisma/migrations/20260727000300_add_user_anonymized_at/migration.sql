ALTER TABLE "users"
  ADD COLUMN "anonymizedAt" TIMESTAMP(3);

CREATE INDEX "users_deletedAt_anonymizedAt_idx"
  ON "users"("deletedAt", "anonymizedAt");
