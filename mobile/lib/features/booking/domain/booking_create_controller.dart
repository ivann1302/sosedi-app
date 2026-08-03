import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/marketplace_documents_config.dart';
import '../../../core/identifiers/uuid_v4.dart';
import '../data/booking_service.dart';

final bookingCreateProvider =
    AsyncNotifierProvider.autoDispose<BookingCreateController, String?>(
      BookingCreateController.new,
      retry: (_, _) => null,
    );

class BookingCreateController extends AsyncNotifier<String?> {
  String? _payloadKey;
  String? _requestId;

  @override
  Future<String?> build() async => null;

  Future<void> submit({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
    required MarketplaceDocumentsConfig terms,
  }) async {
    if (state.isLoading) {
      return;
    }
    final payloadKey = [
      itemId,
      _date(startDate),
      _date(endDate),
      terms.offerVersion,
      terms.cancellationPolicyVersion,
    ].join('|');
    if (_payloadKey != payloadKey) {
      _payloadKey = payloadKey;
      _requestId = generateUuidV4();
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!terms.isBookingReady) {
        throw StateError('Marketplace terms are not approved');
      }
      final bookingId = await ref
          .read(bookingServiceProvider)
          .create(
            itemId: itemId,
            startDate: startDate,
            endDate: endDate,
            offerVersion: terms.offerVersion,
            cancellationPolicyVersion: terms.cancellationPolicyVersion,
            requestId: _requestId!,
          );
      ref.invalidate(myBookingsProvider);
      return bookingId;
    });
  }
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
