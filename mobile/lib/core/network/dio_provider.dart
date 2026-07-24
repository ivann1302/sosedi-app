import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_models.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        Headers.contentTypeHeader: Headers.jsonContentType,
      },
    ),
  );

  dio.interceptors.add(
    _AuthInterceptor(
      tokenStorage: ref.watch(tokenStorageProvider),
      baseUrl: AppConfig.apiBaseUrl,
    ),
  );

  return dio;
});

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required this._tokenStorage,
    required this._baseUrl,
  });

  final TokenStorage _tokenStorage;
  final String _baseUrl;
  Future<_RefreshTokens?>? _refreshFuture;

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

    final tokens = await _refreshTokens();
    if (tokens == null) {
      await _tokenStorage.clear();
      handler.next(err);
      return;
    }

    options
      ..headers['Authorization'] = 'Bearer ${tokens.accessToken}'
      ..extra['authRetry'] = true
      ..extra['skipAuthRefresh'] = true;

    try {
      final retryDio = Dio(
        BaseOptions(
          baseUrl: options.baseUrl,
          connectTimeout: options.connectTimeout,
          receiveTimeout: options.receiveTimeout,
          sendTimeout: options.sendTimeout,
        ),
      );
      final response = await retryDio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
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

  Future<_RefreshTokens?> _refreshTokens() {
    _refreshFuture ??= _doRefreshTokens().whenComplete(() {
      _refreshFuture = null;
    });

    return _refreshFuture!;
  }

  Future<_RefreshTokens?> _doRefreshTokens() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      return null;
    }

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: const {
            Headers.contentTypeHeader: Headers.jsonContentType,
          },
        ),
      );

      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
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
        return null;
      }

      final tokens = _RefreshTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return tokens;
    } on DioException {
      return null;
    }
  }
}

class _RefreshTokens {
  const _RefreshTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
