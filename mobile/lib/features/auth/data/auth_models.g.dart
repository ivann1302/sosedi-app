// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => _AuthUser(
  id: json['id'] as String,
  phone: json['phone'] as String,
  role: json['role'] as String,
  isBlocked: json['isBlocked'] as bool,
  name: json['name'] as String?,
  kycStatus: json['kycStatus'] as String?,
);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'role': instance.role,
  'isBlocked': instance.isBlocked,
  'name': instance.name,
  'kycStatus': instance.kycStatus,
};

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

_OtpRequestResult _$OtpRequestResultFromJson(Map<String, dynamic> json) =>
    _OtpRequestResult(
      phone: json['phone'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$OtpRequestResultToJson(_OtpRequestResult instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'expiresInSeconds': instance.expiresInSeconds,
    };
