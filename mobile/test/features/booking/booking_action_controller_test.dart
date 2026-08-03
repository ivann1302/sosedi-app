import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/booking/data/booking_service.dart';
import 'package:mobile/features/booking/domain/booking_action_controller.dart';

void main() {
  test('reuses the command request ID after an ambiguous failure', () async {
    final service = _RetryBookingService();
    final container = ProviderContainer(
      overrides: [bookingServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(bookingActionProvider.future);
    final controller = container.read(bookingActionProvider.notifier);

    await controller.confirm('booking-1');
    await controller.confirm('booking-1');

    expect(service.requestIds, hasLength(2));
    expect(service.requestIds.first, service.requestIds.last);
  });
}

class _RetryBookingService extends BookingService {
  _RetryBookingService() : super(Dio());

  final requestIds = <String>[];

  @override
  Future<void> confirm(String id, {required String requestId}) async {
    requestIds.add(requestId);
    if (requestIds.length == 1) {
      throw Exception('offline after commit');
    }
  }
}
