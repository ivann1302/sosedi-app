import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_item_models.freezed.dart';
part 'create_item_models.g.dart';

@freezed
abstract class LocalCreateItemDraft with _$LocalCreateItemDraft {
  const factory LocalCreateItemDraft({
    @Default(0) int step,
    String? categoryId,
    String? title,
    String? description,
    String? condition,
    String? completeness,
    String? handoverTerms,
    String? pricePerDay,
    String? publicArea,
    String? depositMode,
    String? depositAmount,
  }) = _LocalCreateItemDraft;

  factory LocalCreateItemDraft.fromJson(Map<String, dynamic> json) =>
      _$LocalCreateItemDraftFromJson(json);
}

@freezed
abstract class CreateItemDraft with _$CreateItemDraft {
  const factory CreateItemDraft({
    required String categoryId,
    required String title,
    required String description,
    required String condition,
    required String completeness,
    required String handoverTerms,
    required double pricePerDay,
    required String publicArea,
    required String address,
    required double latitude,
    required double longitude,
    required bool ownershipConfirmed,
    required bool conditionConfirmed,
    required bool completenessConfirmed,
    required bool safetyAndMarketplaceRulesAccepted,
    required String listingRulesVersion,
    @JsonKey(includeIfNull: false) int? depositAmountMinor,
  }) = _CreateItemDraft;

  factory CreateItemDraft.fromJson(Map<String, dynamic> json) =>
      _$CreateItemDraftFromJson(json);
}

@freezed
abstract class CreateItemResult with _$CreateItemResult {
  const factory CreateItemResult({
    required String id,
    required String status,
    @Default(false) bool isUploadingPhotos,
    @Default(false) bool photoUploadFailed,
  }) = _CreateItemResult;

  factory CreateItemResult.fromJson(Map<String, dynamic> json) =>
      _$CreateItemResultFromJson(json);
}
