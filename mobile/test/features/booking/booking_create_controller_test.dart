import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/marketplace_documents_config.dart';
import 'package:mobile/features/booking/data/booking_service.dart';
import 'package:mobile/features/booking/domain/booking_create_controller.dart';

void main() {
  test('reuses a request ID only for the same booking payload retry', () async {
    final service = _RetryCreateBookingService();
    final container = ProviderContainer(
      overrides: [bookingServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      bookingCreateProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(bookingCreateProvider.future);
    final controller = container.read(bookingCreateProvider.notifier);

    await controller.submit(
      itemId: 'item-1',
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 2),
      terms: terms,
    );
    await controller.submit(
      itemId: 'item-1',
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 2),
      terms: terms,
    );
    await controller.submit(
      itemId: 'item-1',
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 3),
      terms: terms,
    );

    expect(service.requestIds[0], service.requestIds[1]);
    expect(service.requestIds[2], isNot(service.requestIds[1]));
  });
}

const terms = MarketplaceDocumentsConfig(
  offerVersion: '2026-08-01.1',
  offerUrl: 'https://docs.sosedi.ru/documents/offer/2026-08-01.1/',
  cancellationPolicyVersion: '2026-08-01.2',
  rentalRulesUrl:
      'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.2/',
  privacyVersion: '2026-08-01.3',
  privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
);

class _RetryCreateBookingService extends BookingService {
  _RetryCreateBookingService() : super(Dio());

  final requestIds = <String>[];

  @override
  Future<String> create({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
    required String offerVersion,
    required String cancellationPolicyVersion,
    required String requestId,
  }) async {
    requestIds.add(requestId);
    if (requestIds.length == 1) {
      throw Exception('offline');
    }
    return 'booking-${requestIds.length}';
  }
}
