-- A Booking can combine the broad Item storage ceilings: 30 days at
-- 1,000,000 RUB/day plus a 30,000,000 RUB deposit. Application policy is
-- deliberately stricter, but the database ceiling must preserve that range.
ALTER TABLE "bookings"
  DROP CONSTRAINT "bookings_total_amount_range_check",
  ADD CONSTRAINT "bookings_total_amount_range_check"
    CHECK ("totalAmount" BETWEEN 1 AND 60000000) NOT VALID;
