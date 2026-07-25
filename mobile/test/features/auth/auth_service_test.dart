import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/data/auth_service.dart';

import '../../support/network_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requests OTP with auth refresh disabled', () async {
    final storage = MemoryTokenStorage();
    late RequestOptions captured;
    final service = createService(
      storage,
      CallbackAdapter((options) {
        captured = options;
        return jsonResponse({
          'success': true,
          'data': {'phone': '+79991234567', 'expiresInSeconds': 300},
          'error': null,
        });
      }),
    );

    final result = await service.requestOtp('+79991234567');

    expect(result.phone, '+79991234567');
    expect(captured.path, '/auth/otp/request');
    expect(captured.data, {'phone': '+79991234567'});
    expect(captured.extra['skipAuth'], isTrue);
    expect(captured.extra['skipAuthRefresh'], isTrue);
  });

  test('verifies OTP and stores both tokens', () async {
    final storage = MemoryTokenStorage();
    final service = createService(
      storage,
      CallbackAdapter((_) => authTokensResponse()),
    );

    final tokens = await service.verifyOtp(
      phone: '+79991234567',
      code: '123456',
    );

    expect(tokens.user.phone, '+79991234567');
    expect(storage.accessToken, 'access-token');
    expect(storage.refreshToken, 'refresh-token');
  });

  test('maps an API error envelope to ApiException', () async {
    final service = createService(
      MemoryTokenStorage(),
      CallbackAdapter(
        (_) => jsonResponse({
          'success': false,
          'data': null,
          'error': {'code': 'OTP_INVALID', 'message': 'Неверный код'},
        }, statusCode: 401),
      ),
    );

    await expectLater(
      service.verifyOtp(phone: '+79991234567', code: '000000'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'OTP_INVALID')
            .having((error) => error.message, 'message', 'Неверный код'),
      ),
    );
  });

  test('maps connection failures to NETWORK_ERROR', () async {
    final service = createService(
      MemoryTokenStorage(),
      CallbackAdapter((options) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }),
    );

    await expectLater(
      service.requestOtp('+79991234567'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'NETWORK_ERROR',
        ),
      ),
    );
  });

  test('maps a malformed success response to INVALID_RESPONSE', () async {
    final service = createService(
      MemoryTokenStorage(),
      CallbackAdapter(
        (_) => jsonResponse({
          'success': true,
          'data': {'accessToken': 42, 'refreshToken': null},
          'error': null,
        }),
      ),
    );

    await expectLater(
      service.verifyOtp(phone: '+79991234567', code: '123456'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });

  test('requires a refresh token before calling refresh', () async {
    final adapter = CallbackAdapter((_) => authTokensResponse());
    final service = createService(MemoryTokenStorage(), adapter);

    await expectLater(
      service.refresh(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'UNAUTHORIZED',
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('clears local tokens when offline logout cannot reach API', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final service = createService(
      storage,
      CallbackAdapter((options) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }),
    );

    await service.logout();

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(storage.clearCount, 1);
  });

  test(
    'clears local tokens when secure storage cannot read refresh token',
    () async {
      final storage = ReadFailingTokenStorage(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
      );
      final adapter = CallbackAdapter((_) => authTokensResponse());
      final service = createService(storage, adapter);

      await service.logout();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.clearCount, 1);
      expect(adapter.requests, isEmpty);
    },
  );
}

AuthService createService(MemoryTokenStorage storage, CallbackAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.httpClientAdapter = adapter;
  return AuthService(dio, storage);
}

ResponseBody authTokensResponse() {
  return jsonResponse({
    'success': true,
    'data': {
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'user': {
        'id': 'user-1',
        'phone': '+79991234567',
        'name': null,
        'role': 'RENTER',
        'kycStatus': null,
        'isBlocked': false,
      },
    },
    'error': null,
  });
}

class ReadFailingTokenStorage extends MemoryTokenStorage {
  ReadFailingTokenStorage({super.accessToken, super.refreshToken});

  @override
  Future<String?> readRefreshToken() {
    throw const FormatException('Secure storage is unavailable');
  }
}
