ALTER TABLE "admin_audit_logs"
  ADD COLUMN "capability" "AdminCapability",
  ADD COLUMN "reason" TEXT,
  ADD COLUMN "requestId" TEXT,
  ADD COLUMN "deviceId" TEXT,
  ADD COLUMN "before" JSONB,
  ADD COLUMN "after" JSONB;

CREATE OR REPLACE FUNCTION prevent_admin_audit_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'admin_audit_logs is append-only'
    USING ERRCODE = '55000';
END;
$$;

CREATE TRIGGER admin_audit_logs_append_only
BEFORE UPDATE OR DELETE ON "admin_audit_logs"
FOR EACH ROW EXECUTE FUNCTION prevent_admin_audit_mutation();
