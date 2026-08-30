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
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Semantics(
              image: true,
              label: 'Аватар пользователя',
              excludeSemantics: true,
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.cloud,
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
                  const SizedBox(height: 2),
                  Text(
                    city == null || city.isEmpty ? 'Город не указан' : city,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _StatusLine(
                    label: profile.isBlocked
                        ? 'Аккаунт заблокирован'
                        : 'Аккаунт активен',
                    color: profile.isBlocked
                        ? AppColors.error
                        : AppColors.success,
                  ),
                  const SizedBox(height: 2),
                  _StatusLine(label: _kycLabel(profile.kycStatus)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Column(
          key: const ValueKey('profile-navigation-group'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _NavigationGroup(
              label: 'Ваш аккаунт',
              children: [
                _NavigationRow(
                  icon: Icons.bookmark_outline,
                  label: 'Избранное',
                  route: '/profile/favorites',
                ),
                _NavigationRow(
                  icon: Icons.devices_outlined,
                  label: 'Устройства и сессии',
                  route: '/profile/sessions',
                ),
              ],
            ),
            SizedBox(height: 20),
            _NavigationGroup(
              label: 'Приватность и безопасность',
              children: [
                _NavigationRow(
                  icon: Icons.analytics_outlined,
                  label: 'Аналитика и согласие',
                  route: '/profile/analytics',
                ),
                _NavigationRow(
                  icon: Icons.policy_outlined,
                  label: 'Правила и документы',
                  route: '/profile/documents',
                ),
                _NavigationRow(
                  icon: Icons.download_outlined,
                  label: 'Экспортировать мои данные',
                  route: '/profile/data-export',
                ),
                _NavigationRow(
                  icon: Icons.person_off_outlined,
                  label: 'Заблокированные пользователи',
                  route: '/profile/blocked-users',
                ),
              ],
            ),
            SizedBox(height: 20),
            _NavigationGroup(
              label: 'Помощь',
              children: [
                _NavigationRow(
                  icon: Icons.support_agent_outlined,
                  label: 'Поддержка',
                  route: '/support',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/profile/close-account'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Закрыть аккаунт'),
          ),
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

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, this.color = AppColors.textMuted});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _NavigationGroup extends StatelessWidget {
  const _NavigationGroup({required this.label, required this.children});

  final String label;
  final List<_NavigationRow> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Material(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, indent: 56, endIndent: 12),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
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
