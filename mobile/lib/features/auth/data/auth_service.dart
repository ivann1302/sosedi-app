import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

class AuthService {
  const AuthService(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<OtpRequestResult> requestOtp(String phone) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/otp/request',
        data: {'phone': phone},
        options: _skipAuthOptions(),
      );

      return _readData(
        response,
        (json) => OtpRequestResult.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<AuthTokens> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/otp/verify',
        data: {'phone': phone, 'code': code},
        options: _skipAuthOptions(),
      );
      final tokens = _readData(
        response,
        (json) => AuthTokens.fromJson(json! as Map<String, dynamic>),
      );

      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return tokens;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<AuthTokens> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw const ApiException(code: 'UNAUTHORIZED', message: 'Войдите заново');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: _skipAuthOptions(),
      );
      final tokens = _readData(
        response,
        (json) => AuthTokens.fromJson(json! as Map<String, dynamic>),
      );

      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return tokens;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<AuthUser> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');

      return _readData(
        response,
        (json) => AuthUser.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken != null) {
        await _dio.post<Map<String, dynamic>>(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
          options: _skipAuthOptions(),
        );
      }
    } catch (_) {
      // Удалённый logout не должен мешать немедленному локальному выходу.
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() {
    return _tokenStorage.clear();
  }

  Future<List<UserSession>> sessions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/sessions');
      return _readData(
        response,
        (json) => (json! as List<dynamic>)
            .map(
              (item) => UserSession.fromJson(
                item! as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/auth/sessions/$sessionId',
      );
      _readData(
        response,
        (json) => LogoutResult.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<void> revokeAllSessions() async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/auth/sessions',
      );
      _readData(
        response,
        (json) => LogoutResult.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Options _skipAuthOptions() {
    return Options(extra: const {'skipAuth': true, 'skipAuthRefresh': true});
  }

  T _readData<T>(
    Response<Map<String, dynamic>> response,
    T Function(Object?) fromJsonT,
  ) {
    try {
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать ответ сервера',
        );
      }

      final envelope = ApiEnvelope<T>.fromJson(body, fromJsonT);
      final data = envelope.data;

      if (envelope.success && data != null) {
        return data;
      }

      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Ошибка сервера',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать ответ сервера',
      );
    }
  }

  ApiException _toApiException(DioException error) {
    final body = error.response?.data;
    if (body is Map<String, dynamic>) {
      try {
        final envelope = ApiEnvelope<Object?>.fromJson(body, (json) => json);
        final apiError = envelope.error;

        if (apiError != null) {
          return ApiException(code: apiError.code, message: apiError.message);
        }
      } catch (_) {
        return const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать ответ сервера',
        );
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Не удалось связаться с сервером',
      );
    }

    return const ApiException(
      code: 'API_ERROR',
      message: 'Не удалось выполнить запрос',
    );
  }
}
