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
}

class _FakeInboxService extends InboxService {
  _FakeInboxService() : super(Dio());

  var markReadCalls = 0;

  @override
  Future<List<InboxEvent>> list() async => [event];

  @override
  Future<InboxEvent> markRead(String eventId) async {
    markReadCalls += 1;
    return event.copyWith(readAt: DateTime.utc(2026, 7, 29, 12, 5));
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
