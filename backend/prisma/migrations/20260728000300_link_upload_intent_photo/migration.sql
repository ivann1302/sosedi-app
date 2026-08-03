ALTER TABLE "item_photos"
ADD COLUMN "uploadIntentId" TEXT;

CREATE UNIQUE INDEX "item_photos_uploadIntentId_key"
ON "item_photos"("uploadIntentId");
