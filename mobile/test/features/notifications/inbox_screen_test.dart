import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/notifications/data/inbox_event.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';
import 'package:mobile/features/notifications/presentation/inbox_screen.dart';

void main() {
  testWidgets('marks an unread event and opens its authorized target', (
    tester,
  ) async {
    final service = _FakeInboxService();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const InboxScreen()),
        GoRoute(
          path: '/support/:ticketId',
          builder: (_, _) => const Scaffold(body: Text('Обращение открыто')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inboxServiceProvider.overrideWithValue(service)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ответ поддержки'), findsOneWidget);
    expect(find.text('Новое'), findsOneWidget);
    await tester.tap(find.text('Ответ поддержки'));
    await tester.pumpAndSettle();

    expect(service.markReadCalls, 1);
    expect(find.text('Обращение открыто'), findsOneWidget);
  });

  testWidgets('shows a neutral title for a moderated review', (tester) async {
    final service = _FakeInboxService(reviewEvent);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inboxServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: InboxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Отзыв скрыт после проверки'), findsOneWidget);
    expect(find.textContaining('жалоб'), findsNothing);
  });

  testWidgets('loads older events and applies the unread filter', (
    tester,
  ) async {
    final service = _FakeInboxService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inboxServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: InboxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ответ поддержки'), findsOneWidget);
    expect(find.text('Бронирование подтверждено'), findsNothing);

    await tester.tap(find.text('Показать ещё'));
    await tester.pumpAndSettle();
    expect(find.text('Бронирование подтверждено'), findsOneWidget);

    await tester.tap(find.text('Непрочитанные'));
    await tester.pumpAndSettle();
    expect(find.text('Ответ поддержки'), findsOneWidget);
    expect(find.text('Бронирование подтверждено'), findsNothing);
    expect(service.unreadOnlyValues, [false, false, true]);
  });

  testWidgets('marks all inbox events read from the app bar', (tester) async {
    final service = _FakeInboxService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [inboxServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: InboxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Новое'), findsOneWidget);
    await tester.tap(find.byTooltip('Прочитать всё'));
    await tester.pumpAndSettle();

    expect(service.markAllReadCalls, 1);
    expect(find.text('Новое'), findsNothing);
  });
}

class _FakeInboxService extends InboxService {
  _FakeInboxService([this.value]) : super(Dio());

  final InboxEvent? value;

  var markReadCalls = 0;
  final List<bool> unreadOnlyValues = [];
  var markAllReadCalls = 0;
  var allRead = false;

  @override
  Future<List<InboxEvent>> list() async => [value ?? event];

  @override
  Future<InboxPage> listPage({
    int limit = 20,
    String? cursor,
    bool unreadOnly = false,
  }) async {
    unreadOnlyValues.add(unreadOnly);
    if (unreadOnly) {
      return InboxPage(
        items: allRead ? [] : [value ?? event],
        nextCursor: null,
      );
    }
    if (cursor != null) {
      return InboxPage(items: [readEvent], nextCursor: null);
    }
    final first = value ?? event;
    return InboxPage(
      items: [
        allRead
            ? first.copyWith(readAt: DateTime.utc(2026, 8, 30, 12, 5))
            : first,
      ],
      nextCursor: value == null ? 'cursor-2' : null,
    );
  }

  @override
  Future<int> markAllRead() async {
    markAllReadCalls += 1;
    allRead = true;
    return 1;
  }

  @override
  Future<InboxEvent> markRead(String eventId) async {
    markReadCalls += 1;
    return (value ?? event).copyWith(readAt: DateTime.utc(2026, 7, 29, 12, 5));
  }

  @override
  Future<String?> resolveNavigationPath(String eventId) async =>
      '/support/ticket-1';
}

final event = InboxEvent(
  eventId: '9df957f9-b014-4547-a083-cab9b9892351',
  bookingId: null,
  supportTicketId: 'ticket-1',
  itemId: null,
  eventType: 'SUPPORT_REPLIED',
  readAt: null,
  createdAt: DateTime.utc(2026, 7, 29, 12),
);

final reviewEvent = InboxEvent(
  eventId: '89db0bf1-f6ce-4d89-909f-f76d42e45940',
  bookingId: 'booking-1',
  supportTicketId: null,
  itemId: null,
  eventType: 'REVIEW_HIDDEN_BY_REPORT_REVIEW',
  readAt: null,
  createdAt: DateTime.utc(2026, 8, 9, 12),
);

final readEvent = InboxEvent(
  eventId: '79db0bf1-f6ce-4d89-909f-f76d42e45940',
  bookingId: 'booking-2',
  supportTicketId: null,
  itemId: null,
  eventType: 'BOOKING_CONFIRMED',
  readAt: DateTime.utc(2026, 8, 8, 12, 5),
  createdAt: DateTime.utc(2026, 8, 8, 12),
);
