CREATE TYPE "ReportTargetType" AS ENUM ('ITEM', 'USER', 'BOOKING');
CREATE TYPE "ReportReason" AS ENUM (
  'PROHIBITED_CATEGORY',
  'MISLEADING_LISTING',
  'UNSAFE_ITEM',
  'SUSPECTED_FRAUD',
  'HARASSMENT',
  'IMPERSONATION',
  'PRIVACY_VIOLATION',
  'NO_SHOW',
  'UNSAFE_HANDOVER',
  'ITEM_NOT_AS_DESCRIBED',
  'OTHER'
);
CREATE TYPE "ReportStatus" AS ENUM ('OPEN', 'DISMISSED', 'ACTIONED');

CREATE TABLE "user_reports" (
    "id" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "targetType" "ReportTargetType" NOT NULL,
    "targetId" TEXT NOT NULL,
    "reason" "ReportReason" NOT NULL,
    "description" TEXT NOT NULL,
    "status" "ReportStatus" NOT NULL DEFAULT 'OPEN',
    "reviewedById" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "decision" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_reports_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "user_reports_reporterId_createdAt_idx"
ON "user_reports"("reporterId", "createdAt");
CREATE INDEX "user_reports_targetType_targetId_idx"
ON "user_reports"("targetType", "targetId");
CREATE INDEX "user_reports_status_createdAt_idx"
ON "user_reports"("status", "createdAt");
CREATE INDEX "user_reports_reviewedById_idx"
ON "user_reports"("reviewedById");

ALTER TABLE "user_reports"
ADD CONSTRAINT "user_reports_reporterId_fkey"
FOREIGN KEY ("reporterId") REFERENCES "users"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "user_reports"
ADD CONSTRAINT "user_reports_reviewedById_fkey"
FOREIGN KEY ("reviewedById") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
