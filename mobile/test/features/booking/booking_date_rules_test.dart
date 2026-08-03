import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/booking/domain/booking_date_rules.dart';

void main() {
  test('uses inclusive days and enforces MVP date bounds', () {
    final today = DateTime(2026, 7, 29);

    expect(inclusiveBookingDays(today, today), 1);
    expect(
      inclusiveBookingDays(today, today.add(const Duration(days: 29))),
      30,
    );
    expect(
      isAllowedBookingRange(today, today.add(const Duration(days: 29)), today),
      isTrue,
    );
    expect(
      isAllowedBookingRange(today, today.add(const Duration(days: 30)), today),
      isFalse,
    );
    expect(
      isAllowedBookingRange(
        today.add(const Duration(days: 91)),
        today.add(const Duration(days: 91)),
        today,
      ),
      isFalse,
    );
  });
}
