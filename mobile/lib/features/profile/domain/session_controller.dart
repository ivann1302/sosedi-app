import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/auth_controller.dart';

final sessionsProvider = FutureProvider.autoDispose<List<UserSession>>(
  (ref) => ref.watch(authServiceProvider).sessions(),
  retry: (_, _) => null,
);

final sessionControllerProvider =
    NotifierProvider<SessionController, AsyncValue<void>>(
      SessionController.new,
    );

class SessionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> revoke(String sessionId) async {
    await _run(() => ref.read(authServiceProvider).revokeSession(sessionId));
    if (!state.hasError) {
      ref.invalidate(sessionsProvider);
    }
  }

  Future<void> logoutAll() async {
    await _run(() => ref.read(authServiceProvider).revokeAllSessions());
    if (!state.hasError) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      final message = error is ApiException
          ? error.message
          : 'Не удалось завершить сессию';
      state = AsyncError(message, stackTrace);
    }
  }
}
