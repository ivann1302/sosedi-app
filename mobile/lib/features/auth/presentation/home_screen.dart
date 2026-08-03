import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sosedi_logo.dart';
import '../domain/auth_controller.dart';
import '../domain/auth_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const SosediLogo(markSize: 28),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            tooltip: 'Профиль',
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            children: [
              Text(
                'Здравствуйте, ${authState.user.name ?? 'сосед'}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Что хотите сделать сегодня?',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              _ScenarioCard(
                icon: Icons.search,
                title: 'Беру в аренду',
                subtitle: 'Найдите нужную вещь рядом с домом',
                isPrimary: true,
                onTap: () {
                  unawaited(
                    ref
                        .read(analyticsServiceProvider)
                        .track(AnalyticsEvent.catalogOpened),
                  );
                  context.go('/catalog');
                },
              ),
              const SizedBox(height: 12),
              _ScenarioCard(
                icon: Icons.inventory_2_outlined,
                title: 'Сдаю',
                subtitle: 'Опубликуйте вещь или проверьте объявления',
                onTap: () {
                  unawaited(
                    ref
                        .read(analyticsServiceProvider)
                        .track(AnalyticsEvent.listingStarted),
                  );
                  context.go('/items/mine');
                },
              ),
              const SizedBox(height: 12),
              _ScenarioCard(
                icon: Icons.event_note_outlined,
                title: 'Мои бронирования',
                subtitle: 'Статусы, даты и действия по аренде',
                onTap: () => context.go('/bookings'),
              ),
              const SizedBox(height: 12),
              _ScenarioCard(
                icon: Icons.notifications_none,
                title: 'Уведомления',
                subtitle: 'Ответы, статусы и важные события',
                onTap: () => context.go('/inbox'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.person_outline),
                label: const Text('Открыть профиль'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isPrimary = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isPrimary ? AppColors.warmSand : AppColors.surface,
      child: Semantics(
        button: onTap != null,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.brand500 : AppColors.cloud,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 26, color: AppColors.ink900),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ),
          trailing: onTap == null
              ? const Chip(label: Text('Скоро'))
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
