import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String phone,
    required String role,
    required bool isBlocked,
    String? name,
    String? kycStatus,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}

@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

@freezed
abstract class OtpRequestResult with _$OtpRequestResult {
  const factory OtpRequestResult({
    required String phone,
    required int expiresInSeconds,
  }) = _OtpRequestResult;

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestResultFromJson(json);
}

@freezed
abstract class UserSession with _$UserSession {
  const factory UserSession({
    required String sessionId,
    required String installationId,
    required DateTime createdAt,
    required DateTime lastSeenAt,
    required bool isCurrent,
  }) = _UserSession;

  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);
}

@freezed
abstract class LogoutResult with _$LogoutResult {
  const factory LogoutResult({
    required bool loggedOut,
  }) = _LogoutResult;

  factory LogoutResult.fromJson(Map<String, dynamic> json) =>
      _$LogoutResultFromJson(json);
}
