DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM "bookings" WHERE "status"::text = 'PAID') THEN
    RAISE EXCEPTION 'Cannot remove BookingStatus.PAID while rows still use it';
  END IF;
END
$$;

ALTER TABLE "bookings" ALTER COLUMN "status" DROP DEFAULT;
CREATE TYPE "BookingStatus_next" AS ENUM (
  'PENDING',
  'CONFIRMED',
  'ACTIVE',
  'RETURNED',
  'COMPLETED',
  'CANCELLED'
);
ALTER TABLE "bookings"
  ALTER COLUMN "status" TYPE "BookingStatus_next"
  USING ("status"::text::"BookingStatus_next");
DROP TYPE "BookingStatus";
ALTER TYPE "BookingStatus_next" RENAME TO "BookingStatus";
ALTER TABLE "bookings" ALTER COLUMN "status" SET DEFAULT 'PENDING';

ALTER TYPE "PaymentStatus" RENAME VALUE 'CANCELED' TO 'CANCELLED';

CREATE TYPE "PayoutStatus" AS ENUM (
  'PENDING',
  'PROCESSING',
  'SUCCEEDED',
  'FAILED',
  'CANCELLED'
);

CREATE TYPE "DisputeStatus" AS ENUM (
  'OPEN',
  'UNDER_REVIEW',
  'RESOLVED'
);
