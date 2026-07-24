import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/auth_models.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState.loading() = AuthLoading;

  const factory AuthState.unauthenticated({
    String? errorMessage,
    @Default(false) bool isSubmitting,
  }) = AuthUnauthenticated;

  const factory AuthState.codeSent({
    required String phone,
    required int expiresInSeconds,
    String? errorMessage,
    @Default(false) bool isSubmitting,
  }) = AuthCodeSent;

  const factory AuthState.authenticated({
    required AuthUser user,
  }) = AuthAuthenticated;

  bool get isSubmitting => switch (this) {
        AuthUnauthenticated(:final isSubmitting) => isSubmitting,
        AuthCodeSent(:final isSubmitting) => isSubmitting,
        _ => false,
      };

  String? get errorMessage => switch (this) {
        AuthUnauthenticated(:final errorMessage) => errorMessage,
        AuthCodeSent(:final errorMessage) => errorMessage,
        _ => null,
      };
}
