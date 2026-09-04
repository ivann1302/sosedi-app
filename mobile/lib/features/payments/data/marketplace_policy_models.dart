import 'package:freezed_annotation/freezed_annotation.dart';

part 'marketplace_policy_models.freezed.dart';
part 'marketplace_policy_models.g.dart';

const _maximumSafeInteger = 9007199254740991;

class DepositAmountFormatException implements Exception {
  const DepositAmountFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

int parseDepositAmountMinor(String value, {required int maximumMinor}) {
  final match = RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$').firstMatch(value.trim());
  if (match == null) {
    throw const DepositAmountFormatException(
      'Введите неотрицательную сумму, не более двух знаков после запятой',
    );
  }
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final amount =
      BigInt.parse(match.group(1)!) * BigInt.from(100) +
      BigInt.parse(fraction.isEmpty ? '0' : fraction);
  if (amount > BigInt.from(_maximumSafeInteger)) {
    throw const DepositAmountFormatException('Сумма слишком велика');
  }
  if (maximumMinor < 0 || amount > BigInt.from(maximumMinor)) {
    throw const DepositAmountFormatException(
      'Сумма превышает максимальный залог',
    );
  }
  return amount.toInt();
}

String formatDepositRubles(int amountMinor) {
  final amount = BigInt.from(amountMinor);
  final whole = (amount ~/ BigInt.from(100)).toString();
  final grouped = StringBuffer();
  for (var index = 0; index < whole.length; index += 1) {
    if (index > 0 && (whole.length - index) % 3 == 0) {
      grouped.write(' ');
    }
    grouped.write(whole[index]);
  }
  final fraction = (amount % BigInt.from(100)).toString().padLeft(2, '0');
  return fraction == '00' ? grouped.toString() : '$grouped,$fraction';
}

enum PaymentScenario {
  @JsonValue('PAY_ON_HANDOVER')
  payOnHandover,
  @JsonValue('FAKE_SAFE_DEAL')
  fakeSafeDeal,
  @JsonValue('SAFE_DEAL')
  safeDeal,
}

@freezed
abstract class MarketplaceDepositPolicy with _$MarketplaceDepositPolicy {
  const factory MarketplaceDepositPolicy({
    required bool enabled,
    required String currency,
    required int? maximumMinor,
    required String? policyVersion,
    required int? disputeWindowSeconds,
  }) = _MarketplaceDepositPolicy;

  factory MarketplaceDepositPolicy.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceDepositPolicyFromJson(json);
}

@Freezed(copyWith: false)
abstract class MarketplacePolicy with _$MarketplacePolicy {
  const factory MarketplacePolicy({
    required PaymentScenario paymentScenario,
    required MarketplaceDepositPolicy deposit,
  }) = _MarketplacePolicy;

  factory MarketplacePolicy.fromJson(Map<String, dynamic> json) =>
      _$MarketplacePolicyFromJson(json);
}
