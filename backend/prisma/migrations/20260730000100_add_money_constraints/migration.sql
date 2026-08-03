-- Keep the provisional PAY_ON_HANDOVER money boundary safe even when a write
-- bypasses HTTP DTO validation. Online payment schema remains gated by ADR.
ALTER TABLE "items"
  ADD CONSTRAINT "items_price_per_day_range_check"
    CHECK ("pricePerDay" BETWEEN 1 AND 1000000) NOT VALID,
  ADD CONSTRAINT "items_deposit_pilot_check"
    CHECK ("depositAmount" IS NULL OR "depositAmount" = 0) NOT VALID;

ALTER TABLE "bookings"
  ADD CONSTRAINT "bookings_total_amount_range_check"
    CHECK ("totalAmount" BETWEEN 1 AND 30000000) NOT VALID;

ALTER TABLE "payments"
  ADD CONSTRAINT "payments_amount_range_check"
    CHECK ("amount" BETWEEN 1 AND 30000000) NOT VALID;
