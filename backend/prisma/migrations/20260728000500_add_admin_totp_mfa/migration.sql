CREATE TABLE "admin_mfa_credentials" (
  "userId" TEXT NOT NULL,
  "totpSecretEncrypted" TEXT NOT NULL,
  "lastTotpStep" INTEGER NOT NULL,
  "enabledAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "admin_mfa_credentials_pkey" PRIMARY KEY ("userId")
);

CREATE TABLE "admin_recovery_codes" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "codeHash" TEXT NOT NULL,
  "usedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "admin_recovery_codes_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "admin_recovery_codes_codeHash_key"
  ON "admin_recovery_codes"("codeHash");
CREATE INDEX "admin_recovery_codes_userId_usedAt_idx"
  ON "admin_recovery_codes"("userId", "usedAt");

ALTER TABLE "admin_mfa_credentials"
  ADD CONSTRAINT "admin_mfa_credentials_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "users"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "admin_recovery_codes"
  ADD CONSTRAINT "admin_recovery_codes_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "users"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
