// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_policy_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MarketplaceDepositPolicy _$MarketplaceDepositPolicyFromJson(
  Map<String, dynamic> json,
) => _MarketplaceDepositPolicy(
  enabled: json['enabled'] as bool,
  currency: json['currency'] as String,
  maximumMinor: _exactNullableSafeIntegerFromJson(json['maximumMinor']),
  policyVersion: json['policyVersion'] as String?,
  disputeWindowSeconds: _exactNullableSafeIntegerFromJson(
    json['disputeWindowSeconds'],
  ),
);

Map<String, dynamic> _$MarketplaceDepositPolicyToJson(
  _MarketplaceDepositPolicy instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'currency': instance.currency,
  'maximumMinor': instance.maximumMinor,
  'policyVersion': instance.policyVersion,
  'disputeWindowSeconds': instance.disputeWindowSeconds,
};

_MarketplacePolicy _$MarketplacePolicyFromJson(Map<String, dynamic> json) =>
    _MarketplacePolicy(
      paymentScenario: $enumDecode(
        _$PaymentScenarioEnumMap,
        json['paymentScenario'],
      ),
      deposit: MarketplaceDepositPolicy.fromJson(
        json['deposit'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$MarketplacePolicyToJson(_MarketplacePolicy instance) =>
    <String, dynamic>{
      'paymentScenario': _$PaymentScenarioEnumMap[instance.paymentScenario]!,
      'deposit': instance.deposit,
    };

const _$PaymentScenarioEnumMap = {
  PaymentScenario.payOnHandover: 'PAY_ON_HANDOVER',
  PaymentScenario.fakeSafeDeal: 'FAKE_SAFE_DEAL',
  PaymentScenario.safeDeal: 'SAFE_DEAL',
};
