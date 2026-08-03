import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/domain/auth_controller.dart';
import '../domain/session_controller.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final action = ref.watch(sessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Устройства и сессии')),
      body: SafeArea(
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _LoadError(
            onRetry: () => ref.invalidate(sessionsProvider),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final session in items)
                _SessionCard(
                  session: session,
                  disabled: action.isLoading,
                  onRevoke: () => ref
                      .read(sessionControllerProvider.notifier)
                      .revoke(session.sessionId),
                ),
              if (action.hasError) ...[
                const SizedBox(height: 8),
                Text(
                  action.error.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: action.isLoading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .logout(),
                child: const Text('Выйти на этом устройстве'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: action.isLoading
                    ? null
                    : () => ref
                          .read(sessionControllerProvider.notifier)
                          .logoutAll(),
                child: const Text('Выйти на всех устройствах'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.disabled,
    required this.onRevoke,
  });

  final UserSession session;
  final bool disabled;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          session.isCurrent ? Icons.smartphone : Icons.devices_other,
        ),
        title: Text(
          session.isCurrent ? 'Это устройство' : 'Другое устройство',
        ),
        subtitle: Text('Активность: ${_date(session.lastSeenAt)}'),
        trailing: session.isCurrent
            ? const Chip(label: Text('Текущая'))
            : IconButton(
                onPressed: disabled ? null : onRevoke,
                tooltip: 'Завершить сессию',
                icon: const Icon(Icons.logout),
              ),
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: onRetry,
        child: const Text('Повторить'),
      ),
    );
  }
}
