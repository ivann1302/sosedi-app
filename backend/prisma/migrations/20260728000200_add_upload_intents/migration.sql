CREATE TABLE "upload_intents" (
  "id" TEXT NOT NULL,
  "actorId" TEXT NOT NULL,
  "purpose" TEXT NOT NULL,
  "entityId" TEXT NOT NULL,
  "bucket" TEXT NOT NULL,
  "objectKey" TEXT NOT NULL,
  "contentType" TEXT NOT NULL,
  "sizeBytes" INTEGER NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "confirmedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "upload_intents_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "upload_intents_objectKey_key"
  ON "upload_intents"("objectKey");
CREATE INDEX "upload_intents_actorId_idx"
  ON "upload_intents"("actorId");
CREATE INDEX "upload_intents_entityId_idx"
  ON "upload_intents"("entityId");
CREATE INDEX "upload_intents_expiresAt_idx"
  ON "upload_intents"("expiresAt");

ALTER TABLE "upload_intents"
  ADD CONSTRAINT "upload_intents_actorId_fkey"
  FOREIGN KEY ("actorId") REFERENCES "users"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
