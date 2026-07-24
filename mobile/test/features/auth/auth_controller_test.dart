import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_provider.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('authenticates after successful OTP verification', () async {
    FlutterSecureStorage.setMockInitialValues({});

    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.httpClientAdapter = _AuthFakeAdapter();
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero);

    final controller = container.read(authControllerProvider.notifier);

    expect(await controller.requestOtp('8 (999) 123-45-67'), isTrue);
    expect(container.read(authControllerProvider), isA<AuthCodeSent>());

    expect(await controller.verifyOtp('123456'), isTrue);

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).user.phone, '+79991234567');
  });
}

class _AuthFakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/otp/request') {
      return _json({
        'success': true,
        'data': {
          'phone': '+79991234567',
          'expiresInSeconds': 300,
        },
        'error': null,
      });
    }

    if (options.path == '/auth/otp/verify') {
      return _json({
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

    return _json(
      {
        'success': false,
        'data': null,
        'error': {
          'code': 'NOT_FOUND',
          'message': 'Не найдено',
        },
      },
      statusCode: 404,
    );
  }

  ResponseBody _json(
    Map<String, Object?> body, {
    int statusCode = 200,
  }) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
