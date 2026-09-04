-- Fake checkout persists the same one-checkout total as Booking. Keep the
-- broad storage ceiling aligned with 30 days at 1,000,000 RUB/day plus the
-- 30,000,000 RUB Item deposit storage ceiling; runtime policy is stricter.
ALTER TABLE "payments"
  DROP CONSTRAINT "payments_amount_range_check",
  ADD CONSTRAINT "payments_amount_range_check"
    CHECK ("amount" BETWEEN 1 AND 60000000) NOT VALID;
