import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../catalog/data/catalog_models.dart';
import '../../item/data/item_service.dart';
import '../../safety/domain/safety_action_controller.dart';
import '../../safety/presentation/report_dialog.dart';
import '../data/review_models.dart';
import '../data/review_service.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemDetailsProvider(itemId));
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль владельца')),
      body: SafeArea(
        child: item.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ProfileError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить профиль',
            ),
            onRetry: () => ref.invalidate(itemDetailsProvider(itemId)),
          ),
          data: (value) => _OwnerReviews(owner: value.owner),
        ),
      ),
    );
  }
}

class _OwnerReviews extends ConsumerWidget {
  const _OwnerReviews({required this.owner});

  final CatalogOwner owner;

  Future<void> _blockOwner(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать владельца?'),
        content: const Text(
          'Его объявления и новые бронирования станут недоступны. '
          'Существующие обязательства сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final success = await ref
        .read(safetyActionProvider.notifier)
        .block(owner.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Владелец заблокирован')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(publicReviewsProvider(owner.id));
    final auth = ref.watch(authControllerProvider);
    final safety = ref.watch(safetyActionProvider);
    final canBlock = auth is AuthAuthenticated && auth.user.id != owner.id;
    final name = owner.name?.trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UserAvatar(radius: 36, avatarUrl: owner.avatarUrl, name: owner.name),
        const SizedBox(height: 12),
        Text(
          name?.isNotEmpty == true ? name! : 'Сосед',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (owner.city?.trim().isNotEmpty == true)
          Text(owner.city!, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Text(
          'Подтверждённые отзывы',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ProfileError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить отзывы',
            ),
            onRetry: () => ref.invalidate(publicReviewsProvider(owner.id)),
          ),
          data: (page) => _ReviewList(page: page),
        ),
        if (canBlock) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: safety.isLoading
                ? null
                : () => _blockOwner(context, ref),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Заблокировать владельца'),
          ),
        ],
        if (safety.hasError) ...[
          const SizedBox(height: 8),
          Text(
            userFacingError(
              safety.error!,
              fallback: 'Не удалось выполнить действие',
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewList extends ConsumerWidget {
  const _ReviewList({required this.page});

  final PublicReviewPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.summary.count == 0) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.auto_awesome_outlined),
        title: Text('Новый владелец'),
        subtitle: Text('Подтверждённых отзывов пока нет.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.star_rounded, size: 20),
            Text(
              '${page.summary.average!.toStringAsFixed(1)} · '
              '${page.summary.count} ${_reviewCountLabel(page.summary.count)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final review in page.items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 2,
                    children: [
                      for (var index = 0; index < review.rating; index++)
                        const Icon(Icons.star_rounded, size: 18),
                    ],
                  ),
                  const Text('Подтверждённая аренда'),
                ],
              ),
              if (review.text != null) ...[
                const SizedBox(height: 8),
                Text(review.text!),
              ],
              if (ref.watch(authControllerProvider) is AuthAuthenticated)
                TextButton.icon(
                  onPressed: ref.watch(safetyActionProvider).isLoading
                      ? null
                      : () => _report(context, ref, review.id),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Пожаловаться на отзыв'),
                ),
              const SizedBox(height: 4),
            ],
          ),
      ],
    );
  }

  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    String reviewId,
  ) async {
    final submission = await showSafetyReportDialog(
      context: context,
      targetType: 'REVIEW',
    );
    if (submission == null || !context.mounted) {
      return;
    }
    final success = await ref
        .read(safetyActionProvider.notifier)
        .report(
          targetType: 'REVIEW',
          targetId: reviewId,
          reason: submission.reason,
          description: submission.description,
        );
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Жалоба отправлена')));
    }
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

String _reviewCountLabel(int count) {
  final tens = count % 100;
  final units = count % 10;
  if (tens >= 11 && tens <= 14) {
    return 'отзывов';
  }
  return switch (units) {
    1 => 'отзыв',
    2 || 3 || 4 => 'отзыва',
    _ => 'отзывов',
  };
}
