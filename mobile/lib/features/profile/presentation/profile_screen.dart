import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/profile_models.dart';
import '../data/profile_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            tooltip: 'Редактировать',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _ProfileError(onRetry: () => ref.invalidate(profileProvider)),
          data: (value) => _ProfileContent(profile: value),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name?.trim();
    final city = profile.city?.trim();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.warmSand,
            borderRadius: BorderRadius.circular(AppRadii.large),
          ),
          child: Row(
            children: [
              Semantics(
                image: true,
                label: 'Аватар пользователя',
                excludeSemantics: true,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.brand500,
                  foregroundColor: AppColors.ink900,
                  backgroundImage: profile.avatarUrl == null
                      ? null
                      : NetworkImage(profile.avatarUrl!),
                  child: profile.avatarUrl == null
                      ? Text(
                          _initial(name),
                          style: Theme.of(context).textTheme.headlineMedium,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name == null || name.isEmpty ? 'Имя не указано' : name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      city == null || city.isEmpty ? 'Город не указан' : city,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _StatusRow(
          icon: Icons.verified_user_outlined,
          label: 'Аккаунт активен',
        ),
        const SizedBox(height: 12),
        _StatusRow(
          icon: Icons.badge_outlined,
          label: _kycLabel(profile.kycStatus),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/sessions'),
          icon: const Icon(Icons.devices_outlined),
          label: const Text('Устройства и сессии'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/analytics'),
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Аналитика и согласие'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/documents'),
          icon: const Icon(Icons.policy_outlined),
          label: const Text('Правила и документы'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/support'),
          icon: const Icon(Icons.support_agent_outlined),
          label: const Text('Поддержка'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/data-export'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Экспортировать мои данные'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/profile/blocked-users'),
          icon: const Icon(Icons.person_off_outlined),
          label: const Text('Заблокированные пользователи'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push('/profile/close-account'),
          child: const Text('Закрыть аккаунт'),
        ),
      ],
    );
  }

  String _initial(String? name) {
    if (name == null || name.isEmpty) {
      return 'С';
    }
    return name.characters.first.toUpperCase();
  }

  String _kycLabel(String? status) {
    return switch (status) {
      'VERIFIED' => 'Личность подтверждена',
      'PENDING' => 'Проверка личности идёт',
      'REJECTED' => 'Проверка личности не пройдена',
      _ => 'Личность не подтверждена',
    };
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.slate700),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось загрузить профиль'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
