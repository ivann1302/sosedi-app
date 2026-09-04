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
        if (!_isValidPolicy(policy)) {
          throw const ApiException(
            code: 'INVALID_RESPONSE',
            message: 'Не удалось прочитать платёжную политику',
          );
        }
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

bool _isValidPolicy(MarketplacePolicy policy) {
  final deposit = policy.deposit;
  if (deposit.currency != 'RUB') return false;

  return switch (policy.paymentScenario) {
    PaymentScenario.payOnHandover =>
      !deposit.enabled &&
          deposit.maximumMinor == null &&
          deposit.policyVersion == null &&
          deposit.disputeWindowSeconds == null,
    PaymentScenario.fakeSafeDeal =>
      deposit.enabled &&
          deposit.maximumMinor != null &&
          deposit.maximumMinor! > 0 &&
          deposit.policyVersion != null &&
          deposit.policyVersion!.trim().isNotEmpty &&
          deposit.disputeWindowSeconds != null &&
          deposit.disputeWindowSeconds! > 0,
    PaymentScenario.safeDeal => false,
  };
}
