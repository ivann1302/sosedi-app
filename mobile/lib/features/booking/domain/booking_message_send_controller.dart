import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/identifiers/uuid_v4.dart';
import '../../notifications/data/inbox_service.dart';
import '../../notifications/domain/inbox_controller.dart';
import '../data/booking_models.dart';
import '../data/booking_service.dart';

final bookingMessageSendProvider =
    AsyncNotifierProvider<BookingMessageSendController, BookingMessage?>(
      BookingMessageSendController.new,
      retry: (_, _) => null,
    );

class BookingMessageSendController extends AsyncNotifier<BookingMessage?> {
  String? _draftKey;
  String? _clientMessageId;

  @override
  Future<BookingMessage?> build() async => null;

  Future<bool> send({required String bookingId, required String body}) async {
    if (state.isLoading) {
      return false;
    }
    final normalized = body.trim();
    final draftKey = '$bookingId:$normalized';
    if (_draftKey != draftKey) {
      _draftKey = draftKey;
      _clientMessageId = generateUuidV4();
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(bookingServiceProvider)
          .sendMessage(
            bookingId: bookingId,
            body: normalized,
            clientMessageId: _clientMessageId!,
          ),
    );
    if (state.hasError) {
      return false;
    }
    _draftKey = null;
    _clientMessageId = null;
    ref.invalidate(bookingMessagesProvider(bookingId));
    ref.invalidate(inboxEventsProvider);
    ref.invalidate(inboxControllerProvider);
    return true;
  }
}
