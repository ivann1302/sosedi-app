const bookingMaxDays = 30;
const bookingHorizonDays = 90;

int inclusiveBookingDays(DateTime start, DateTime end) {
  final first = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  return last.difference(first).inDays + 1;
}

bool isAllowedBookingRange(DateTime start, DateTime end, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final first = DateTime(start.year, start.month, start.day);
  final days = inclusiveBookingDays(start, end);
  return !first.isBefore(today) &&
      first.difference(today).inDays <= bookingHorizonDays &&
      days >= 1 &&
      days <= bookingMaxDays;
}
