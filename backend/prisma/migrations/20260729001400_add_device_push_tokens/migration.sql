CREATE TYPE "PushTokenProvider" AS ENUM ('FCM', 'RUSTORE');
CREATE TYPE "PushPlatform" AS ENUM ('ANDROID', 'IOS');

CREATE TABLE "device_push_tokens" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "installationId" TEXT NOT NULL,
    "provider" "PushTokenProvider" NOT NULL,
    "platform" "PushPlatform" NOT NULL,
    "token" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "device_push_tokens_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "device_push_tokens_rustore_android"
      CHECK ("provider" <> 'RUSTORE' OR "platform" = 'ANDROID')
);

CREATE UNIQUE INDEX "device_push_tokens_provider_token_key"
ON "device_push_tokens"("provider", "token");
CREATE UNIQUE INDEX "device_push_tokens_userId_installationId_provider_key"
ON "device_push_tokens"("userId", "installationId", "provider");
CREATE INDEX "device_push_tokens_userId_idx"
ON "device_push_tokens"("userId");

ALTER TABLE "device_push_tokens"
ADD CONSTRAINT "device_push_tokens_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
