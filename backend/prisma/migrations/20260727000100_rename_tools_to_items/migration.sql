-- Rename the prototype domain in place so existing listings, photos, and bookings
-- keep their identifiers and relationships.
ALTER TYPE "ToolStatus" RENAME TO "ItemStatus";

ALTER TABLE "tools" RENAME TO "items";
ALTER TABLE "tool_photos" RENAME TO "item_photos";

ALTER TABLE "item_photos" RENAME COLUMN "toolId" TO "itemId";
ALTER TABLE "bookings" RENAME COLUMN "toolId" TO "itemId";

ALTER TABLE "items" RENAME CONSTRAINT "tools_pkey" TO "items_pkey";
ALTER TABLE "items" RENAME CONSTRAINT "tools_ownerId_fkey" TO "items_ownerId_fkey";
ALTER TABLE "items" RENAME CONSTRAINT "tools_categoryId_fkey" TO "items_categoryId_fkey";
ALTER TABLE "items" RENAME CONSTRAINT "tools_latitude_check" TO "items_latitude_check";
ALTER TABLE "items" RENAME CONSTRAINT "tools_longitude_check" TO "items_longitude_check";
ALTER TABLE "items" RENAME CONSTRAINT "tools_public_area_length_check" TO "items_public_area_length_check";
ALTER TABLE "item_photos" RENAME CONSTRAINT "tool_photos_pkey" TO "item_photos_pkey";
ALTER TABLE "item_photos" RENAME CONSTRAINT "tool_photos_toolId_fkey" TO "item_photos_itemId_fkey";
ALTER TABLE "bookings" RENAME CONSTRAINT "bookings_toolId_fkey" TO "bookings_itemId_fkey";

ALTER INDEX "tools_ownerId_idx" RENAME TO "items_ownerId_idx";
ALTER INDEX "tools_categoryId_idx" RENAME TO "items_categoryId_idx";
ALTER INDEX "tools_status_idx" RENAME TO "items_status_idx";
ALTER INDEX "tools_pricePerDay_idx" RENAME TO "items_pricePerDay_idx";
ALTER INDEX "tools_createdAt_idx" RENAME TO "items_createdAt_idx";
ALTER INDEX "tools_location_idx" RENAME TO "items_location_idx";
ALTER INDEX "tool_photos_toolId_idx" RENAME TO "item_photos_itemId_idx";
ALTER INDEX "tool_photos_toolId_sortOrder_idx" RENAME TO "item_photos_itemId_sortOrder_idx";
ALTER INDEX "bookings_toolId_idx" RENAME TO "bookings_itemId_idx";

ALTER FUNCTION update_tool_location() RENAME TO update_item_location;
ALTER TRIGGER "tools_update_location" ON "items" RENAME TO "items_update_location";
