CREATE TABLE "item_unavailable_periods" (
    "id" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,
    "startDate" DATE NOT NULL,
    "endDate" DATE NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "item_unavailable_periods_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "item_unavailable_periods_dates_check" CHECK ("startDate" <= "endDate")
);

CREATE UNIQUE INDEX "item_unavailable_periods_itemId_startDate_endDate_key"
ON "item_unavailable_periods"("itemId", "startDate", "endDate");

CREATE INDEX "item_unavailable_periods_itemId_startDate_endDate_idx"
ON "item_unavailable_periods"("itemId", "startDate", "endDate");

ALTER TABLE "item_unavailable_periods"
ADD CONSTRAINT "item_unavailable_periods_itemId_fkey"
FOREIGN KEY ("itemId") REFERENCES "items"("id") ON DELETE CASCADE ON UPDATE CASCADE;
