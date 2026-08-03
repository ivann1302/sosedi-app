CREATE TYPE "SupportMessageAuthorRole" AS ENUM ('USER', 'SUPPORT');

CREATE TABLE "support_messages" (
    "id" TEXT NOT NULL,
    "ticketId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "authorRole" "SupportMessageAuthorRole" NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "support_messages_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "support_attachments" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "uploadIntentId" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "sha256" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "support_attachments_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "support_messages_ticketId_createdAt_idx"
ON "support_messages"("ticketId", "createdAt");
CREATE INDEX "support_messages_authorId_idx"
ON "support_messages"("authorId");
CREATE UNIQUE INDEX "support_attachments_uploadIntentId_key"
ON "support_attachments"("uploadIntentId");
CREATE INDEX "support_attachments_messageId_idx"
ON "support_attachments"("messageId");

ALTER TABLE "support_messages"
ADD CONSTRAINT "support_messages_ticketId_fkey"
FOREIGN KEY ("ticketId") REFERENCES "support_tickets"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "support_messages"
ADD CONSTRAINT "support_messages_authorId_fkey"
FOREIGN KEY ("authorId") REFERENCES "users"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "support_attachments"
ADD CONSTRAINT "support_attachments_messageId_fkey"
FOREIGN KEY ("messageId") REFERENCES "support_messages"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "support_attachments"
ADD CONSTRAINT "support_attachments_uploadIntentId_fkey"
FOREIGN KEY ("uploadIntentId") REFERENCES "upload_intents"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;
