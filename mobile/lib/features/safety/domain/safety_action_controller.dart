import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/safety_service.dart';

final safetyActionProvider =
    AsyncNotifierProvider<SafetyActionController, String?>(
      SafetyActionController.new,
      retry: (_, _) => null,
    );

class SafetyActionController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<bool> report({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) {
    return _run(
      success: 'REPORT_CREATED',
      action: () => ref
          .read(safetyServiceProvider)
          .createReport(
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            description: description,
          ),
    );
  }

  Future<bool> block(String userId) {
    return _run(
      success: 'USER_BLOCKED',
      action: () => ref.read(safetyServiceProvider).blockUser(userId),
    );
  }

  Future<bool> unblock(String userId) {
    return _run(
      success: 'USER_UNBLOCKED',
      action: () => ref.read(safetyServiceProvider).unblockUser(userId),
      refreshBlockedUsers: true,
    );
  }

  Future<bool> _run({
    required String success,
    required Future<void> Function() action,
    bool refreshBlockedUsers = false,
  }) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
      if (refreshBlockedUsers) {
        ref.invalidate(blockedUsersProvider);
      }
      return success;
    });
    return !state.hasError;
  }
}
