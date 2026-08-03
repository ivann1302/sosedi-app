import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/booking_models.dart';
import '../data/booking_service.dart';

final bookingAvailabilityProvider =
    AsyncNotifierProvider<BookingAvailabilityController, ItemAvailability?>(
      BookingAvailabilityController.new,
      retry: (_, _) => null,
    );

class BookingAvailabilityController extends AsyncNotifier<ItemAvailability?> {
  @override
  Future<ItemAvailability?> build() async => null;

  Future<void> check({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(bookingServiceProvider)
          .checkAvailability(
            itemId: itemId,
            startDate: startDate,
            endDate: endDate,
          ),
    );
  }
}
