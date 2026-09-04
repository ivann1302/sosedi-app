import 'package:freezed_annotation/freezed_annotation.dart';

import '../../catalog/data/catalog_models.dart';

part 'owned_item_models.freezed.dart';
part 'owned_item_models.g.dart';

double _doubleFromJson(Object value) => (value as num).toDouble();
double? _nullableDoubleFromJson(Object? value) =>
    value == null ? null : (value as num).toDouble();

@freezed
abstract class OwnedItem with _$OwnedItem {
  const factory OwnedItem({
    required String id,
    required String title,
    required String description,
    required String condition,
    required String completeness,
    required String handoverTerms,
    required String status,
    required String publicArea,
    required String address,
    @JsonKey(fromJson: _doubleFromJson) required double latitude,
    @JsonKey(fromJson: _doubleFromJson) required double longitude,
    @JsonKey(fromJson: _doubleFromJson) required double pricePerDay,
    @JsonKey(fromJson: _nullableDoubleFromJson) required double? depositAmount,
    required CatalogCategory category,
    required DateTime updatedAt,
    required List<CatalogPhoto> photos,
    String? rejectReason,
  }) = _OwnedItem;

  factory OwnedItem.fromJson(Map<String, dynamic> json) =>
      _$OwnedItemFromJson(json);
}

@freezed
abstract class UpdateItemDraft with _$UpdateItemDraft {
  const factory UpdateItemDraft({
    required String title,
    required String description,
    required String categoryId,
    required String condition,
    required String completeness,
    required String handoverTerms,
    required double pricePerDay,
    required String publicArea,
    required String address,
    required double latitude,
    required double longitude,
    @JsonKey(includeIfNull: false) int? depositAmountMinor,
  }) = _UpdateItemDraft;

  factory UpdateItemDraft.fromJson(Map<String, dynamic> json) =>
      _$UpdateItemDraftFromJson(json);
}

@freezed
abstract class UnavailablePeriod with _$UnavailablePeriod {
  const factory UnavailablePeriod({
    required String id,
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime createdAt,
  }) = _UnavailablePeriod;

  factory UnavailablePeriod.fromJson(Map<String, dynamic> json) =>
      _$UnavailablePeriodFromJson(json);
}

@freezed
abstract class CreateUnavailablePeriodDraft
    with _$CreateUnavailablePeriodDraft {
  const factory CreateUnavailablePeriodDraft({
    required String startDate,
    required String endDate,
  }) = _CreateUnavailablePeriodDraft;

  factory CreateUnavailablePeriodDraft.fromJson(Map<String, dynamic> json) =>
      _$CreateUnavailablePeriodDraftFromJson(json);
}
