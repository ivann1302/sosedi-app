import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'item_models.dart';

final itemServiceProvider = Provider<ItemService>((ref) {
  return ItemService(ref.watch(dioProvider));
});

final itemDetailsProvider = FutureProvider.family<ItemDetails, String>(
  (ref, id) => ref.watch(itemServiceProvider).fetchItem(id),
  retry: (_, _) => null,
);

class ItemService {
  const ItemService(this._dio);

  final Dio _dio;

  Future<ItemDetails> fetchItem(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/items/$id');
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать объявление',
        );
      }

      final envelope = ApiEnvelope<ItemDetails>.fromJson(
        body,
        (json) => ItemDetails.fromJson(json! as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось загрузить объявление',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ApiException(
          code: 'ITEM_NOT_FOUND',
          message: 'Объявление не найдено',
        );
      }
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось загрузить объявление',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать объявление',
      );
    }
  }
}
