import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'marketplace_policy_models.dart';

final marketplacePolicyServiceProvider = Provider<MarketplacePolicyService>((
  ref,
) {
  return MarketplacePolicyService(ref.watch(dioProvider));
});

final marketplacePolicyProvider = FutureProvider<MarketplacePolicy>(
  (ref) => ref.watch(marketplacePolicyServiceProvider).fetch(),
  retry: (_, _) => null,
);

class MarketplacePolicyService {
  const MarketplacePolicyService(this._dio);

  final Dio _dio;

  Future<MarketplacePolicy> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/marketplace-policy',
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать платёжную политику',
        );
      }
      final envelope = ApiEnvelope<MarketplacePolicy>.fromJson(
        body,
        (json) => MarketplacePolicy.fromJson(json! as Map<String, dynamic>),
      );
      final policy = envelope.data;
      if (envelope.success && policy != null) {
        return policy;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message:
            envelope.error?.message ??
            'Не удалось загрузить платёжную политику',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось загрузить платёжную политику',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать платёжную политику',
      );
    }
  }
}
