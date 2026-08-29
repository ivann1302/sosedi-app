import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'catalog_models.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(ref.watch(dioProvider));
});

class CatalogService {
  const CatalogService(this._dio);

  final Dio _dio;

  Future<CatalogState> fetchItems({
    int limit = 20,
    int offset = 0,
    String search = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? availableFrom,
    String? availableTo,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String sort = 'newest',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/items',
        queryParameters: <String, Object>{
          'limit': limit + 1,
          'offset': offset,
          'sort': sort,
          if (search.isNotEmpty) 'search': search,
          'categoryId': ?categoryId,
          'minPrice': ?minPrice,
          'maxPrice': ?maxPrice,
          'availableFrom': ?availableFrom,
          'availableTo': ?availableTo,
          'latitude': ?latitude,
          'longitude': ?longitude,
          'radiusKm': ?radiusKm,
        },
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать каталог',
        );
      }

      final envelope = ApiEnvelope<List<CatalogItem>>.fromJson(
        body,
        (json) => (json! as List<dynamic>)
            .map((item) => CatalogItem.fromJson(item! as Map<String, dynamic>))
            .toList(growable: false),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        final hasMore = data.length > limit;
        final items = hasMore ? data.take(limit).toList(growable: false) : data;
        return CatalogState(
          items: items,
          hasMore: hasMore,
          nextOffset: offset + items.length,
        );
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось загрузить каталог',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось загрузить каталог',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать каталог',
      );
    }
  }

  Future<List<CatalogCategory>> fetchCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/categories');
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать категории',
        );
      }

      final envelope = ApiEnvelope<List<CatalogCategory>>.fromJson(
        body,
        (json) => (json! as List<dynamic>)
            .map(
              (category) =>
                  CatalogCategory.fromJson(category! as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось загрузить категории',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось загрузить категории',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать категории',
      );
    }
  }
}
