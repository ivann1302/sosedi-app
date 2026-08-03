import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'owned_item_models.dart';

final ownedItemsServiceProvider = Provider<OwnedItemsService>((ref) {
  return OwnedItemsService(ref.watch(dioProvider));
});

final ownedItemsProvider = FutureProvider<List<OwnedItem>>(
  (ref) => ref.watch(ownedItemsServiceProvider).fetchOwnedItems(),
  retry: (_, _) => null,
);

final unavailablePeriodsProvider =
    FutureProvider.family<List<UnavailablePeriod>, String>(
      (ref, itemId) =>
          ref.watch(ownedItemsServiceProvider).fetchUnavailablePeriods(itemId),
      retry: (_, _) => null,
    );

class OwnedItemsService {
  const OwnedItemsService(this._dio);

  final Dio _dio;

  Future<List<OwnedItem>> fetchOwnedItems() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/items/mine');
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать объявления',
        );
      }
      final envelope = ApiEnvelope<List<OwnedItem>>.fromJson(
        body,
        (json) => (json! as List<dynamic>)
            .map((item) => OwnedItem.fromJson(item! as Map<String, dynamic>))
            .toList(growable: false),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось загрузить объявления',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось загрузить объявления',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать объявления',
      );
    }
  }

  Future<OwnedItem> updateItem(String id, UpdateItemDraft draft) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/items/$id',
        data: draft.toJson(),
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать объявление',
        );
      }
      final envelope = ApiEnvelope<OwnedItem>.fromJson(
        body,
        (json) => OwnedItem.fromJson(json! as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось обновить объявление',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось обновить объявление',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать объявление',
      );
    }
  }

  Future<OwnedItem> hideItem(String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/items/$id/hide',
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать объявление',
        );
      }
      final envelope = ApiEnvelope<OwnedItem>.fromJson(
        body,
        (json) => OwnedItem.fromJson(json! as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось скрыть объявление',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось скрыть объявление',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать объявление',
      );
    }
  }

  Future<List<UnavailablePeriod>> fetchUnavailablePeriods(String itemId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/items/$itemId/unavailable-periods',
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать календарь',
        );
      }
      final envelope = ApiEnvelope<List<UnavailablePeriod>>.fromJson(
        body,
        (json) => (json! as List<dynamic>)
            .map(
              (period) =>
                  UnavailablePeriod.fromJson(period! as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось загрузить календарь',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось загрузить календарь',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать календарь',
      );
    }
  }

  Future<UnavailablePeriod> createUnavailablePeriod(
    String itemId,
    CreateUnavailablePeriodDraft draft,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/items/$itemId/unavailable-periods',
        data: draft.toJson(),
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать период',
        );
      }
      final envelope = ApiEnvelope<UnavailablePeriod>.fromJson(
        body,
        (json) => UnavailablePeriod.fromJson(json! as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось добавить период',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(error, fallback: 'Не удалось добавить период');
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать период',
      );
    }
  }

  Future<void> deleteUnavailablePeriod(String itemId, String periodId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/items/$itemId/unavailable-periods/$periodId',
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать ответ',
        );
      }
      final envelope = ApiEnvelope<Object?>.fromJson(body, (_) => null);
      if (!envelope.success) {
        throw ApiException(
          code: envelope.error?.code ?? 'API_ERROR',
          message: envelope.error?.message ?? 'Не удалось удалить период',
        );
      }
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(error, fallback: 'Не удалось удалить период');
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать ответ',
      );
    }
  }
}
