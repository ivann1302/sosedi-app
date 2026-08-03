import 'package:freezed_annotation/freezed_annotation.dart';

part 'safety_models.freezed.dart';
part 'safety_models.g.dart';

@freezed
abstract class BlockedUserSummary with _$BlockedUserSummary {
  const factory BlockedUserSummary({
    required String id,
    required String? name,
  }) = _BlockedUserSummary;

  factory BlockedUserSummary.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserSummaryFromJson(json);
}

@freezed
abstract class BlockedUser with _$BlockedUser {
  const factory BlockedUser({
    required String id,
    required BlockedUserSummary blocked,
    required DateTime createdAt,
  }) = _BlockedUser;

  factory BlockedUser.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserFromJson(json);
}
