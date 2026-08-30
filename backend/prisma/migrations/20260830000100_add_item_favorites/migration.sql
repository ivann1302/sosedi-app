CREATE TABLE "favorites" (
    "userId" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favorites_pkey" PRIMARY KEY ("userId", "itemId")
);

CREATE INDEX "favorites_userId_createdAt_idx"
ON "favorites"("userId", "createdAt");

ALTER TABLE "favorites"
ADD CONSTRAINT "favorites_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "favorites"
ADD CONSTRAINT "favorites_itemId_fkey"
FOREIGN KEY ("itemId") REFERENCES "items"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
