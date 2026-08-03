import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/booking/data/booking_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('creates a booking with exact accepted terms and request ID', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/bookings');
      expect(
        options.headers['X-Request-Id'],
        '33333333-3333-4333-8333-333333333333',
      );
      expect(options.data, {
        'itemId': 'item-1',
        'startDate': '2026-08-01',
        'endDate': '2026-08-03',
        'offerVersion': '2026-08-01.1',
        'cancellationPolicyVersion': '2026-08-01.2',
        'offerAccepted': true,
        'rentalRulesAccepted': true,
      });
      return jsonResponse({
        'success': true,
        'data': {'id': 'booking-created'},
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    final id = await service.create(
      itemId: 'item-1',
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 3),
      offerVersion: '2026-08-01.1',
      cancellationPolicyVersion: '2026-08-01.2',
      requestId: '33333333-3333-4333-8333-333333333333',
    );

    expect(id, 'booking-created');
  });

  test(
    'checks item availability without loading private calendar details',
    () async {
      final adapter = CallbackAdapter((options) {
        expect(options.method, 'GET');
        expect(options.path, '/items/item-1/availability');
        expect(options.queryParameters, {
          'startDate': '2026-08-01',
          'endDate': '2026-08-03',
        });
        return jsonResponse({
          'success': true,
          'data': {'available': false},
          'error': null,
        });
      });
      final service = BookingService(Dio()..httpClientAdapter = adapter);

      final result = await service.checkAvailability(
        itemId: 'item-1',
        startDate: DateTime(2026, 8),
        endDate: DateTime(2026, 8, 3),
      );

      expect(result.available, isFalse);
    },
  );

  test('loads actor-specific booking terms and redacted handover', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/bookings');
      return jsonResponse({
        'success': true,
        'data': [bookingJson()],
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    final bookings = await service.listMine();

    expect(bookings, hasLength(1));
    expect(bookings.single.actorRole, 'BORROWER');
    expect(bookings.single.terms?.days, 2);
    expect(bookings.single.terms?.total, 900);
    expect(bookings.single.handover, isNull);
  });

  test('sends one caller-owned request ID for a booking command', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/bookings/booking-1/confirm');
      expect(
        options.headers['X-Request-Id'],
        '11111111-1111-4111-8111-111111111111',
      );
      return jsonResponse({'success': true, 'data': {}, 'error': null});
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    await service.confirm(
      'booking-1',
      requestId: '11111111-1111-4111-8111-111111111111',
    );
  });

  test('cancels a pending booking with a caller-owned request ID', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/bookings/booking-1/cancel');
      expect(
        options.headers['X-Request-Id'],
        '22222222-2222-4222-8222-222222222222',
      );
      return jsonResponse({'success': true, 'data': {}, 'error': null});
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    await service.cancel(
      'booking-1',
      requestId: '22222222-2222-4222-8222-222222222222',
    );
  });

  test('creates a structured booking issue without financial fields', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/support/tickets');
      expect(options.data, {
        'bookingId': 'booking-1',
        'bookingIssueReason': 'ITEM_FAULTY',
        'subject': 'Вещь неисправна при передаче',
        'message': 'Вещь не включается при проверке.',
      });
      return jsonResponse({'success': true, 'data': {}, 'error': null});
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    await service.reportIssue(
      bookingId: 'booking-1',
      reason: 'ITEM_FAULTY',
      details: '  Вещь не включается при проверке.  ',
    );
  });

  test('lists, creates and confirms a private handover act', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      if (requestIndex == 1) {
        return jsonResponse({
          'success': true,
          'data': [bookingActJson()],
          'error': null,
        });
      }
      if (requestIndex == 2) {
        return jsonResponse({
          'success': true,
          'data': {
            'intentId': 'intent-1',
            'uploadUrl': 'https://storage.test/private-upload',
            'fields': {'key': 'quarantine/handover.jpg'},
          },
          'error': null,
        });
      }
      if (requestIndex == 3) {
        return ResponseBody.fromString('', 204);
      }
      return jsonResponse({
        'success': true,
        'data': bookingActJson(),
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);
    final photo = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'handover.jpg',
      mimeType: 'image/jpeg',
    );

    final listed = await service.listActs('booking-1');
    final created = await service.createAct(
      bookingId: 'booking-1',
      stage: 'HANDOVER',
      photo: photo,
    );
    final confirmed = await service.confirmAct(
      bookingId: 'booking-1',
      actId: created.id,
      requestId: '11111111-1111-4111-8111-111111111111',
    );

    expect(listed.single.stage, 'HANDOVER');
    expect(listed.single.evidence.single.sha256, 'abc123');
    expect(confirmed.id, 'act-1');
    expect(adapter.requests, hasLength(5));
    expect(adapter.requests[0].path, '/bookings/booking-1/acts');
    expect(adapter.requests[1].data, {
      'purpose': 'BOOKING_EVIDENCE',
      'bookingId': 'booking-1',
      'fileName': 'booking-evidence.jpg',
      'contentType': 'image/jpeg',
      'sizeBytes': 3,
    });
    expect(adapter.requests[2].path, 'https://storage.test/private-upload');
    expect(adapter.requests[2].extra['skipAuth'], isTrue);
    expect(adapter.requests[3].path, '/bookings/booking-1/acts');
    expect(adapter.requests[3].data, {
      'stage': 'HANDOVER',
      'intentId': 'intent-1',
    });
    expect(adapter.requests[4].path, '/bookings/booking-1/acts/act-1/confirm');
    expect(
      adapter.requests[4].headers['X-Request-Id'],
      '11111111-1111-4111-8111-111111111111',
    );
  });

  test('loads one participant booking by ID', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/bookings/booking-1');
      return jsonResponse({
        'success': true,
        'data': bookingJson(),
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    final booking = await service.getDetails('booking-1');

    expect(booking.id, 'booking-1');
    expect(booking.actorRole, 'BORROWER');
  });

  test('preserves a booking command conflict from the API envelope', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': false,
        'data': null,
        'error': {
          'code': 'BOOKING_EXPIRED',
          'message': 'Срок подтверждения истёк',
        },
      }, statusCode: 409),
    );
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.confirm('booking-1', requestId: 'request-1'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'BOOKING_EXPIRED')
            .having(
              (error) => error.message,
              'message',
              'Срок подтверждения истёк',
            ),
      ),
    );
  });

  test('rejects a failed booking list envelope', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': false,
        'data': null,
        'error': {
          'code': 'BOOKINGS_UNAVAILABLE',
          'message': 'Бронирования временно недоступны',
        },
      }),
    );
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.listMine(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'BOOKINGS_UNAVAILABLE',
        ),
      ),
    );
  });
}

Map<String, Object?> bookingJson() => {
  'id': 'booking-1',
  'itemId': 'item-1',
  'actorRole': 'BORROWER',
  'startDate': '2026-08-01T00:00:00.000Z',
  'endDate': '2026-08-02T00:00:00.000Z',
  'status': 'PENDING',
  'expiresAt': '2026-07-29T12:15:00.000Z',
  'cancellationReason': null,
  'terms': {
    'itemTitle': 'Перфоратор',
    'lenderDisplayName': 'Иван',
    'pricePerDay': 450,
    'days': 2,
    'rentalSubtotal': 900,
    'depositAmount': null,
    'platformFee': 0,
    'ownerPayout': 900,
    'total': 900,
    'currency': 'RUB',
    'listingVersion': '2026-07-28:1',
    'offerVersion': null,
    'cancellationPolicyVersion': null,
  },
  'handover': null,
  'counterpartyContact': null,
  'createdAt': '2026-07-29T12:00:00.000Z',
};

Map<String, Object?> bookingActJson() => {
  'id': 'act-1',
  'bookingId': 'booking-1',
  'authorId': 'lender-1',
  'stage': 'HANDOVER',
  'createdAt': '2026-08-01T10:00:00.000Z',
  'confirmedById': null,
  'confirmedAt': null,
  'evidence': [
    {
      'id': 'evidence-1',
      'sha256': 'abc123',
      'createdAt': '2026-08-01T10:00:00.000Z',
    },
  ],
};
