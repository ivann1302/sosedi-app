ALTER TABLE "booking_acts"
ADD COLUMN "readinessIsWorking" BOOLEAN,
ADD COLUMN "readinessIsComplete" BOOLEAN,
ADD COLUMN "readinessVisibleDefects" TEXT,
ADD COLUMN "readinessDeclaredAt" TIMESTAMP(3);

ALTER TABLE "booking_acts"
ADD CONSTRAINT "booking_acts_readiness_stage_check"
CHECK (
  (
    "stage" = 'HANDOVER'
    AND (
      (
        "readinessIsWorking" IS NULL
        AND "readinessIsComplete" IS NULL
        AND "readinessVisibleDefects" IS NULL
        AND "readinessDeclaredAt" IS NULL
      )
      OR (
        "readinessIsWorking" IS TRUE
        AND "readinessIsComplete" IS TRUE
        AND "readinessVisibleDefects" IS NOT NULL
        AND length(btrim("readinessVisibleDefects")) BETWEEN 2 AND 500
        AND "readinessDeclaredAt" IS NOT NULL
      )
    )
  )
  OR (
    "stage" = 'RETURN'
    AND "readinessIsWorking" IS NULL
    AND "readinessIsComplete" IS NULL
    AND "readinessVisibleDefects" IS NULL
    AND "readinessDeclaredAt" IS NULL
  )
);

CREATE FUNCTION prevent_booking_act_readiness_update()
RETURNS trigger AS $$
BEGIN
  IF NEW."readinessIsWorking" IS DISTINCT FROM OLD."readinessIsWorking"
    OR NEW."readinessIsComplete" IS DISTINCT FROM OLD."readinessIsComplete"
    OR NEW."readinessVisibleDefects" IS DISTINCT FROM OLD."readinessVisibleDefects"
    OR NEW."readinessDeclaredAt" IS DISTINCT FROM OLD."readinessDeclaredAt" THEN
    RAISE EXCEPTION 'booking act readiness is append-only';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER booking_act_readiness_append_only
BEFORE UPDATE ON "booking_acts"
FOR EACH ROW EXECUTE FUNCTION prevent_booking_act_readiness_update();
