import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/booking/data/booking_models.dart';
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
    expect(bookings.single.payment, isNull);
    expect(bookings.single.deposit, isNull);
    expect(bookings.single.financialDispute, isNull);
  });

  test('parses exact minor booking, payment and deposit summaries', () {
    final parsed = ParticipantBooking.fromJson(fakeBookingJson());

    expect(parsed.terms?.moneyMinor?.pricePerDay, 45000);
    expect(parsed.terms?.moneyMinor?.rentalSubtotal, 90000);
    expect(parsed.terms?.moneyMinor?.deposit, 5000);
    expect(parsed.terms?.moneyMinor?.platformFee, 900);
    expect(parsed.terms?.moneyMinor?.ownerPayout, 89100);
    expect(parsed.terms?.moneyMinor?.total, 95000);
    expect(parsed.payment?.amountMinor, 95000);
    expect(parsed.payment?.status, 'SUCCEEDED');
    expect(parsed.deposit?.amountMinor, 5000);
    expect(parsed.deposit?.status, 'HELD');
    expect(parsed.deposit?.refundedMinor, 0);
    expect(parsed.deposit?.releasedToLenderMinor, 0);
    expect(parsed.deposit?.policyVersion, 'fake-deposit-v1');
    expect(
      parsed.deposit?.disputeWindowEndsAt,
      DateTime.parse('2026-08-03T12:00:00.000Z'),
    );

    final fractional = fakeBookingJson();
    final terms = fractional['terms']! as Map<String, Object?>;
    final money = terms['moneyMinor']! as Map<String, Object?>;
    terms['moneyMinor'] = <String, Object?>{...money, 'total': 95000.5};
    expect(
      () => ParticipantBooking.fromJson(fractional),
      throwsA(isA<FormatException>()),
    );
  });

  test('sends fake checkout outcomes with a caller-owned stable key', () async {
    final outcomes = <String>[];
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/dev/fake-safe-deal/bookings/booking-1/checkout');
      expect(options.headers['Idempotency-Key'], 'stable-checkout-id');
      final outcome =
          (options.data! as Map<String, dynamic>)['outcome']! as String;
      outcomes.add(outcome);
      return jsonResponse({
        'success': true,
        'data': {
          'outcome': switch (outcome) {
            'SUCCESS' => 'SUCCEEDED',
            'DECLINE' => 'DECLINED',
            _ => 'TIMEOUT',
          },
          if (outcome == 'DECLINE') 'errorCode': 'FAKE_DECLINED',
        },
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    final results = <FakeCheckoutResult>[];
    for (final outcome in ['SUCCESS', 'DECLINE', 'TIMEOUT']) {
      results.add(
        await service.fakeCheckout(
          bookingId: 'booking-1',
          outcome: outcome,
          requestId: 'stable-checkout-id',
        ),
      );
    }

    expect(outcomes, ['SUCCESS', 'DECLINE', 'TIMEOUT']);
    expect(results.map((value) => value.outcome), [
      'SUCCEEDED',
      'DECLINED',
      'TIMEOUT',
    ]);
  });

  test(
    'composes the participant financial dispute into booking details',
    () async {
      var requestIndex = 0;
      final adapter = CallbackAdapter((options) {
        requestIndex += 1;
        if (requestIndex == 1) {
          expect(options.path, '/bookings/booking-1');
          return jsonResponse({
            'success': true,
            'data': fakeBookingJson(),
            'error': null,
          });
        }
        expect(options.path, '/bookings/booking-1/dispute');
        return jsonResponse({
          'success': true,
          'data': financialDisputeJson(),
          'error': null,
        });
      });
      final service = BookingService(Dio()..httpClientAdapter = adapter);

      final result = await service.getDetails('booking-1');

      expect(result.financialDispute?.id, 'dispute-1');
      expect(result.financialDispute?.reason, 'ITEM_DAMAGED');
      expect(result.financialDispute?.evidence.single.sha256, 'abc123');
      expect(adapter.requests, hasLength(2));
    },
  );

  test('treats only a participant dispute 404 as no dispute', () async {
    final adapter = CallbackAdapter((options) {
      if (options.path == '/bookings/booking-1') {
        return jsonResponse({
          'success': true,
          'data': fakeBookingJson(),
          'error': null,
        });
      }
      return jsonResponse({
        'success': false,
        'data': null,
        'error': {'code': 'NOT_FOUND', 'message': 'Спор не найден'},
      }, statusCode: 404);
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    final result = await service.getDetails('booking-1');

    expect(result.financialDispute, isNull);
  });

  test('does not swallow a non-404 dispute loading failure', () async {
    final adapter = CallbackAdapter((options) {
      if (options.path == '/bookings/booking-1') {
        return jsonResponse({
          'success': true,
          'data': fakeBookingJson(),
          'error': null,
        });
      }
      return jsonResponse({
        'success': false,
        'data': null,
        'error': {'code': 'TEMPORARY', 'message': 'Повторите позже'},
      }, statusCode: 503);
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.getDetails('booking-1'),
      throwsA(
        isA<ApiException>().having((error) => error.code, 'code', 'TEMPORARY'),
      ),
    );
  });

  test('opens a financial dispute through the dedicated endpoint', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/bookings/booking-1/disputes');
      expect(options.data, {
        'reason': 'ITEM_LOST',
        'description': 'Вещь не была возвращена после завершения аренды.',
      });
      return jsonResponse({
        'success': true,
        'data': financialDisputeJson(),
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    final dispute = await service.openFinancialDispute(
      bookingId: 'booking-1',
      reason: 'ITEM_LOST',
      description: '  Вещь не была возвращена после завершения аренды.  ',
    );

    expect(dispute.id, 'dispute-1');
  });

  test('uploads and attaches private dispute evidence', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      if (requestIndex == 1) {
        expect(options.path, '/uploads/presigned-url');
        expect(options.data, {
          'purpose': 'DISPUTE_EVIDENCE',
          'disputeId': 'dispute-1',
          'fileName': 'dispute-evidence.jpg',
          'contentType': 'image/jpeg',
          'sizeBytes': 3,
        });
        return jsonResponse({
          'success': true,
          'data': {
            'intentId': 'intent-1',
            'uploadUrl': 'https://storage.test/private-dispute-upload',
            'fields': {'key': 'quarantine/dispute.jpg'},
          },
          'error': null,
        });
      }
      if (requestIndex == 2) {
        expect(options.path, 'https://storage.test/private-dispute-upload');
        expect(options.extra['skipAuth'], isTrue);
        return ResponseBody.fromString('', 204);
      }
      expect(options.path, '/bookings/booking-1/disputes/dispute-1/evidence');
      expect(options.data, {'intentId': 'intent-1'});
      return jsonResponse({
        'success': true,
        'data': {
          'id': 'evidence-new',
          'sha256': 'def456',
          'createdAt': '2026-08-03T10:00:00.000Z',
        },
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);
    final photo = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'damage.jpg',
      mimeType: 'image/jpeg',
    );

    final evidence = await service.addDisputeEvidence(
      bookingId: 'booking-1',
      disputeId: 'dispute-1',
      photo: photo,
    );

    expect(evidence.id, 'evidence-new');
    expect(adapter.requests, hasLength(3));
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
      return jsonResponse({
        'success': true,
        'data': {
          'id': 'ticket-1',
          'status': 'OPEN',
          'createdAt': '2026-08-10T10:00:00.000Z',
        },
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);

    final receipt = await service.reportIssue(
      bookingId: 'booking-1',
      reason: 'ITEM_FAULTY',
      details: '  Вещь не включается при проверке.  ',
    );

    expect(receipt.id, 'ticket-1');
    expect(receipt.status, 'OPEN');
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
      readiness: const HandoverReadinessInput(
        isWorking: true,
        isComplete: true,
        visibleDefects: 'Нет',
      ),
    );
    final confirmed = await service.confirmAct(
      bookingId: 'booking-1',
      actId: created.id,
      requestId: '11111111-1111-4111-8111-111111111111',
    );

    expect(listed.single.stage, 'HANDOVER');
    expect(listed.single.readiness?.visibleDefects, 'Нет');
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
      'readiness': {
        'isWorking': true,
        'isComplete': true,
        'visibleDefects': 'Нет',
      },
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

  test(
    'lists, sends, marks and blocks through booking chat endpoints',
    () async {
      var requestIndex = 0;
      final adapter = CallbackAdapter((options) {
        requestIndex += 1;
        if (requestIndex == 1) {
          expect(options.method, 'GET');
          expect(options.path, '/bookings/booking-1/messages');
          expect(options.queryParameters, {'limit': 20, 'cursor': 'cursor-1'});
          return jsonResponse({
            'success': true,
            'data': {
              'items': [bookingMessageJson()],
              'nextCursor': null,
            },
            'error': null,
          });
        }
        if (requestIndex == 2) {
          expect(options.method, 'POST');
          expect(options.path, '/bookings/booking-1/messages');
          expect(options.data, {
            'body': 'Добрый день',
            'clientMessageId': '11111111-1111-4111-8111-111111111141',
          });
          return jsonResponse({
            'success': true,
            'data': bookingMessageJson(),
            'error': null,
          });
        }
        if (requestIndex == 3) {
          expect(options.method, 'PATCH');
          expect(options.path, '/bookings/booking-1/messages/read');
          return jsonResponse({
            'success': true,
            'data': {'readAt': '2026-08-09T12:00:00.000Z', 'updatedCount': 1},
            'error': null,
          });
        }
        expect(options.method, 'POST');
        expect(options.path, '/bookings/booking-1/messages/block-counterparty');
        return jsonResponse({
          'success': true,
          'data': {
            'id': 'block-1',
            'blocked': {'id': 'user-2', 'name': 'Анна'},
            'createdAt': '2026-08-09T12:00:00.000Z',
          },
          'error': null,
        });
      });
      final service = BookingService(Dio()..httpClientAdapter = adapter);

      final page = await service.listMessages(
        'booking-1',
        cursor: 'cursor-1',
        limit: 20,
      );
      final sent = await service.sendMessage(
        bookingId: 'booking-1',
        body: '  Добрый день  ',
        clientMessageId: '11111111-1111-4111-8111-111111111141',
      );
      await service.markMessagesRead('booking-1');
      await service.blockCounterparty('booking-1');

      expect(page.items.single.body, 'Добрый день');
      expect(sent.author, 'SELF');
      expect(adapter.requests, hasLength(4));
    },
  );

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
  'nextAction': {
    'code': 'WAIT_LENDER',
    'title': 'Ожидайте ответ владельца',
    'description': 'Владелец должен подтвердить или отклонить заявку.',
  },
  'expiresAt': '2026-07-30T00:00:00.000Z',
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

Map<String, Object?> fakeBookingJson() => {
  ...bookingJson(),
  'status': 'RETURNED',
  'expiresAt': null,
  'terms': {
    'itemTitle': 'Перфоратор',
    'lenderDisplayName': 'Иван',
    'pricePerDay': 450,
    'days': 2,
    'rentalSubtotal': 900,
    'depositAmount': 50,
    'platformFee': 9,
    'ownerPayout': 891,
    'total': 950,
    'currency': 'RUB',
    'paymentScenario': 'FAKE_SAFE_DEAL',
    'moneyMinor': {
      'pricePerDay': 45000,
      'rentalSubtotal': 90000,
      'deposit': 5000,
      'platformFee': 900,
      'ownerPayout': 89100,
      'total': 95000,
    },
    'depositTerms': {
      'policyVersion': 'fake-deposit-v1',
      'disputeWindowSeconds': 86400,
    },
    'listingVersion': '2026-07-28:2',
    'offerVersion': '2026-08-01.1',
    'cancellationPolicyVersion': '2026-08-01.2',
  },
  'payment': {'amountMinor': 95000, 'status': 'SUCCEEDED'},
  'deposit': {
    'amountMinor': 5000,
    'status': 'HELD',
    'refundedMinor': 0,
    'releasedToLenderMinor': 0,
    'policyVersion': 'fake-deposit-v1',
    'disputeWindowEndsAt': '2026-08-03T12:00:00.000Z',
  },
};

Map<String, Object?> financialDisputeJson() => {
  'id': 'dispute-1',
  'bookingId': 'booking-1',
  'openedById': 'borrower-1',
  'reason': 'ITEM_DAMAGED',
  'description': 'После возврата обнаружена новая трещина.',
  'status': 'OPEN',
  'openedAt': '2026-08-03T10:00:00.000Z',
  'resolvedAt': null,
  'evidence': [
    {
      'id': 'evidence-1',
      'sha256': 'abc123',
      'createdAt': '2026-08-03T10:01:00.000Z',
    },
  ],
};

Map<String, Object?> bookingMessageJson() => {
  'id': 'message-1',
  'bookingId': 'booking-1',
  'author': 'SELF',
  'clientMessageId': '11111111-1111-4111-8111-111111111141',
  'body': 'Добрый день',
  'createdAt': '2026-08-09T12:00:00.000Z',
};

Map<String, Object?> bookingActJson() => {
  'id': 'act-1',
  'bookingId': 'booking-1',
  'authorId': 'lender-1',
  'stage': 'HANDOVER',
  'createdAt': '2026-08-01T10:00:00.000Z',
  'confirmedById': null,
  'confirmedAt': null,
  'readiness': {
    'isWorking': true,
    'isComplete': true,
    'visibleDefects': 'Нет',
    'declaredAt': '2026-08-01T09:59:00.000Z',
    'declaration': 'LENDER_SELF_DECLARATION',
  },
  'evidence': [
    {
      'id': 'evidence-1',
      'sha256': 'abc123',
      'createdAt': '2026-08-01T10:00:00.000Z',
    },
  ],
};
