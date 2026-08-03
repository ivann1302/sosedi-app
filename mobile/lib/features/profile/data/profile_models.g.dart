// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  phone: json['phone'] as String,
  role: json['role'] as String,
  isBlocked: json['isBlocked'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  name: json['name'] as String?,
  city: json['city'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  kycStatus: json['kycStatus'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'role': instance.role,
      'isBlocked': instance.isBlocked,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'name': instance.name,
      'city': instance.city,
      'avatarUrl': instance.avatarUrl,
      'kycStatus': instance.kycStatus,
    };

_PresignedAvatarUpload _$PresignedAvatarUploadFromJson(
  Map<String, dynamic> json,
) => _PresignedAvatarUpload(
  intentId: json['intentId'] as String,
  uploadUrl: json['uploadUrl'] as String,
  fields: Map<String, String>.from(json['fields'] as Map),
);

Map<String, dynamic> _$PresignedAvatarUploadToJson(
  _PresignedAvatarUpload instance,
) => <String, dynamic>{
  'intentId': instance.intentId,
  'uploadUrl': instance.uploadUrl,
  'fields': instance.fields,
};

_AvatarUploadResult _$AvatarUploadResultFromJson(Map<String, dynamic> json) =>
    _AvatarUploadResult(avatarUrl: json['avatarUrl'] as String);

Map<String, dynamic> _$AvatarUploadResultToJson(_AvatarUploadResult instance) =>
    <String, dynamic>{'avatarUrl': instance.avatarUrl};

_AccountClosureResult _$AccountClosureResultFromJson(
  Map<String, dynamic> json,
) => _AccountClosureResult(
  status: json['status'] as String,
  requestedAt: DateTime.parse(json['requestedAt'] as String),
  anonymizedAt: json['anonymizedAt'] == null
      ? null
      : DateTime.parse(json['anonymizedAt'] as String),
);

Map<String, dynamic> _$AccountClosureResultToJson(
  _AccountClosureResult instance,
) => <String, dynamic>{
  'status': instance.status,
  'requestedAt': instance.requestedAt.toIso8601String(),
  'anonymizedAt': instance.anonymizedAt?.toIso8601String(),
};

_UserStepUpResult _$UserStepUpResultFromJson(Map<String, dynamic> json) =>
    _UserStepUpResult(
      stepUpToken: json['stepUpToken'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$UserStepUpResultToJson(_UserStepUpResult instance) =>
    <String, dynamic>{
      'stepUpToken': instance.stepUpToken,
      'expiresInSeconds': instance.expiresInSeconds,
    };

_UserDataExport _$UserDataExportFromJson(Map<String, dynamic> json) =>
    _UserDataExport(
      schemaVersion: json['schemaVersion'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      retentionPolicyVersion: json['retentionPolicyVersion'] as String,
      profile: json['profile'] as Map<String, dynamic>,
      listings: (json['listings'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      bookings: (json['bookings'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      inbox: (json['inbox'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      support: (json['support'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      reports: (json['reports'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      blocks: (json['blocks'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      documentAcceptances: (json['documentAcceptances'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      financialHistory: (json['financialHistory'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      fileManifest: (json['fileManifest'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      processing: json['processing'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$UserDataExportToJson(_UserDataExport instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'retentionPolicyVersion': instance.retentionPolicyVersion,
      'profile': instance.profile,
      'listings': instance.listings,
      'bookings': instance.bookings,
      'inbox': instance.inbox,
      'support': instance.support,
      'reports': instance.reports,
      'blocks': instance.blocks,
      'documentAcceptances': instance.documentAcceptances,
      'financialHistory': instance.financialHistory,
      'fileManifest': instance.fileManifest,
      'processing': instance.processing,
    };
