// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owned_item_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OwnedItem _$OwnedItemFromJson(Map<String, dynamic> json) => _OwnedItem(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  condition: json['condition'] as String,
  completeness: json['completeness'] as String,
  handoverTerms: json['handoverTerms'] as String,
  status: json['status'] as String,
  publicArea: json['publicArea'] as String,
  address: json['address'] as String,
  latitude: _doubleFromJson(json['latitude'] as Object),
  longitude: _doubleFromJson(json['longitude'] as Object),
  pricePerDay: _doubleFromJson(json['pricePerDay'] as Object),
  depositAmount: _nullableDoubleFromJson(json['depositAmount']),
  category: CatalogCategory.fromJson(json['category'] as Map<String, dynamic>),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  photos: (json['photos'] as List<dynamic>)
      .map((e) => CatalogPhoto.fromJson(e as Map<String, dynamic>))
      .toList(),
  rejectReason: json['rejectReason'] as String?,
);

Map<String, dynamic> _$OwnedItemToJson(_OwnedItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'condition': instance.condition,
      'completeness': instance.completeness,
      'handoverTerms': instance.handoverTerms,
      'status': instance.status,
      'publicArea': instance.publicArea,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'pricePerDay': instance.pricePerDay,
      'depositAmount': instance.depositAmount,
      'category': instance.category,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'photos': instance.photos,
      'rejectReason': instance.rejectReason,
    };

_UpdateItemDraft _$UpdateItemDraftFromJson(Map<String, dynamic> json) =>
    _UpdateItemDraft(
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      condition: json['condition'] as String,
      completeness: json['completeness'] as String,
      handoverTerms: json['handoverTerms'] as String,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      publicArea: json['publicArea'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$UpdateItemDraftToJson(_UpdateItemDraft instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'condition': instance.condition,
      'completeness': instance.completeness,
      'handoverTerms': instance.handoverTerms,
      'pricePerDay': instance.pricePerDay,
      'publicArea': instance.publicArea,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

_UnavailablePeriod _$UnavailablePeriodFromJson(Map<String, dynamic> json) =>
    _UnavailablePeriod(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UnavailablePeriodToJson(_UnavailablePeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

_CreateUnavailablePeriodDraft _$CreateUnavailablePeriodDraftFromJson(
  Map<String, dynamic> json,
) => _CreateUnavailablePeriodDraft(
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
);

Map<String, dynamic> _$CreateUnavailablePeriodDraftToJson(
  _CreateUnavailablePeriodDraft instance,
) => <String, dynamic>{
  'startDate': instance.startDate,
  'endDate': instance.endDate,
};
