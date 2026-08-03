ALTER TABLE "support_tickets"
ADD COLUMN "adminResponse" TEXT,
ADD COLUMN "respondedById" TEXT,
ADD COLUMN "respondedAt" TIMESTAMP(3);

CREATE INDEX "support_tickets_respondedById_idx"
ON "support_tickets"("respondedById");

ALTER TABLE "support_tickets"
ADD CONSTRAINT "support_tickets_respondedById_fkey"
FOREIGN KEY ("respondedById") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
