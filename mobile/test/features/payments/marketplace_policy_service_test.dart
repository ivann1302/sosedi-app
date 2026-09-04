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
