import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/payments/data/marketplace_policy_models.dart';
import 'package:mobile/features/payments/data/marketplace_policy_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('parses exact RUB text to policy-bounded minor units', () {
    expect(parseDepositAmountMinor('123', maximumMinor: 10000000), 12300);
    expect(parseDepositAmountMinor('123,4', maximumMinor: 10000000), 12340);
    expect(parseDepositAmountMinor('123.45', maximumMinor: 10000000), 12345);

    for (final value in ['-1', '1.001', '100000.01', '90071992547409.92']) {
      expect(
        () => parseDepositAmountMinor(value, maximumMinor: 10000000),
        throwsA(isA<DepositAmountFormatException>()),
        reason: value,
      );
    }
  });

  test(
    'reads the disabled offline policy from the exact API envelope',
    () async {
      final adapter = CallbackAdapter((options) {
        expect(options.method, 'GET');
        expect(options.path, '/marketplace-policy');
        return jsonResponse({
          'success': true,
          'data': {
            'paymentScenario': 'PAY_ON_HANDOVER',
            'deposit': {
              'enabled': false,
              'currency': 'RUB',
              'maximumMinor': null,
              'policyVersion': null,
              'disputeWindowSeconds': null,
            },
          },
          'error': null,
        });
      });
      final service = MarketplacePolicyService(
        Dio()..httpClientAdapter = adapter,
      );

      final policy = await service.fetch();

      expect(policy.paymentScenario, PaymentScenario.payOnHandover);
      expect(policy.deposit.enabled, isFalse);
      expect(policy.deposit.maximumMinor, isNull);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('reads the fake deposit maximum, version and window exactly', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': {
          'paymentScenario': 'FAKE_SAFE_DEAL',
          'deposit': {
            'enabled': true,
            'currency': 'RUB',
            'maximumMinor': 10000000,
            'policyVersion': 'fake-deposit-2026-09-02',
            'disputeWindowSeconds': 300,
          },
        },
        'error': null,
      }),
    );
    final service = MarketplacePolicyService(
      Dio()..httpClientAdapter = adapter,
    );

    final policy = await service.fetch();

    expect(policy.paymentScenario, PaymentScenario.fakeSafeDeal);
    expect(policy.deposit.enabled, isTrue);
    expect(policy.deposit.currency, 'RUB');
    expect(policy.deposit.maximumMinor, 10000000);
    expect(policy.deposit.policyVersion, 'fake-deposit-2026-09-02');
    expect(policy.deposit.disputeWindowSeconds, 300);
  });

  test('rejects fractional, negative and unsafe policy integers', () async {
    final invalidValues = <Object>[0.5, 0, -1, 9007199254740992];

    for (final value in invalidValues) {
      final service = _serviceForPolicy(_fakePolicyData(maximumMinor: value));

      await _expectInvalidResponse(service, reason: '$value');
    }

    await _expectInvalidResponse(
      _serviceForPolicy(_fakePolicyData(disputeWindowSeconds: 0.5)),
      reason: 'fractional dispute window',
    );
  });

  test('rejects unsupported scenarios and non-RUB currency', () async {
    for (final policy in [
      _fakePolicyData(paymentScenario: 'SAFE_DEAL'),
      _fakePolicyData(paymentScenario: 'UNKNOWN_SCENARIO'),
      _fakePolicyData(currency: 'USD'),
    ]) {
      await _expectInvalidResponse(_serviceForPolicy(policy));
    }
  });

  test(
    'rejects incomplete active and polluted offline policy tuples',
    () async {
      for (final policy in [
        _fakePolicyData(policyVersion: ''),
        _fakePolicyData(policyVersion: '   '),
        _fakePolicyData(policyVersion: null),
        _fakePolicyData(disputeWindowSeconds: 0),
        {
          'paymentScenario': 'PAY_ON_HANDOVER',
          'deposit': {
            'enabled': false,
            'currency': 'RUB',
            'maximumMinor': null,
            'policyVersion': 'stale-policy',
            'disputeWindowSeconds': null,
          },
        },
        {
          'paymentScenario': 'PAY_ON_HANDOVER',
          'deposit': {
            'enabled': false,
            'currency': 'RUB',
            'maximumMinor': 1,
            'policyVersion': null,
            'disputeWindowSeconds': 1,
          },
        },
      ]) {
        await _expectInvalidResponse(_serviceForPolicy(policy));
      }
    },
  );

  test(
    'fails closed when the policy is not wrapped in the API envelope',
    () async {
      final adapter = CallbackAdapter(
        (_) => jsonResponse({
          'paymentScenario': 'FAKE_SAFE_DEAL',
          'deposit': {
            'enabled': true,
            'currency': 'RUB',
            'maximumMinor': 10000000,
            'policyVersion': 'fake-deposit-2026-09-02',
            'disputeWindowSeconds': 300,
          },
        }),
      );
      final service = MarketplacePolicyService(
        Dio()..httpClientAdapter = adapter,
      );

      await expectLater(
        service.fetch(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'INVALID_RESPONSE',
          ),
        ),
      );
      expect(adapter.requests, hasLength(1));
    },
  );
}

Map<String, Object?> _fakePolicyData({
  String paymentScenario = 'FAKE_SAFE_DEAL',
  String currency = 'RUB',
  Object? maximumMinor = 10000000,
  Object? policyVersion = 'fake-deposit-2026-09-02',
  Object? disputeWindowSeconds = 300,
}) {
  return {
    'paymentScenario': paymentScenario,
    'deposit': {
      'enabled': true,
      'currency': currency,
      'maximumMinor': maximumMinor,
      'policyVersion': policyVersion,
      'disputeWindowSeconds': disputeWindowSeconds,
    },
  };
}

MarketplacePolicyService _serviceForPolicy(Map<String, Object?> policy) {
  final adapter = CallbackAdapter(
    (_) => jsonResponse({'success': true, 'data': policy, 'error': null}),
  );
  return MarketplacePolicyService(Dio()..httpClientAdapter = adapter);
}

Future<void> _expectInvalidResponse(
  MarketplacePolicyService service, {
  String? reason,
}) {
  return expectLater(
    service.fetch(),
    throwsA(
      isA<ApiException>().having(
        (error) => error.code,
        'code',
        'INVALID_RESPONSE',
      ),
    ),
    reason: reason,
  );
}
