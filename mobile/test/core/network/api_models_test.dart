import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_models.dart';
import 'package:mobile/features/auth/data/auth_models.dart';

void main() {
  test('parses success envelope with auth user', () {
    final envelope = ApiEnvelope<AuthUser>.fromJson(
      {
        'success': true,
        'data': {
          'id': 'user-1',
          'phone': '+79991234567',
          'name': null,
          'role': 'RENTER',
          'kycStatus': null,
          'isBlocked': false,
        },
        'error': null,
      },
      (json) => AuthUser.fromJson(json! as Map<String, dynamic>),
    );

    expect(envelope.success, isTrue);
    expect(envelope.data?.phone, '+79991234567');
    expect(envelope.error, isNull);
  });

  test('parses error envelope', () {
    final envelope = ApiEnvelope<Object?>.fromJson(
      {
        'success': false,
        'data': null,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Ошибка',
        },
      },
      (json) => json,
    );

    expect(envelope.success, isFalse);
    expect(envelope.data, isNull);
    expect(envelope.error?.code, 'VALIDATION_ERROR');
  });
}
