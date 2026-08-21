import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/booking/data/booking_models.dart';
import 'package:mobile/features/booking/data/booking_service.dart';
import 'package:mobile/features/booking/presentation/booking_chat_screen.dart';
import 'package:mobile/features/booking/presentation/booking_list_screen.dart';
import 'package:mobile/features/notifications/data/inbox_event.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';
import 'package:mobile/features/safety/data/safety_service.dart';

void main() {
  testWidgets(
    'shows system text and retries one draft with the same client ID',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _RetryBookingService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingServiceProvider.overrideWithValue(service),
            bookingDetailsProvider(
              booking.id,
            ).overrideWith((ref) async => booking),
          ],
          child: MaterialApp(home: BookingChatScreen(bookingId: booking.id)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Заявка отправлена.'), findsOneWidget);
      await tester.enterText(
        find.byType(FormBuilderTextField),
        'Можно забрать после 18:00?',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
      await tester.pumpAndSettle();
      expect(find.text('Нет сети'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
      await tester.pumpAndSettle();

      expect(service.clientMessageIds, hasLength(2));
      expect(service.clientMessageIds[0], service.clientMessageIds[1]);
      expect(service.markReadCalls, greaterThan(0));
      expect(find.text('Можно забрать после 18:00?'), findsNothing);
    },
  );

  testWidgets('shows unread booking-message count on the booking card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBookingsProvider.overrideWith((ref) async => [booking]),
          inboxEventsProvider.overrideWith(
            (ref) async => [_unreadEvent('event-1'), _unreadEvent('event-2')],
          ),
        ],
        child: const MaterialApp(home: BookingListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('reports a counterparty message and confirms pair block', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bookingService = _ModerationBookingService();
    final safetyService = _FakeSafetyService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingServiceProvider.overrideWithValue(bookingService),
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => booking),
          safetyServiceProvider.overrideWithValue(safetyService),
        ],
        child: MaterialApp(home: BookingChatScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Пожаловаться'));
    await tester.pumpAndSettle();
    final reportForm = tester.state<FormBuilderState>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FormBuilder),
      ),
    );
    reportForm.patchValue({
      'reason': 'HARASSMENT',
      'description': 'Собеседник отправил угрозу в сообщении.',
    });
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Отправить'),
      ),
    );
    await tester.pumpAndSettle();

    expect(safetyService.lastTargetType, 'MESSAGE');
    expect(safetyService.lastTargetId, 'message-counterparty');
    await tester.tap(find.byTooltip('Заблокировать собеседника'));
    await tester.pumpAndSettle();
    expect(find.text('Заблокировать собеседника?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Заблокировать'),
      ),
    );
    await tester.pumpAndSettle();

    expect(bookingService.blockCalls, 1);
  });
}

class _RetryBookingService extends BookingService {
  _RetryBookingService() : super(Dio());

  final clientMessageIds = <String>[];
  var markReadCalls = 0;
  var shouldFail = true;

  @override
  Future<BookingMessagePage> listMessages(
    String bookingId, {
    String? cursor,
    int limit = 50,
  }) async => BookingMessagePage(
    items: [
      BookingMessage(
        id: 'message-system',
        bookingId: bookingId,
        author: 'SYSTEM',
        clientMessageId: null,
        body: 'Заявка отправлена.',
        createdAt: DateTime.utc(2026, 8, 9, 12),
      ),
    ],
    nextCursor: null,
  );

  @override
  Future<void> markMessagesRead(String bookingId) async {
    markReadCalls += 1;
  }

  @override
  Future<BookingMessage> sendMessage({
    required String bookingId,
    required String body,
    required String clientMessageId,
  }) async {
    clientMessageIds.add(clientMessageId);
    if (shouldFail) {
      shouldFail = false;
      throw const ApiException(code: 'NETWORK_ERROR', message: 'Нет сети');
    }
    return BookingMessage(
      id: 'message-sent',
      bookingId: bookingId,
      author: 'SELF',
      clientMessageId: clientMessageId,
      body: body,
      createdAt: DateTime.utc(2026, 8, 9, 12, 1),
    );
  }
}

class _ModerationBookingService extends BookingService {
  _ModerationBookingService() : super(Dio());

  var blockCalls = 0;

  @override
  Future<BookingMessagePage> listMessages(
    String bookingId, {
    String? cursor,
    int limit = 50,
  }) async => BookingMessagePage(
    items: [
      BookingMessage(
        id: 'message-counterparty',
        bookingId: bookingId,
        author: 'COUNTERPARTY',
        clientMessageId: null,
        body: 'Сообщение второй стороны',
        createdAt: DateTime.utc(2026, 8, 9, 12),
      ),
    ],
    nextCursor: null,
  );

  @override
  Future<void> markMessagesRead(String bookingId) async {}

  @override
  Future<void> blockCounterparty(String bookingId) async {
    blockCalls += 1;
  }
}

class _FakeSafetyService extends SafetyService {
  _FakeSafetyService() : super(Dio());

  String? lastTargetType;
  String? lastTargetId;

  @override
  Future<void> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    lastTargetType = targetType;
    lastTargetId = targetId;
  }
}

final booking = ParticipantBooking(
  id: 'booking-1',
  itemId: 'item-1',
  actorRole: 'BORROWER',
  startDate: DateTime.utc(2026, 8, 20),
  endDate: DateTime.utc(2026, 8, 21),
  status: 'PENDING',
  nextAction: const BookingNextAction(
    code: 'WAIT_LENDER',
    title: 'Ожидайте ответ владельца',
    description: 'Владелец должен подтвердить или отклонить заявку.',
  ),
  expiresAt: DateTime.utc(2030),
  cancellationReason: null,
  terms: null,
  handover: null,
  counterpartyContact: null,
  createdAt: DateTime.utc(2026, 8, 9),
);

InboxEvent _unreadEvent(String eventId) => InboxEvent(
  eventId: eventId,
  bookingId: booking.id,
  supportTicketId: null,
  itemId: null,
  eventType: 'BOOKING_MESSAGE_CREATED',
  readAt: null,
  createdAt: DateTime.utc(2026, 8, 9, 12),
);
