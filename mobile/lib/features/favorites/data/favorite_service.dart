import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import '../../catalog/data/catalog_models.dart';

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.watch(dioProvider));
});

class FavoriteService {
  const FavoriteService(this._dio);

  final Dio _dio;

  Future<List<CatalogItem>> list() async {
    final body = await _request(() => _dio.get('/items/favorites'));
    final envelope = ApiEnvelope<List<CatalogItem>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map((value) => CatalogItem.fromJson(value! as Map<String, dynamic>))
          .toList(growable: false),
    );
    return _data(envelope, 'Не удалось загрузить избранное');
  }

  Future<void> add(String itemId) =>
      _mutate(itemId, () => _dio.put('/items/$itemId/favorite'));

  Future<void> remove(String itemId) =>
      _mutate(itemId, () => _dio.delete('/items/$itemId/favorite'));

  Future<void> _mutate(
    String itemId,
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    final body = await _request(request);
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
      body,
      (json) => json! as Map<String, dynamic>,
    );
    final result = _data(envelope, 'Не удалось обновить избранное');
    if (result['itemId'] != itemId) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось обновить избранное',
      );
    }
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
          message: 'Не удалось прочитать избранное',
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось обновить избранное',
      );
    }
  }

  T _data<T>(ApiEnvelope<T> envelope, String fallback) {
    final data = envelope.data;
    if (envelope.success && data != null) {
      return data;
    }
    throw ApiException(
      code: envelope.error?.code ?? 'API_ERROR',
      message: envelope.error?.message ?? fallback,
    );
  }
}
