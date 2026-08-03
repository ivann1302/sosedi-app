// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogCategory _$CatalogCategoryFromJson(Map<String, dynamic> json) =>
    _CatalogCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      safetyNotice: json['safetyNotice'] as String,
      iconName: json['iconName'] as String?,
    );

Map<String, dynamic> _$CatalogCategoryToJson(_CatalogCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'safetyNotice': instance.safetyNotice,
      'iconName': instance.iconName,
    };

_CatalogOwner _$CatalogOwnerFromJson(Map<String, dynamic> json) =>
    _CatalogOwner(
      id: json['id'] as String,
      name: json['name'] as String?,
      city: json['city'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$CatalogOwnerToJson(_CatalogOwner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'avatarUrl': instance.avatarUrl,
    };

_CatalogPhoto _$CatalogPhotoFromJson(Map<String, dynamic> json) =>
    _CatalogPhoto(
      id: json['id'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      isCover: json['isCover'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      previewUrl: json['previewUrl'] as String?,
    );

Map<String, dynamic> _$CatalogPhotoToJson(_CatalogPhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sortOrder': instance.sortOrder,
      'isCover': instance.isCover,
      'createdAt': instance.createdAt.toIso8601String(),
      'thumbnailUrl': instance.thumbnailUrl,
      'previewUrl': instance.previewUrl,
    };

_ApproximateLocation _$ApproximateLocationFromJson(Map<String, dynamic> json) =>
    _ApproximateLocation(
      latitude: _doubleFromJson(json['latitude'] as Object),
      longitude: _doubleFromJson(json['longitude'] as Object),
      precision: json['precision'] as String,
    );

Map<String, dynamic> _$ApproximateLocationToJson(
  _ApproximateLocation instance,
) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'precision': instance.precision,
};

_CatalogItem _$CatalogItemFromJson(Map<String, dynamic> json) => _CatalogItem(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  condition: json['condition'] as String,
  completeness: json['completeness'] as String,
  handoverTerms: json['handoverTerms'] as String,
  pricePerDay: _doubleFromJson(json['pricePerDay'] as Object),
  depositAmount: _nullableDoubleFromJson(json['depositAmount']),
  category: CatalogCategory.fromJson(json['category'] as Map<String, dynamic>),
  owner: CatalogOwner.fromJson(json['owner'] as Map<String, dynamic>),
  area: json['area'] as String,
  approximateLocation: ApproximateLocation.fromJson(
    json['approximateLocation'] as Map<String, dynamic>,
  ),
  photos: (json['photos'] as List<dynamic>)
      .map((e) => CatalogPhoto.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  distanceBucket: json['distanceBucket'] as String?,
);

Map<String, dynamic> _$CatalogItemToJson(_CatalogItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'condition': instance.condition,
      'completeness': instance.completeness,
      'handoverTerms': instance.handoverTerms,
      'pricePerDay': instance.pricePerDay,
      'depositAmount': instance.depositAmount,
      'category': instance.category,
      'owner': instance.owner,
      'area': instance.area,
      'approximateLocation': instance.approximateLocation,
      'photos': instance.photos,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'distanceBucket': instance.distanceBucket,
    };
