import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'safety_models.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  return SafetyService(ref.watch(dioProvider));
});

final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUser>>(
  (ref) => ref.watch(safetyServiceProvider).listBlockedUsers(),
  retry: (_, _) => null,
);

class SafetyService {
  const SafetyService(this._dio);

  final Dio _dio;

  Future<void> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    final body = await _request(
      () => _dio.post(
        '/reports',
        data: {
          'targetType': targetType,
          'targetId': targetId,
          'reason': reason,
          'description': description.trim(),
        },
      ),
    );
    _requireSuccess(body, 'Не удалось отправить жалобу');
  }

  Future<void> blockUser(String userId) async {
    final body = await _request(() => _dio.post('/users/blocks/$userId'));
    _requireSuccess(body, 'Не удалось заблокировать пользователя');
  }

  Future<List<BlockedUser>> listBlockedUsers() async {
    final body = await _request(() => _dio.get('/users/blocks'));
    final envelope = ApiEnvelope<List<BlockedUser>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map((value) => BlockedUser.fromJson(value! as Map<String, dynamic>))
          .toList(growable: false),
    );
    final data = envelope.data;
    if (envelope.success && data != null) {
      return data;
    }
    throw ApiException(
      code: envelope.error?.code ?? 'API_ERROR',
      message:
          envelope.error?.message ??
          'Не удалось загрузить заблокированных пользователей',
    );
  }

  Future<void> unblockUser(String userId) async {
    final body = await _request(() => _dio.delete('/users/blocks/$userId'));
    _requireSuccess(body, 'Не удалось разблокировать пользователя');
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать ответ',
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Действие временно недоступно',
      );
    }
  }

  void _requireSuccess(Map<String, dynamic> body, String fallback) {
    if (body['success'] == true) {
      return;
    }
    final error = body['error'];
    throw ApiException(
      code: error is Map<String, dynamic>
          ? error['code']?.toString() ?? 'API_ERROR'
          : 'API_ERROR',
      message: error is Map<String, dynamic>
          ? error['message']?.toString() ?? fallback
          : fallback,
    );
  }
}
