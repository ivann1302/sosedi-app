// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_item_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocalCreateItemDraft _$LocalCreateItemDraftFromJson(
  Map<String, dynamic> json,
) => _LocalCreateItemDraft(
  step: (json['step'] as num?)?.toInt() ?? 0,
  categoryId: json['categoryId'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  condition: json['condition'] as String?,
  completeness: json['completeness'] as String?,
  handoverTerms: json['handoverTerms'] as String?,
  pricePerDay: json['pricePerDay'] as String?,
  publicArea: json['publicArea'] as String?,
);

Map<String, dynamic> _$LocalCreateItemDraftToJson(
  _LocalCreateItemDraft instance,
) => <String, dynamic>{
  'step': instance.step,
  'categoryId': instance.categoryId,
  'title': instance.title,
  'description': instance.description,
  'condition': instance.condition,
  'completeness': instance.completeness,
  'handoverTerms': instance.handoverTerms,
  'pricePerDay': instance.pricePerDay,
  'publicArea': instance.publicArea,
};

_CreateItemDraft _$CreateItemDraftFromJson(Map<String, dynamic> json) =>
    _CreateItemDraft(
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      condition: json['condition'] as String,
      completeness: json['completeness'] as String,
      handoverTerms: json['handoverTerms'] as String,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      publicArea: json['publicArea'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      ownershipConfirmed: json['ownershipConfirmed'] as bool,
      conditionConfirmed: json['conditionConfirmed'] as bool,
      completenessConfirmed: json['completenessConfirmed'] as bool,
      safetyAndMarketplaceRulesAccepted:
          json['safetyAndMarketplaceRulesAccepted'] as bool,
      listingRulesVersion: json['listingRulesVersion'] as String,
    );

Map<String, dynamic> _$CreateItemDraftToJson(_CreateItemDraft instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'title': instance.title,
      'description': instance.description,
      'condition': instance.condition,
      'completeness': instance.completeness,
      'handoverTerms': instance.handoverTerms,
      'pricePerDay': instance.pricePerDay,
      'publicArea': instance.publicArea,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'ownershipConfirmed': instance.ownershipConfirmed,
      'conditionConfirmed': instance.conditionConfirmed,
      'completenessConfirmed': instance.completenessConfirmed,
      'safetyAndMarketplaceRulesAccepted':
          instance.safetyAndMarketplaceRulesAccepted,
      'listingRulesVersion': instance.listingRulesVersion,
    };

_CreateItemResult _$CreateItemResultFromJson(Map<String, dynamic> json) =>
    _CreateItemResult(
      id: json['id'] as String,
      status: json['status'] as String,
      isUploadingPhotos: json['isUploadingPhotos'] as bool? ?? false,
      photoUploadFailed: json['photoUploadFailed'] as bool? ?? false,
    );

Map<String, dynamic> _$CreateItemResultToJson(_CreateItemResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'isUploadingPhotos': instance.isUploadingPhotos,
      'photoUploadFailed': instance.photoUploadFailed,
    };
