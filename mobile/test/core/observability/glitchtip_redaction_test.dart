import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:mobile/core/observability/glitchtip.dart';

void main() {
  test('beforeSend removes PII and secrets from the complete event', () {
    final event = SentryEvent(
      message: SentryMessage('OTP: 123456 for +7 (999) 123-45-67'),
      user: SentryUser(id: 'user-1', username: '+79991234567'),
      request: SentryRequest(
        url:
            'https://storage.example/item.jpg?X-Amz-Signature=url-secret',
        cookies: 'session=cookie-secret',
        headers: {'Authorization': 'Bearer access-secret'},
        data: {'pickupAddress': 'Москва, Тверская, 1'},
      ),
      breadcrumbs: [
        Breadcrumb(
          message: 'phone +79991234567',
          data: {
            'paymentPayload': {'cardNumber': '4111111111111111'},
          },
        ),
      ],
      exceptions: [
        SentryException(
          type: 'StateError',
          value: 'Bearer exception-secret',
          stackTrace: SentryStackTrace(
            frames: [
              SentryStackFrame(
                absPath: '/Users/ivan/private.dart',
                fileName: 'private.dart',
                function: 'loadItem',
                contextLine: 'final phone = "+79991234567";',
                vars: {'accessToken': 'frame-secret'},
              ),
            ],
          ),
        ),
      ],
      contexts: Contexts()
        ..['booking'] = {
          'bookingId': 'booking-1',
          'pickupAddress': 'Москва, Арбат, 1',
        }
        ..['diagnostics'] = {
          'accessToken': 'access-secret',
          'safeStatus': 'BOOKING_CONFLICT',
        },
    );
    final hint = Hint.withAttachment(
      SentryAttachment.fromIntList([1, 2, 3], 'private.txt'),
    );

    final result = scrubGlitchTipEvent(event, hint);

    expect(result, isNot(same(event)));
    expect(result.user, isNull);
    expect(result.request, isNull);
    expect(result.message!.formatted, isNot(contains('123456')));
    expect(result.message!.formatted, isNot(contains('999')));
    expect(result.contexts['diagnostics'], {
      'accessToken': '[REDACTED]',
      'safeStatus': 'BOOKING_CONFLICT',
    });
    expect(result.breadcrumbs!.single.message, 'phone [REDACTED]');
    expect(result.breadcrumbs!.single.data!['paymentPayload'], '[REDACTED]');
    expect(result.exceptions!.single.value, 'Bearer [REDACTED]');
    final exceptionJson = result.exceptions!.single.toJson().toString();
    expect(exceptionJson, isNot(contains('/Users/ivan')));
    expect(exceptionJson, isNot(contains('frame-secret')));
    expect(exceptionJson, isNot(contains('79991234567')));
    expect(exceptionJson, contains('private.dart'));
    expect(result.contexts['booking'], {
      'bookingId': 'booking-1',
      'pickupAddress': '[REDACTED]',
    });
    expect(hint.attachments, isEmpty);
  });

  test('redacts signed URLs and cookies in unstructured diagnostic text', () {
    final redacted = redactDiagnosticText(
      'Cookie: session=secret; '
      'https://storage.example/file?X-Amz-Signature=signed-secret',
    );

    expect(redacted, isNot(contains('session=secret')));
    expect(redacted, isNot(contains('storage.example')));
    expect(redacted, isNot(contains('signed-secret')));
  });
}
