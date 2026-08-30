import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/safety_models.dart';
import '../data/safety_service.dart';
import '../domain/safety_action_controller.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(blockedUsersProvider);
    final action = ref.watch(safetyActionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Заблокированные')),
      body: SafeArea(
        child: users.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _BlockedUsersError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить список',
            ),
            onRetry: () => ref.invalidate(blockedUsersProvider),
          ),
          data: (values) => values.isEmpty
              ? const Center(child: Text('Заблокированных пользователей нет'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: values.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) => _BlockedUserTile(
                    user: values[index],
                    enabled: !action.isLoading,
                    onUnblock: () => _unblock(context, ref, values[index]),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    BlockedUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Разблокировать пользователя?'),
        content: const Text(
          'Пользователь снова сможет взаимодействовать с вашими новыми '
          'объявлениями и бронированиями.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Разблокировать'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(safetyActionProvider.notifier).unblock(user.blocked.id);
    }
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.user,
    required this.enabled,
    required this.onUnblock,
  });

  final BlockedUser user;
  final bool enabled;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final action = TextButton(
      onPressed: enabled ? onUnblock : null,
      child: const Text('Разблокировать'),
    );
    final useStackedLayout =
        MediaQuery.sizeOf(context).width <= 360 ||
        MediaQuery.textScalerOf(context).scale(16) > 16;

    return ListTile(
      minTileHeight: 64,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_off_outlined),
      title: useStackedLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(user.blocked.name ?? 'Пользователь'), action],
            )
          : Text(user.blocked.name ?? 'Пользователь'),
      trailing: useStackedLayout ? null : action,
    );
  }
}

class _BlockedUsersError extends StatelessWidget {
  const _BlockedUsersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
