import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/booking/data/booking_models.dart';
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

  test('does not send a duplicate command while the first is loading', () async {
    final service = _SlowBookingService();
    final container = ProviderContainer(
      overrides: [bookingServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(bookingActionProvider.future);
    final controller = container.read(bookingActionProvider.notifier);

    final first = controller.confirm('booking-1');
    await Future<void>.delayed(Duration.zero);
    await controller.confirm('booking-1');

    expect(service.calls, 1);
    service.completer.complete();
    await first;
  });

  test('reloads authoritative booking providers after an error response', () async {
    final service = _ReloadAfterErrorBookingService();
    final container = ProviderContainer(
      overrides: [bookingServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscriptions = [
      container.listen(myBookingsProvider, (_, _) {}),
      container.listen(bookingDetailsProvider('booking-1'), (_, _) {}),
      container.listen(bookingActsProvider('booking-1'), (_, _) {}),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });
    await Future.wait([
      container.read(myBookingsProvider.future),
      container.read(bookingDetailsProvider('booking-1').future),
      container.read(bookingActsProvider('booking-1').future),
      container.read(bookingActionProvider.future),
    ]);

    await container.read(bookingActionProvider.notifier).confirm('booking-1');
    await Future.wait([
      container.read(myBookingsProvider.future),
      container.read(bookingDetailsProvider('booking-1').future),
      container.read(bookingActsProvider('booking-1').future),
    ]);

    expect(container.read(bookingActionProvider).hasError, isTrue);
    expect(service.listLoads, 2);
    expect(service.detailLoads, 2);
    expect(service.actLoads, 2);
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

class _SlowBookingService extends BookingService {
  _SlowBookingService() : super(Dio());

  final completer = Completer<void>();
  var calls = 0;

  @override
  Future<void> confirm(String id, {required String requestId}) {
    calls += 1;
    return completer.future;
  }
}

class _ReloadAfterErrorBookingService extends BookingService {
  _ReloadAfterErrorBookingService() : super(Dio());

  var listLoads = 0;
  var detailLoads = 0;
  var actLoads = 0;

  @override
  Future<List<ParticipantBooking>> listMine() async {
    listLoads += 1;
    return [_participantBooking];
  }

  @override
  Future<ParticipantBooking> getDetails(String id) async {
    detailLoads += 1;
    return _participantBooking;
  }

  @override
  Future<List<BookingAct>> listActs(String bookingId) async {
    actLoads += 1;
    return const [];
  }

  @override
  Future<void> confirm(String id, {required String requestId}) async {
    throw Exception('received conflict response');
  }
}

final _participantBooking = ParticipantBooking(
  id: 'booking-1',
  itemId: 'item-1',
  actorRole: 'BORROWER',
  startDate: DateTime.utc(2026, 9, 4),
  endDate: DateTime.utc(2026, 9, 4),
  status: 'PENDING',
  nextAction: const BookingNextAction(
    code: 'WAIT_LENDER',
    title: 'Ожидайте ответ',
    description: 'Заявка рассматривается.',
  ),
  expiresAt: null,
  cancellationReason: null,
  terms: null,
  handover: null,
  counterpartyContact: null,
  createdAt: DateTime.utc(2026, 9, 4),
);
