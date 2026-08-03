ALTER TABLE "support_tickets"
ADD COLUMN "assigneeId" TEXT;

CREATE INDEX "support_tickets_assigneeId_idx"
ON "support_tickets"("assigneeId");

ALTER TABLE "support_tickets"
ADD CONSTRAINT "support_tickets_assigneeId_fkey"
FOREIGN KEY ("assigneeId") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
