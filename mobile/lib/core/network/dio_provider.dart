import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_events.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_models.dart';

final dioProvider = Provider<Dio>((ref) {
  return createApiDio(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionInvalidated: () {
      ref.read(sessionInvalidationProvider.notifier).notify();
    },
  );
});

Dio createApiDio({
  required String baseUrl,
  required TokenStorage tokenStorage,
  HttpClientAdapter? adapter,
  void Function()? onSessionInvalidated,
}) {
  final dio = Dio(_baseOptions(baseUrl));
  final transport = Dio(_baseOptions(baseUrl));

  if (adapter != null) {
    dio.httpClientAdapter = adapter;
    transport.httpClientAdapter = adapter;
  }

  dio.interceptors.add(
    _AuthInterceptor(
      tokenStorage: tokenStorage,
      transport: transport,
      onSessionInvalidated: onSessionInvalidated,
    ),
  );

  return dio;
}

BaseOptions _baseOptions(String baseUrl) {
  return BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: const {Headers.contentTypeHeader: Headers.jsonContentType},
  );
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this._tokenStorage,
    required this._transport,
    this._onSessionInvalidated,
  });

  final TokenStorage _tokenStorage;
  final Dio _transport;
  final void Function()? _onSessionInvalidated;
  Future<_RefreshResult>? _refreshFuture;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;

    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    try {
      final currentAccessToken = await _tokenStorage.readAccessToken();
      if (_usedStaleAccessToken(options, currentAccessToken)) {
        final response = await _retry(options, currentAccessToken!);
        handler.resolve(response);
        return;
      }

      final result = await _refreshTokens();
      switch (result) {
        case _RefreshSucceeded(:final tokens):
          final response = await _retry(options, tokens.accessToken);
          handler.resolve(response);
        case _RefreshRejected():
          await _tokenStorage.clear();
          _onSessionInvalidated?.call();
          handler.next(err);
        case _RefreshFailed(:final error):
          handler.next(error);
      }
    } on DioException catch (error) {
      handler.next(error);
    } catch (error, stackTrace) {
      handler.next(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  bool _shouldRefresh(DioException error) {
    final options = error.requestOptions;
    final path = options.path;

    if (error.response?.statusCode != 401) {
      return false;
    }

    if (options.extra['authRetry'] == true ||
        options.extra['skipAuthRefresh'] == true) {
      return false;
    }

    return !path.startsWith('/auth/otp') &&
        path != '/auth/refresh' &&
        path != '/auth/logout';
  }

  bool _usedStaleAccessToken(
    RequestOptions options,
    String? currentAccessToken,
  ) {
    if (currentAccessToken == null) {
      return false;
    }

    final authorization = options.headers['Authorization'];
    return authorization is String &&
        authorization.startsWith('Bearer ') &&
        authorization != 'Bearer $currentAccessToken';
  }

  Future<Response<dynamic>> _retry(RequestOptions options, String accessToken) {
    final retryOptions = options.copyWith(
      headers: {...options.headers, 'Authorization': 'Bearer $accessToken'},
      extra: {...options.extra, 'authRetry': true, 'skipAuthRefresh': true},
    );

    return _transport.fetch<dynamic>(retryOptions);
  }

  Future<_RefreshResult> _refreshTokens() {
    _refreshFuture ??= _doRefreshTokens().whenComplete(() {
      _refreshFuture = null;
    });

    return _refreshFuture!;
  }

  Future<_RefreshResult> _doRefreshTokens() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      return const _RefreshRejected();
    }

    Response<Map<String, dynamic>> response;
    try {
      response = await _transport.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        return const _RefreshRejected();
      }

      return _RefreshFailed(error);
    }

    final _RefreshTokens tokens;
    try {
      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => json! as Map<String, dynamic>,
      );
      final data = envelope.data;
      final accessToken = data?['accessToken'];
      final nextRefreshToken = data?['refreshToken'];

      if (!envelope.success ||
          accessToken is! String ||
          nextRefreshToken is! String) {
        throw const FormatException('Invalid refresh response');
      }

      tokens = _RefreshTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );
    } catch (error, stackTrace) {
      return _RefreshFailed(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }

    try {
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } catch (_) {
      return const _RefreshRejected();
    }

    return _RefreshSucceeded(tokens);
  }
}

sealed class _RefreshResult {
  const _RefreshResult();
}

class _RefreshSucceeded extends _RefreshResult {
  const _RefreshSucceeded(this.tokens);

  final _RefreshTokens tokens;
}

class _RefreshRejected extends _RefreshResult {
  const _RefreshRejected();
}

class _RefreshFailed extends _RefreshResult {
  const _RefreshFailed(this.error);

  final DioException error;
}

class _RefreshTokens {
  const _RefreshTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}
