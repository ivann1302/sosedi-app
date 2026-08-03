import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/identifiers/uuid_v4.dart';
import '../../../core/router/app_router.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../data/inbox_service.dart';
import 'notification_open_source.dart';

final notificationNavigatorProvider = Provider<void Function(String)>((ref) {
  return ref.read(appRouterProvider).go;
});

final notificationNavigationProvider =
    NotifierProvider<NotificationNavigationController, String?>(
      NotificationNavigationController.new,
    );

class NotificationNavigationController extends Notifier<String?> {
  var _isResolving = false;

  @override
  String? build() {
    final source = ref.watch(notificationOpenSourceProvider);
    final subscription = source.openedEventIds.listen(handleEventId);
    ref.onDispose(subscription.cancel);
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      if (next is AuthAuthenticated) {
        unawaited(_openPending());
      }
    });
    unawaited(_loadInitialEvent(source));
    return null;
  }

  Future<void> _loadInitialEvent(NotificationOpenSource source) async {
    final eventId = await source.initialEventId();
    if (eventId != null) {
      await handleEventId(eventId);
    }
  }

  Future<void> handleEventId(String eventId) async {
    if (!isUuidV4(eventId)) {
      return;
    }

    state = eventId;
    await _openPending();
  }

  Future<void> _openPending() async {
    if (_isResolving ||
        state == null ||
        ref.read(authControllerProvider) is! AuthAuthenticated) {
      return;
    }

    _isResolving = true;
    final eventId = state!;
    try {
      final path = await ref
          .read(inboxServiceProvider)
          .resolveNavigationPath(eventId);
      if (state == eventId && path != null) {
        ref.read(notificationNavigatorProvider)(path);
      }
    } catch (_) {
      // Missing, stale and unauthorized events must not reveal a target.
    } finally {
      if (state == eventId) {
        state = null;
      }
      _isResolving = false;
      if (state != null) {
        unawaited(_openPending());
      }
    }
  }
}
