// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BlockedUserSummary _$BlockedUserSummaryFromJson(Map<String, dynamic> json) =>
    _BlockedUserSummary(
      id: json['id'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$BlockedUserSummaryToJson(_BlockedUserSummary instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_BlockedUser _$BlockedUserFromJson(Map<String, dynamic> json) => _BlockedUser(
  id: json['id'] as String,
  blocked: BlockedUserSummary.fromJson(json['blocked'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$BlockedUserToJson(_BlockedUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'blocked': instance.blocked,
      'createdAt': instance.createdAt.toIso8601String(),
    };
