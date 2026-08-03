import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_models.freezed.dart';
part 'catalog_models.g.dart';

double _doubleFromJson(Object value) => (value as num).toDouble();

@freezed
abstract class CatalogCategory with _$CatalogCategory {
  const factory CatalogCategory({
    required String id,
    required String name,
    required String slug,
    required String safetyNotice,
    String? iconName,
  }) = _CatalogCategory;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      _$CatalogCategoryFromJson(json);
}

@freezed
abstract class CatalogOwner with _$CatalogOwner {
  const factory CatalogOwner({
    required String id,
    String? name,
    String? city,
    String? avatarUrl,
  }) = _CatalogOwner;

  factory CatalogOwner.fromJson(Map<String, dynamic> json) =>
      _$CatalogOwnerFromJson(json);
}

@freezed
abstract class CatalogPhoto with _$CatalogPhoto {
  const factory CatalogPhoto({
    required String id,
    required int sortOrder,
    required bool isCover,
    required DateTime createdAt,
    String? thumbnailUrl,
    String? previewUrl,
  }) = _CatalogPhoto;

  factory CatalogPhoto.fromJson(Map<String, dynamic> json) =>
      _$CatalogPhotoFromJson(json);
}

@freezed
abstract class ApproximateLocation with _$ApproximateLocation {
  const factory ApproximateLocation({
    @JsonKey(fromJson: _doubleFromJson) required double latitude,
    @JsonKey(fromJson: _doubleFromJson) required double longitude,
    required String precision,
  }) = _ApproximateLocation;

  factory ApproximateLocation.fromJson(Map<String, dynamic> json) =>
      _$ApproximateLocationFromJson(json);
}

@freezed
abstract class CatalogItem with _$CatalogItem {
  const factory CatalogItem({
    required String id,
    required String title,
    required String description,
    required String condition,
    required String completeness,
    required String handoverTerms,
    @JsonKey(fromJson: _doubleFromJson) required double pricePerDay,
    @JsonKey(fromJson: _nullableDoubleFromJson) double? depositAmount,
    required CatalogCategory category,
    required CatalogOwner owner,
    required String area,
    required ApproximateLocation approximateLocation,
    required List<CatalogPhoto> photos,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? distanceBucket,
  }) = _CatalogItem;

  factory CatalogItem.fromJson(Map<String, dynamic> json) =>
      _$CatalogItemFromJson(json);
}

double? _nullableDoubleFromJson(Object? value) =>
    value == null ? null : (value as num).toDouble();

@freezed
abstract class CatalogState with _$CatalogState {
  const factory CatalogState({
    required List<CatalogItem> items,
    required bool hasMore,
    required int nextOffset,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isRefreshing,
    String? refreshError,
  }) = _CatalogState;
}
