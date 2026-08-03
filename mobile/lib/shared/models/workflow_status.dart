enum BookingStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  active('ACTIVE'),
  returned('RETURNED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const BookingStatus(this.wireValue);
  final String wireValue;
}

enum PaymentStatus {
  pending('PENDING'),
  succeeded('SUCCEEDED'),
  failed('FAILED'),
  cancelled('CANCELLED');

  const PaymentStatus(this.wireValue);
  final String wireValue;
}

enum PayoutStatus {
  pending('PENDING'),
  processing('PROCESSING'),
  succeeded('SUCCEEDED'),
  failed('FAILED'),
  cancelled('CANCELLED');

  const PayoutStatus(this.wireValue);
  final String wireValue;
}

enum DisputeStatus {
  open('OPEN'),
  underReview('UNDER_REVIEW'),
  resolved('RESOLVED');

  const DisputeStatus(this.wireValue);
  final String wireValue;
}
