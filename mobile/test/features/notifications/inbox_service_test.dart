import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';

import '../../support/network_fakes.dart';

void main() {
  const eventId = '9df957f9-b014-4547-a083-cab9b9892351';

  test('resolves only the booking bound to the requested event', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/inbox/$eventId');
      return jsonResponse({
        'success': true,
        'data': {
          'eventId': eventId,
          'eventType': 'BOOKING_CONFIRMED',
          'bookingId': 'booking-1',
          'supportTicketId': null,
        },
        'error': null,
      });
    });
    final service = InboxService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.resolveNavigationPath(eventId),
      completion('/bookings/booking-1'),
    );
  });

  test('opens a booking message directly in its participant chat', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': {
          'eventId': eventId,
          'eventType': 'BOOKING_MESSAGE_CREATED',
          'bookingId': 'booking-1',
          'supportTicketId': null,
          'itemId': null,
        },
        'error': null,
      }),
    );
    final service = InboxService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.resolveNavigationPath(eventId),
      completion('/bookings/booking-1/chat'),
    );
  });

  test('resolves a moderation event to the owner edit route', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': {
          'eventId': eventId,
          'eventType': 'ITEM_APPROVED',
          'bookingId': null,
          'supportTicketId': null,
          'itemId': 'item-1',
        },
        'error': null,
      }),
    );
    final service = InboxService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.resolveNavigationPath(eventId),
      completion('/items/item-1/edit'),
    );
  });

  test('resolves a support reply to the authenticated ticket route', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': {
          'eventId': eventId,
          'eventType': 'SUPPORT_REPLIED',
          'bookingId': null,
          'supportTicketId': 'ticket-1',
          'itemId': null,
        },
        'error': null,
      }),
    );
    final service = InboxService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.resolveNavigationPath(eventId),
      completion('/support/ticket-1'),
    );
  });

  test('lists safe summaries and marks one event as read', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      if (requestIndex == 1) {
        return jsonResponse({
          'success': true,
          'data': [inboxEventJson(eventId)],
          'error': null,
        });
      }
      return jsonResponse({
        'success': true,
        'data': inboxEventJson(eventId, readAt: '2026-07-29T12:05:00.000Z'),
        'error': null,
      });
    });
    final service = InboxService(Dio()..httpClientAdapter = adapter);

    final events = await service.list();
    final read = await service.markRead(eventId);

    expect(events.single.eventType, 'SUPPORT_REPLIED');
    expect(events.single.readAt, isNull);
    expect(read.readAt, isNotNull);
    expect(adapter.requests[0].path, '/inbox');
    expect(adapter.requests[0].method, 'GET');
    expect(adapter.requests[1].path, '/inbox/$eventId/read');
    expect(adapter.requests[1].method, 'PATCH');
  });

  test('rejects an event response bound to another event ID', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': {
          'eventId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          'eventType': 'BOOKING_CONFIRMED',
          'bookingId': 'booking-1',
          'supportTicketId': null,
        },
        'error': null,
      }),
    );
    final service = InboxService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.resolveNavigationPath(eventId),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });

  test('preserves a safe backend error without exposing its payload', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': false,
        'data': null,
        'error': {'code': 'EVENT_NOT_FOUND', 'message': 'Событие недоступно'},
      }, statusCode: 404),
    );
    final service = InboxService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.resolveNavigationPath(eventId),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'EVENT_NOT_FOUND')
            .having((error) => error.message, 'message', 'Событие недоступно'),
      ),
    );
  });
}

Map<String, Object?> inboxEventJson(String eventId, {String? readAt}) => {
  'eventId': eventId,
  'bookingId': null,
  'supportTicketId': 'ticket-1',
  'itemId': null,
  'eventType': 'SUPPORT_REPLIED',
  'readAt': readAt,
  'createdAt': '2026-07-29T12:00:00.000Z',
};
