import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/data/inbox_event.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';
import 'package:mobile/features/notifications/domain/inbox_controller.dart';

void main() {
  test('appends the next inbox cursor page', () async {
    final service = _FakeInboxService([
      InboxPage(items: [event], nextCursor: 'cursor-2'),
      InboxPage(items: [secondEvent], nextCursor: null),
    ]);
    final container = ProviderContainer(
      overrides: [inboxServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(inboxControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(inboxControllerProvider.future);
    await container.read(inboxControllerProvider.notifier).loadMore();

    expect(
      container
          .read(inboxControllerProvider)
          .value!
          .items
          .map((value) => value.eventId),
      [event.eventId, secondEvent.eventId],
    );
    expect(service.cursors, [null, 'cursor-2']);
  });

  test('reloads the first page when unread-only changes', () async {
    final service = _FakeInboxService([
      InboxPage(items: [event, secondEvent], nextCursor: null),
      InboxPage(items: [event], nextCursor: null),
    ]);
    final container = ProviderContainer(
      overrides: [inboxServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(inboxControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(inboxControllerProvider.future);
    await container.read(inboxControllerProvider.notifier).setUnreadOnly(true);

    final state = container.read(inboxControllerProvider).value!;
    expect(state.unreadOnly, isTrue);
    expect(state.items.map((value) => value.eventId), [event.eventId]);
    expect(service.unreadOnlyValues, [false, true]);
  });

  test('marks all events read and reloads the active filter', () async {
    final readEvent = event.copyWith(readAt: DateTime.utc(2026, 8, 30, 10, 5));
    final service = _FakeInboxService([
      InboxPage(items: [event], nextCursor: null),
      InboxPage(items: [readEvent], nextCursor: null),
    ]);
    final container = ProviderContainer(
      overrides: [inboxServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(inboxControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(inboxControllerProvider.future);
    await container.read(inboxControllerProvider.notifier).markAllRead();

    expect(service.markAllReadCalls, 1);
    expect(
      container.read(inboxControllerProvider).value!.items.single.readAt,
      readEvent.readAt,
    );
  });
}

class _FakeInboxService extends InboxService {
  _FakeInboxService(this.pages) : super(Dio());

  final List<InboxPage> pages;
  final List<String?> cursors = [];
  final List<bool> unreadOnlyValues = [];
  var index = 0;
  var markAllReadCalls = 0;

  @override
  Future<InboxPage> listPage({
    int limit = 20,
    String? cursor,
    bool unreadOnly = false,
  }) async {
    cursors.add(cursor);
    unreadOnlyValues.add(unreadOnly);
    return pages[index++];
  }

  @override
  Future<int> markAllRead() async {
    markAllReadCalls += 1;
    return 1;
  }
}

final event = InboxEvent(
  eventId: 'event-1',
  bookingId: 'booking-1',
  supportTicketId: null,
  itemId: null,
  eventType: 'BOOKING_CONFIRMED',
  readAt: null,
  createdAt: DateTime.utc(2026, 8, 30, 10),
);

final secondEvent = event.copyWith(
  eventId: 'event-2',
  createdAt: DateTime.utc(2026, 8, 30, 9),
);
