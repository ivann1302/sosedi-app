import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_events.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_service.dart';
import 'auth_state.dart';
import 'auth_validators.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  Future<void>? _sessionRestore;

  @override
  AuthState build() {
    ref.listen<int>(sessionInvalidationProvider, (previous, next) {
      if (previous != null && previous != next) {
        state = const AuthState.unauthenticated();
      }
    });

    unawaited(Future<void>.microtask(restoreSession));
    return const AuthState.loading();
  }

  Future<bool> requestOtp(String rawPhone) async {
    if (state.isSubmitting) {
      return false;
    }

    final phone = AuthValidators.normalizeRussianPhone(rawPhone);
    state = const AuthState.unauthenticated(isSubmitting: true);

    try {
      final result = await ref.read(authServiceProvider).requestOtp(phone);
      state = AuthState.codeSent(
        phone: result.phone,
        expiresInSeconds: result.expiresInSeconds,
      );
      unawaited(
        ref.read(analyticsServiceProvider).track(AnalyticsEvent.otpRequested),
      );
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(errorMessage: _message(error));
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final currentState = state;
    if (currentState is! AuthCodeSent || currentState.isSubmitting) {
      return false;
    }

    state = currentState.copyWith(errorMessage: null, isSubmitting: true);

    try {
      final tokens = await ref
          .read(authServiceProvider)
          .verifyOtp(phone: currentState.phone, code: code);
      state = AuthState.authenticated(user: tokens.user);
      unawaited(
        ref.read(analyticsServiceProvider).track(AnalyticsEvent.loginCompleted),
      );
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
    state = const AuthState.unauthenticated();
    await ref.read(authServiceProvider).logout();
  }

  Future<void> validateSessionOnResume() {
    final currentState = state;
    final shouldRestore =
        currentState is AuthAuthenticated ||
        currentState is AuthUnauthenticated &&
            currentState.errorMessage != null;
    if (!shouldRestore) {
      return Future<void>.value();
    }

    return restoreSession();
  }

  Future<void> restoreSession() {
    final activeRestore = _sessionRestore;
    if (activeRestore != null) {
      return activeRestore;
    }

    final restore = _restoreSession();
    _sessionRestore = restore;
    return restore.whenComplete(() {
      if (identical(_sessionRestore, restore)) {
        _sessionRestore = null;
      }
    });
  }

  Future<void> _restoreSession() async {
    state = const AuthState.loading();
    final storage = ref.read(tokenStorageProvider);

    try {
      final refreshToken = await storage.readRefreshToken();

      if (refreshToken == null) {
        if (await storage.readAccessToken() != null) {
          await ref.read(authServiceProvider).clearSession();
        }
        state = const AuthState.unauthenticated();
        return;
      }

      final user = await ref.read(authServiceProvider).me();
      state = AuthState.authenticated(user: user);
    } on ApiException catch (error) {
      if (_invalidatesSession(error)) {
        await ref.read(authServiceProvider).clearSession();
        state = const AuthState.unauthenticated();
        return;
      }

      state = AuthState.unauthenticated(errorMessage: error.message);
    } catch (error) {
      state = AuthState.unauthenticated(errorMessage: _message(error));
    }
  }

  bool _invalidatesSession(ApiException error) {
    return error.code == 'UNAUTHORIZED' || error.code == 'FORBIDDEN';
  }

  String _message(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Не удалось выполнить действие';
  }
}
