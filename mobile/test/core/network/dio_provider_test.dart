import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_provider.dart';

import '../../support/network_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adds the access token only when auth is not skipped', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
    final adapter = CallbackAdapter((_) => jsonResponse({'ok': true}));
    final dio = createApiDio(
      baseUrl: 'http://test',
      tokenStorage: storage,
      adapter: adapter,
    );

    await dio.get<Map<String, dynamic>>('/protected');
    await dio.get<Map<String, dynamic>>(
      '/public',
      options: Options(extra: {'skipAuth': true}),
    );

    expect(adapter.requests[0].headers['Authorization'], 'Bearer access-token');
    expect(adapter.requests[1].headers['Authorization'], isNull);
  });

  test('uses one refresh for concurrent 401 responses', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    final bothOldRequestsStarted = Completer<void>();
    var oldRequests = 0;
    var retriedRequests = 0;
    var refreshRequests = 0;

    final adapter = CallbackAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshRequests += 1;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return tokenResponse();
      }

      if (options.path == '/protected') {
        if (options.headers['Authorization'] == 'Bearer old-access') {
          oldRequests += 1;
          if (oldRequests == 2) {
            bothOldRequestsStarted.complete();
          }
          await bothOldRequestsStarted.future;
          return jsonResponse({'error': 'expired'}, statusCode: 401);
        }

        if (options.headers['Authorization'] == 'Bearer new-access') {
          retriedRequests += 1;
          return jsonResponse({'ok': true});
        }
      }

      return jsonResponse({'error': 'unexpected'}, statusCode: 500);
    });
    final dio = createApiDio(
      baseUrl: 'http://test',
      tokenStorage: storage,
      adapter: adapter,
    );

    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/protected'),
      dio.get<Map<String, dynamic>>('/protected'),
    ]);

    expect(responses, hasLength(2));
    expect(refreshRequests, 1);
    expect(retriedRequests, 2);
    expect(storage.accessToken, 'new-access');
    expect(storage.refreshToken, 'new-refresh');
  });

  test('retries a late old-token 401 without a second refresh', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    final firstRefreshCompleted = Completer<void>();
    var oldRequests = 0;
    var refreshRequests = 0;

    final adapter = CallbackAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshRequests += 1;
        return tokenResponse(onCreated: firstRefreshCompleted.complete);
      }

      if (options.path == '/protected' &&
          options.headers['Authorization'] == 'Bearer old-access') {
        oldRequests += 1;
        if (oldRequests == 2) {
          await firstRefreshCompleted.future;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        return jsonResponse({'error': 'expired'}, statusCode: 401);
      }

      if (options.path == '/protected' &&
          options.headers['Authorization'] == 'Bearer new-access') {
        return jsonResponse({'ok': true});
      }

      return jsonResponse({'error': 'unexpected'}, statusCode: 500);
    });
    final dio = createApiDio(
      baseUrl: 'http://test',
      tokenStorage: storage,
      adapter: adapter,
    );

    await Future.wait([
      dio.get<Map<String, dynamic>>('/protected'),
      dio.get<Map<String, dynamic>>('/protected'),
    ]);

    expect(refreshRequests, 1);
  });

  test('clears the session when refresh token is rejected', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    var invalidations = 0;
    final adapter = CallbackAdapter((options) {
      return jsonResponse({'error': 'unauthorized'}, statusCode: 401);
    });
    final dio = createApiDio(
      baseUrl: 'http://test',
      tokenStorage: storage,
      adapter: adapter,
      onSessionInvalidated: () => invalidations += 1,
    );

    await expectLater(
      dio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(storage.clearCount, 1);
    expect(invalidations, 1);
  });

  test('keeps the session when refresh fails temporarily', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    var invalidations = 0;
    final adapter = CallbackAdapter((options) {
      if (options.path == '/auth/refresh') {
        return jsonResponse({'error': 'server'}, statusCode: 500);
      }

      return jsonResponse({'error': 'expired'}, statusCode: 401);
    });
    final dio = createApiDio(
      baseUrl: 'http://test',
      tokenStorage: storage,
      adapter: adapter,
      onSessionInvalidated: () => invalidations += 1,
    );

    await expectLater(
      dio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(storage.accessToken, 'old-access');
    expect(storage.refreshToken, 'old-refresh');
    expect(storage.clearCount, 0);
    expect(invalidations, 0);
  });

  test('retries a request at most once', () async {
    final storage = MemoryTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    var protectedRequests = 0;
    var refreshRequests = 0;
    final adapter = CallbackAdapter((options) {
      if (options.path == '/auth/refresh') {
        refreshRequests += 1;
        return tokenResponse();
      }

      protectedRequests += 1;
      return jsonResponse({'error': 'unauthorized'}, statusCode: 401);
    });
    final dio = createApiDio(
      baseUrl: 'http://test',
      tokenStorage: storage,
      adapter: adapter,
    );

    await expectLater(
      dio.get<Map<String, dynamic>>('/protected'),
      throwsA(isA<DioException>()),
    );

    expect(refreshRequests, 1);
    expect(protectedRequests, 2);
  });
}

ResponseBody tokenResponse({void Function()? onCreated}) {
  onCreated?.call();
  return jsonResponse({
    'success': true,
    'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
    'error': null,
  });
}
