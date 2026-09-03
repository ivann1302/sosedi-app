ALTER TYPE "AdminCapability" ADD VALUE 'DISPUTE';

CREATE TYPE "DepositStatus" AS ENUM (
  'PENDING',
  'HELD',
  'DISPUTED',
  'RESOLVING',
  'RESOLVED',
  'CANCELLED'
);

CREATE TYPE "DepositOperationKind" AS ENUM (
  'HOLD',
  'CANCEL',
  'REFUND',
  'RELEASE_TO_LENDER'
);

CREATE TYPE "DepositOperationStatus" AS ENUM (
  'PENDING',
  'SUCCEEDED',
  'FAILED'
);

CREATE TYPE "FinancialDisputeReason" AS ENUM (
  'ITEM_DAMAGED',
  'ITEM_LOST',
  'OTHER'
);

ALTER TABLE "items"
  DROP CONSTRAINT "items_deposit_pilot_check",
  ADD CONSTRAINT "items_deposit_storage_range_check"
    CHECK ("depositAmount" IS NULL OR "depositAmount" BETWEEN 0 AND 30000000) NOT VALID;

CREATE TABLE "booking_deposits" (
  "id" TEXT NOT NULL,
  "bookingId" TEXT NOT NULL,
  "amount" DECIMAL(10,2) NOT NULL,
  "currency" TEXT NOT NULL DEFAULT 'RUB',
  "policyVersion" TEXT NOT NULL,
  "disputeWindowSeconds" INTEGER NOT NULL,
  "status" "DepositStatus" NOT NULL DEFAULT 'PENDING',
  "disputeWindowEndsAt" TIMESTAMP(3),
  "refundedAmount" DECIMAL(10,2) NOT NULL DEFAULT 0,
  "releasedToLenderAmount" DECIMAL(10,2) NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "booking_deposits_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "booking_deposits_currency_check" CHECK ("currency" = 'RUB'),
  CONSTRAINT "booking_deposits_amount_positive_check" CHECK ("amount" > 0),
  CONSTRAINT "booking_deposits_resolved_amounts_non_negative_check" CHECK (
    "refundedAmount" >= 0 AND "releasedToLenderAmount" >= 0
  ),
  CONSTRAINT "booking_deposits_resolution_not_excessive_check" CHECK (
    "refundedAmount" + "releasedToLenderAmount" <= "amount"
  ),
  CONSTRAINT "booking_deposits_resolved_exactly_check" CHECK (
    "status" <> 'RESOLVED' OR
    "refundedAmount" + "releasedToLenderAmount" = "amount"
  )
);

CREATE TABLE "deposit_operations" (
  "id" TEXT NOT NULL,
  "depositId" TEXT NOT NULL,
  "kind" "DepositOperationKind" NOT NULL,
  "amount" DECIMAL(10,2) NOT NULL,
  "status" "DepositOperationStatus" NOT NULL DEFAULT 'PENDING',
  "idempotencyKey" TEXT NOT NULL,
  "providerOperationId" TEXT,
  "retryOfId" TEXT,
  "providerErrorCode" TEXT,
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "nextAttemptAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "processingUntil" TIMESTAMP(3),
  "completedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "deposit_operations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "deposit_operations_amount_positive_check" CHECK ("amount" > 0)
);

CREATE TABLE "financial_disputes" (
  "id" TEXT NOT NULL,
  "bookingId" TEXT NOT NULL,
  "openedById" TEXT NOT NULL,
  "resolvedById" TEXT,
  "reason" "FinancialDisputeReason" NOT NULL,
  "description" VARCHAR(1000),
  "status" "DisputeStatus" NOT NULL DEFAULT 'OPEN',
  "decisionReason" VARCHAR(1000),
  "refundToBorrowerAmount" DECIMAL(10,2) NOT NULL DEFAULT 0,
  "releaseToLenderAmount" DECIMAL(10,2) NOT NULL DEFAULT 0,
  "openedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "resolvedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "financial_disputes_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "financial_disputes_resolution_amounts_non_negative_check" CHECK (
    "refundToBorrowerAmount" >= 0 AND "releaseToLenderAmount" >= 0
  )
);

CREATE TABLE "dispute_evidence" (
  "id" TEXT NOT NULL,
  "disputeId" TEXT NOT NULL,
  "uploadIntentId" TEXT NOT NULL,
  "storageKey" TEXT NOT NULL,
  "sha256" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "dispute_evidence_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "booking_deposits_bookingId_key"
ON "booking_deposits"("bookingId");
CREATE INDEX "booking_deposits_status_disputeWindowEndsAt_idx"
ON "booking_deposits"("status", "disputeWindowEndsAt");

CREATE UNIQUE INDEX "deposit_operations_idempotencyKey_key"
ON "deposit_operations"("idempotencyKey");
CREATE UNIQUE INDEX "deposit_operations_providerOperationId_key"
ON "deposit_operations"("providerOperationId");
CREATE INDEX "deposit_operations_depositId_createdAt_idx"
ON "deposit_operations"("depositId", "createdAt");
CREATE INDEX "deposit_operations_status_nextAttemptAt_processingUntil_idx"
ON "deposit_operations"("status", "nextAttemptAt", "processingUntil");
CREATE INDEX "deposit_operations_retryOfId_idx"
ON "deposit_operations"("retryOfId");

CREATE UNIQUE INDEX "financial_disputes_bookingId_key"
ON "financial_disputes"("bookingId");
CREATE INDEX "financial_disputes_status_openedAt_idx"
ON "financial_disputes"("status", "openedAt");
CREATE INDEX "financial_disputes_openedById_idx"
ON "financial_disputes"("openedById");
CREATE INDEX "financial_disputes_resolvedById_idx"
ON "financial_disputes"("resolvedById");

CREATE UNIQUE INDEX "dispute_evidence_uploadIntentId_key"
ON "dispute_evidence"("uploadIntentId");
CREATE INDEX "dispute_evidence_disputeId_idx"
ON "dispute_evidence"("disputeId");

ALTER TABLE "booking_deposits"
ADD CONSTRAINT "booking_deposits_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "deposit_operations"
ADD CONSTRAINT "deposit_operations_depositId_fkey"
FOREIGN KEY ("depositId") REFERENCES "booking_deposits"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "deposit_operations"
ADD CONSTRAINT "deposit_operations_retryOfId_fkey"
FOREIGN KEY ("retryOfId") REFERENCES "deposit_operations"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "financial_disputes"
ADD CONSTRAINT "financial_disputes_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "financial_disputes"
ADD CONSTRAINT "financial_disputes_openedById_fkey"
FOREIGN KEY ("openedById") REFERENCES "users"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "financial_disputes"
ADD CONSTRAINT "financial_disputes_resolvedById_fkey"
FOREIGN KEY ("resolvedById") REFERENCES "users"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "dispute_evidence"
ADD CONSTRAINT "dispute_evidence_disputeId_fkey"
FOREIGN KEY ("disputeId") REFERENCES "financial_disputes"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "dispute_evidence"
ADD CONSTRAINT "dispute_evidence_uploadIntentId_fkey"
FOREIGN KEY ("uploadIntentId") REFERENCES "upload_intents"("id")
ON DELETE RESTRICT ON UPDATE CASCADE;
