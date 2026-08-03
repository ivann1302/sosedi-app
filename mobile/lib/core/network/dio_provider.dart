import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../auth/session_events.dart';
import '../compatibility/compatibility_gate.dart';
import '../config/app_config.dart';
import '../storage/installation_id_storage.dart';
import '../storage/token_storage.dart';
import 'api_models.dart';

final dioProvider = Provider<Dio>((ref) {
  final mobileVersion = PackageInfo.fromPlatform().then((info) => info.version);
  return createApiDio(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
    installationId: ref.watch(installationIdStorageProvider).getOrCreate(),
    mobileVersion: mobileVersion,
    mobilePlatform: defaultTargetPlatform.name,
    onSessionInvalidated: () {
      ref.read(sessionInvalidationProvider.notifier).notify();
    },
    onUpdateRequired: (requirement) {
      ref
          .read(compatibilityRequirementProvider.notifier)
          .requireUpdate(requirement);
    },
  );
});

final apiCompatibilityCheckProvider = FutureProvider<void>((ref) async {
  try {
    await ref
        .watch(dioProvider)
        .get<void>(
          '/health',
          options: Options(
            extra: const {'skipAuth': true, 'skipAuthRefresh': true},
          ),
        );
  } on DioException {
    // Network failures remain retryable and must not force an update.
  }
});

Dio createApiDio({
  required String baseUrl,
  required TokenStorage tokenStorage,
  Future<String>? installationId,
  Future<String>? mobileVersion,
  String? mobilePlatform,
  HttpClientAdapter? adapter,
  void Function()? onSessionInvalidated,
  void Function(UpdateRequirement)? onUpdateRequired,
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
      installationId: installationId,
      mobileVersion: mobileVersion,
      mobilePlatform: mobilePlatform,
      onSessionInvalidated: onSessionInvalidated,
      onUpdateRequired: onUpdateRequired,
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
    this._installationId,
    this._mobileVersion,
    this._mobilePlatform,
    this._onSessionInvalidated,
    this._onUpdateRequired,
  });

  final TokenStorage _tokenStorage;
  final Dio _transport;
  final Future<String>? _installationId;
  final Future<String>? _mobileVersion;
  final String? _mobilePlatform;
  final void Function()? _onSessionInvalidated;
  final void Function(UpdateRequirement)? _onUpdateRequired;
  Future<_RefreshResult>? _refreshFuture;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _addClientHeaders(options.headers);
    final installationId = await _installationId;
    if (installationId != null) {
      options.headers['X-Installation-Id'] = installationId;
    }

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
    final updateRequirement = UpdateRequirement.fromResponse(err.response);
    if (updateRequirement != null) {
      _onUpdateRequired?.call(updateRequirement);
    }
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
        options: Options(headers: await _clientHeaders()),
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

  Future<void> _addClientHeaders(Map<String, dynamic> headers) async {
    headers.addAll(await _clientHeaders());
  }

  Future<Map<String, String>> _clientHeaders() async {
    final headers = <String, String>{'X-Api-Version': '1'};
    final mobileVersion = await _mobileVersion;
    if (mobileVersion != null) {
      headers['X-Mobile-Version'] = mobileVersion;
    }
    if (_mobilePlatform case final mobilePlatform?) {
      headers['X-Mobile-Platform'] = mobilePlatform;
    }
    return headers;
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
