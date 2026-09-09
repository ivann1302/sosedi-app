import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/session_events.dart';
import 'package:mobile/core/network/dio_provider.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';

import '../../support/network_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts unauthenticated when no session exists', () async {
    final storage = MemoryTokenStorage();
    final container = createContainer(storage, (_) => notFoundResponse());
    addTearDown(container.dispose);

    expect(await waitForState<AuthUnauthenticated>(container), isNotNull);
    expect(storage.clearCount, 0);
  });

  test('clears an orphan access token during restore', () async {
    final storage = MemoryTokenStorage(accessToken: 'orphan-access');
    final container = createContainer(storage, (_) => notFoundResponse());
    addTearDown(container.dispose);

    await waitForState<AuthUnauthenticated>(container);

    expect(storage.accessToken, isNull);
    expect(storage.clearCount, 1);
  });

  test('restores a valid session from /auth/me', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final container = createContainer(
      storage,
      (options) =>
          options.path == '/auth/me' ? userResponse() : notFoundResponse(),
    );
    addTearDown(container.dispose);

    final state = await waitForState<AuthAuthenticated>(container);

    expect(state.user.phone, '+79991234567');
    expect(storage.clearCount, 0);
  });

  test('hides protected state while revalidating a resumed session', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final resumedResponse = Completer<ResponseBody>();
    var meRequests = 0;
    final container = createContainer(storage, (options) {
      if (options.path != '/auth/me') {
        return notFoundResponse();
      }

      meRequests += 1;
      if (meRequests == 1) {
        return userResponse();
      }

      return resumedResponse.future;
    });
    addTearDown(container.dispose);
    await waitForState<AuthAuthenticated>(container);

    final validation = container
        .read(authControllerProvider.notifier)
        .validateSessionOnResume();

    expect(container.read(authControllerProvider), isA<AuthLoading>());

    resumedResponse.complete(
      jsonResponse({
        'success': false,
        'data': null,
        'error': {'code': 'UNAUTHORIZED', 'message': 'Войдите заново'},
      }, statusCode: 401),
    );
    await validation;

    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('clears a session rejected by the server', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'expired-access',
      refreshToken: 'rejected-refresh',
    );
    final container = createContainer(
      storage,
      (_) => jsonResponse({
        'success': false,
        'data': null,
        'error': {'code': 'UNAUTHORIZED', 'message': 'Войдите заново'},
      }, statusCode: 401),
    );
    addTearDown(container.dispose);

    await waitForState<AuthUnauthenticated>(container);

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(storage.clearCount, 1);
  });

  test('keeps tokens when session restore fails temporarily', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final container = createContainer(storage, (options) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    });
    addTearDown(container.dispose);

    final state = await waitForState<AuthUnauthenticated>(container);

    expect(state.errorMessage, 'Не удалось связаться с сервером');
    expect(storage.accessToken, 'access-token');
    expect(storage.refreshToken, 'refresh-token');
    expect(storage.clearCount, 0);
  });

  test('retries a temporary session restore on the next resume', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    var meRequests = 0;
    final container = createContainer(storage, (options) {
      if (options.path != '/auth/me') {
        return notFoundResponse();
      }

      meRequests += 1;
      if (meRequests == 1) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );
      }
      return userResponse();
    });
    addTearDown(container.dispose);
    final failed = await waitForState<AuthUnauthenticated>(container);
    expect(failed.errorMessage, 'Не удалось связаться с сервером');

    await container
        .read(authControllerProvider.notifier)
        .validateSessionOnResume();

    final restored = await waitForState<AuthAuthenticated>(container);
    expect(restored.user.phone, '+79991234567');
    expect(meRequests, 2);
  });

  test('reacts to session invalidation from the network layer', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final container = createContainer(storage, (_) => userResponse());
    addTearDown(container.dispose);
    await waitForState<AuthAuthenticated>(container);

    container.read(sessionInvalidationProvider.notifier).notify();

    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('runs the OTP login and local-first logout flow', () async {
    final storage = MemoryTokenStorage();
    final logoutRelease = Completer<void>();
    final container = createContainer(storage, (options) async {
      switch (options.path) {
        case '/auth/otp/request':
          return otpResponse();
        case '/auth/otp/verify':
          return authTokensResponse();
        case '/auth/logout':
          await logoutRelease.future;
          return emptySuccessResponse();
        default:
          return notFoundResponse();
      }
    });
    addTearDown(container.dispose);
    await waitForState<AuthUnauthenticated>(container);
    final controller = container.read(authControllerProvider.notifier);

    expect(await controller.requestOtp('8 (999) 123-45-67'), isTrue);
    expect(container.read(authControllerProvider), isA<AuthCodeSent>());

    expect(await controller.verifyOtp('123456'), isTrue);
    final authenticated = container.read(authControllerProvider);
    expect(authenticated, isA<AuthAuthenticated>());
    expect((authenticated as AuthAuthenticated).user.phone, '+79991234567');
    expect(storage.refreshToken, 'refresh-token');

    final logout = controller.logout();
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
    logoutRelease.complete();
    await logout;
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('does not submit two OTP requests concurrently', () async {
    final storage = MemoryTokenStorage();
    final release = Completer<void>();
    var requests = 0;
    final container = createContainer(storage, (options) async {
      if (options.path == '/auth/otp/request') {
        requests += 1;
        await release.future;
        return otpResponse();
      }
      return notFoundResponse();
    });
    addTearDown(container.dispose);
    await waitForState<AuthUnauthenticated>(container);
    final controller = container.read(authControllerProvider.notifier);

    final first = controller.requestOtp('+79991234567');
    final second = controller.requestOtp('+79991234567');

    expect(await second, isFalse);
    release.complete();
    expect(await first, isTrue);
    expect(requests, 1);
  });

  test('keeps the OTP step after a verification error', () async {
    final storage = MemoryTokenStorage();
    final container = createContainer(storage, (options) {
      if (options.path == '/auth/otp/request') {
        return otpResponse();
      }
      return jsonResponse({
        'success': false,
        'data': null,
        'error': {'code': 'OTP_INVALID', 'message': 'Неверный код'},
      }, statusCode: 401);
    });
    addTearDown(container.dispose);
    await waitForState<AuthUnauthenticated>(container);
    final controller = container.read(authControllerProvider.notifier);
    await controller.requestOtp('+79991234567');

    expect(await controller.verifyOtp('000000'), isFalse);

    final state = container.read(authControllerProvider) as AuthCodeSent;
    expect(state.errorMessage, 'Неверный код');
    expect(state.isSubmitting, isFalse);
  });
}

ProviderContainer createContainer(
  MemoryTokenStorage storage,
  FutureOr<ResponseBody> Function(RequestOptions options) callback,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.httpClientAdapter = CallbackAdapter(callback);

  return ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      dioProvider.overrideWithValue(dio),
    ],
  )..read(authControllerProvider);
}

Future<T> waitForState<T extends AuthState>(ProviderContainer container) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    final state = container.read(authControllerProvider);
    if (state is T) {
      return state;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  throw TestFailure(
    'AuthController did not reach $T. '
    'Last state: ${container.read(authControllerProvider)}',
  );
}

ResponseBody otpResponse() {
  return jsonResponse({
    'success': true,
    'data': {'phone': '+79991234567', 'expiresInSeconds': 300},
    'error': null,
  });
}

ResponseBody authTokensResponse() {
  return jsonResponse({
    'success': true,
    'data': {
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'user': userJson(),
    },
    'error': null,
  });
}

ResponseBody userResponse() {
  return jsonResponse({'success': true, 'data': userJson(), 'error': null});
}

ResponseBody emptySuccessResponse() {
  return jsonResponse({
    'success': true,
    'data': <String, Object?>{},
    'error': null,
  });
}

ResponseBody notFoundResponse() {
  return jsonResponse({
    'success': false,
    'data': null,
    'error': {'code': 'NOT_FOUND', 'message': 'Не найдено'},
  }, statusCode: 404);
}

Map<String, Object?> userJson() {
  return {
    'id': 'user-1',
    'phone': '+79991234567',
    'name': null,
    'role': 'USER',
    'kycStatus': null,
    'isBlocked': false,
  };
}
