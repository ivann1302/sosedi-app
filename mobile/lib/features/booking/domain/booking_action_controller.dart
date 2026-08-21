import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/identifiers/uuid_v4.dart';
import '../data/booking_service.dart';
import '../data/booking_models.dart';

final bookingActionProvider =
    AsyncNotifierProvider<BookingActionController, String?>(
      BookingActionController.new,
      retry: (_, _) => null,
    );

class BookingActionController extends AsyncNotifier<String?> {
  String? _actionKey;
  String? _requestId;

  @override
  Future<String?> build() async => null;

  Future<void> confirm(String bookingId) async {
    await _run(
      actionKey: 'confirm:$bookingId',
      bookingId: bookingId,
      command: (requestId) => ref
          .read(bookingServiceProvider)
          .confirm(bookingId, requestId: requestId),
    );
  }

  Future<void> cancel(String bookingId) async {
    await _run(
      actionKey: 'cancel:$bookingId',
      bookingId: bookingId,
      command: (requestId) => ref
          .read(bookingServiceProvider)
          .cancel(bookingId, requestId: requestId),
    );
  }

  Future<BookingIssueReceipt?> reportIssue({
    required String bookingId,
    required String reason,
    required String details,
  }) async {
    BookingIssueReceipt? receipt;
    await _run(
      actionKey: 'issue:$bookingId:$reason',
      bookingId: bookingId,
      command: (_) async {
        receipt = await ref
            .read(bookingServiceProvider)
            .reportIssue(
              bookingId: bookingId,
              reason: reason,
              details: details,
            );
      },
    );
    return receipt;
  }

  Future<void> createAct({
    required String bookingId,
    required String stage,
    required XFile photo,
    HandoverReadinessInput? readiness,
  }) async {
    await _run(
      actionKey: 'act:create:$bookingId:$stage',
      bookingId: bookingId,
      command: (_) async {
        await ref
            .read(bookingServiceProvider)
            .createAct(
              bookingId: bookingId,
              stage: stage,
              photo: photo,
              readiness: readiness,
            );
      },
    );
  }

  Future<void> confirmAct({
    required String bookingId,
    required String actId,
  }) async {
    await _run(
      actionKey: 'act:confirm:$bookingId:$actId',
      bookingId: bookingId,
      command: (requestId) async {
        await ref
            .read(bookingServiceProvider)
            .confirmAct(
              bookingId: bookingId,
              actId: actId,
              requestId: requestId,
            );
      },
    );
  }

  Future<void> _run({
    required String actionKey,
    required String bookingId,
    required Future<void> Function(String requestId) command,
  }) async {
    if (state.isLoading) {
      return;
    }
    if (_actionKey != actionKey) {
      _actionKey = actionKey;
      _requestId = generateUuidV4();
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await command(_requestId!);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(bookingDetailsProvider(bookingId));
      ref.invalidate(bookingActsProvider(bookingId));
      return bookingId;
    });
  }
}
