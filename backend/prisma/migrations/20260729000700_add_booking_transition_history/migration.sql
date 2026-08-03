CREATE TABLE "booking_transition_history" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "actorId" TEXT,
    "actorType" TEXT NOT NULL,
    "command" TEXT NOT NULL,
    "oldStatus" "BookingStatus",
    "newStatus" "BookingStatus" NOT NULL,
    "reason" TEXT,
    "requestId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_transition_history_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "booking_transition_history_bookingId_createdAt_idx"
ON "booking_transition_history"("bookingId", "createdAt");
CREATE INDEX "booking_transition_history_actorId_idx"
ON "booking_transition_history"("actorId");
CREATE INDEX "booking_transition_history_requestId_idx"
ON "booking_transition_history"("requestId");

ALTER TABLE "booking_transition_history"
ADD CONSTRAINT "booking_transition_history_bookingId_fkey"
FOREIGN KEY ("bookingId") REFERENCES "bookings"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "booking_transition_history"
ADD CONSTRAINT "booking_transition_history_actorId_fkey"
FOREIGN KEY ("actorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

CREATE OR REPLACE FUNCTION prevent_booking_transition_history_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'booking_transition_history is append-only'
    USING ERRCODE = '55000';
END;
$$;

CREATE TRIGGER booking_transition_history_append_only
BEFORE UPDATE OR DELETE ON "booking_transition_history"
FOR EACH ROW EXECUTE FUNCTION prevent_booking_transition_history_mutation();
