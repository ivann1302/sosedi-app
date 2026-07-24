import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_service.dart';
import 'auth_state.dart';
import 'auth_validators.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(_restoreSession());
    return const AuthState.loading();
  }

  Future<bool> requestOtp(String rawPhone) async {
    final phone = AuthValidators.normalizeRussianPhone(rawPhone);
    state = const AuthState.unauthenticated(isSubmitting: true);

    try {
      final result = await ref.read(authServiceProvider).requestOtp(phone);
      state = AuthState.codeSent(
        phone: result.phone,
        expiresInSeconds: result.expiresInSeconds,
      );
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(errorMessage: _message(error));
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final currentState = state;
    if (currentState is! AuthCodeSent) {
      return false;
    }

    state = currentState.copyWith(
      errorMessage: null,
      isSubmitting: true,
    );

    try {
      final tokens = await ref.read(authServiceProvider).verifyOtp(
            phone: currentState.phone,
            code: code,
          );
      state = AuthState.authenticated(user: tokens.user);
      return true;
    } catch (error) {
      state = currentState.copyWith(
        errorMessage: _message(error),
        isSubmitting: false,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AuthState.unauthenticated();
  }

  Future<void> _restoreSession() async {
    final refreshToken =
        await ref.read(tokenStorageProvider).readRefreshToken();

    if (refreshToken == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await ref.read(authServiceProvider).me();
      state = AuthState.authenticated(user: user);
    } catch (_) {
      await ref.read(authServiceProvider).clearSession();
      state = const AuthState.unauthenticated();
    }
  }

  String _message(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Не удалось выполнить действие';
  }
}
