import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String phone,
    required String role,
    required bool isBlocked,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? name,
    String? city,
    String? avatarUrl,
    String? kycStatus,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
abstract class PresignedAvatarUpload with _$PresignedAvatarUpload {
  const factory PresignedAvatarUpload({
    required String intentId,
    required String uploadUrl,
    required Map<String, String> fields,
  }) = _PresignedAvatarUpload;

  factory PresignedAvatarUpload.fromJson(Map<String, dynamic> json) =>
      _$PresignedAvatarUploadFromJson(json);
}

@freezed
abstract class AvatarUploadResult with _$AvatarUploadResult {
  const factory AvatarUploadResult({required String avatarUrl}) =
      _AvatarUploadResult;

  factory AvatarUploadResult.fromJson(Map<String, dynamic> json) =>
      _$AvatarUploadResultFromJson(json);
}

@freezed
abstract class AccountClosureResult with _$AccountClosureResult {
  const factory AccountClosureResult({
    required String status,
    required DateTime requestedAt,
    DateTime? anonymizedAt,
  }) = _AccountClosureResult;

  factory AccountClosureResult.fromJson(Map<String, dynamic> json) =>
      _$AccountClosureResultFromJson(json);
}

@freezed
abstract class UserStepUpResult with _$UserStepUpResult {
  const factory UserStepUpResult({
    required String stepUpToken,
    required int expiresInSeconds,
  }) = _UserStepUpResult;

  factory UserStepUpResult.fromJson(Map<String, dynamic> json) =>
      _$UserStepUpResultFromJson(json);
}

@freezed
abstract class UserDataExport with _$UserDataExport {
  const factory UserDataExport({
    required String schemaVersion,
    required DateTime generatedAt,
    required String retentionPolicyVersion,
    required Map<String, Object?> profile,
    required List<Map<String, Object?>> listings,
    required List<Map<String, Object?>> bookings,
    required List<Map<String, Object?>> inbox,
    required List<Map<String, Object?>> support,
    required List<Map<String, Object?>> reports,
    required List<Map<String, Object?>> blocks,
    required List<Map<String, Object?>> documentAcceptances,
    required List<Map<String, Object?>> financialHistory,
    required List<Map<String, Object?>> fileManifest,
    required Map<String, Object?> processing,
  }) = _UserDataExport;

  factory UserDataExport.fromJson(Map<String, dynamic> json) =>
      _$UserDataExportFromJson(json);
}
