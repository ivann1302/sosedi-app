import 'package:dio/dio.dart';

import 'api_exception.dart';

ApiException apiExceptionFromDio(
  DioException error, {
  required String fallback,
}) {
  final body = error.response?.data;
  if (body is Map<String, dynamic>) {
    final apiError = body['error'];
    if (apiError is Map<String, dynamic>) {
      return ApiException(
        code: apiError['code']?.toString() ?? 'API_ERROR',
        message: apiError['message']?.toString() ?? fallback,
      );
    }
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const ApiException(
      code: 'TIMEOUT',
      message: 'Сервер отвечает слишком долго. Попробуйте ещё раз',
    ),
    DioExceptionType.connectionError => const ApiException(
      code: 'OFFLINE',
      message: 'Нет подключения к интернету',
    ),
    _ => ApiException(code: 'NETWORK_ERROR', message: fallback),
  };
}
