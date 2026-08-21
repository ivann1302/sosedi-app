import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/config/marketplace_documents_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../catalog/data/catalog_models.dart';
import '../../reviews/data/review_service.dart';
import '../../safety/domain/safety_action_controller.dart';
import '../../safety/presentation/report_dialog.dart';
import '../data/item_service.dart';

class ItemDetailsScreen extends ConsumerWidget {
  const ItemDetailsScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemDetailsProvider(itemId));

    return Scaffold(
      appBar: AppBar(title: const Text('Объявление')),
      body: SafeArea(
        child: item.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ItemError(
            notFound: error is ApiException && error.code == 'ITEM_NOT_FOUND',
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить объявление',
            ),
            onRetry: () => ref.invalidate(itemDetailsProvider(itemId)),
          ),
          data: (value) => _ItemContent(item: value),
        ),
      ),
      bottomNavigationBar: item.when(
        loading: () => null,
        error: (_, _) => null,
        data: (value) => _ItemPrimaryAction(item: value),
      ),
    );
  }
}

class _ItemContent extends ConsumerWidget {
  const _ItemContent({required this.item});

  final CatalogItem item;

  Future<void> _report(
    BuildContext context,
    WidgetRef ref, {
    required String targetType,
    required String targetId,
  }) async {
    final submission = await showSafetyReportDialog(
      context: context,
      targetType: targetType,
    );
    if (submission == null || !context.mounted) {
      return;
    }
    final success = await ref
        .read(safetyActionProvider.notifier)
        .report(
          targetType: targetType,
          targetId: targetId,
          reason: submission.reason,
          description: submission.description,
        );
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Жалоба отправлена')));
    }
  }

  Future<void> _blockOwner(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать пользователя?'),
        content: const Text(
          'Новые объявления и бронирования между вами будут недоступны. '
          'Существующие обязательства останутся видимы поддержке.',
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
    if (confirmed != true) {
      return;
    }
    final success = await ref
        .read(safetyActionProvider.notifier)
        .block(item.owner.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь заблокирован')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final documents = ref.watch(marketplaceDocumentsConfigProvider);
    final safety = ref.watch(safetyActionProvider);
    final reviews = ref.watch(publicReviewsProvider(item.owner.id));
    final currentUserId = auth is AuthAuthenticated ? auth.user.id : null;
    final isOwner = currentUserId == item.owner.id;
    final canReport = currentUserId != null && !isOwner;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _PhotoGallery(photos: item.photos),
        const SizedBox(height: 20),
        Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.warmSand,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '${_price(item.pricePerDay)} ₽ / день',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              children: [
                _DetailRow(label: 'Категория', value: item.category.name),
                _DetailRow(label: 'Район', value: item.area),
                _DetailRow(
                  label: 'Владелец',
                  value: item.owner.name?.trim().isNotEmpty == true
                      ? item.owner.name!
                      : 'Сосед',
                ),
                _DetailRow(
                  label: 'Состояние',
                  value: _condition(item.condition),
                ),
                _DetailRow(label: 'Комплектация', value: item.completeness),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Рейтинг владельца',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                reviews.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Рейтинг временно недоступен'),
                  data: (page) => page.summary.count == 0
                      ? const Text('Новый владелец')
                      : Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${page.summary.average!.toStringAsFixed(1)} · '
                              '${page.summary.count} подтверждённых отзывов',
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/items/${item.id}/owner'),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Профиль и отзывы владельца'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Описание', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(item.description),
        const SizedBox(height: 24),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warmSand,
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.handshake_outlined, color: AppColors.slate800),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Передача и использование',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(item.handoverTerms),
                      const SizedBox(height: 8),
                      Text(
                        item.category.safetyNotice,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.event_available_outlined),
            title: Text('Доступность проверяется по датам'),
            subtitle: Text(
              'Выберите период — приложение сверит календарь владельца '
              'перед отправкой заявки.',
            ),
          ),
        ),
        if (documents.isPublishedSetReady) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile/documents'),
            icon: const Icon(Icons.policy_outlined),
            label: Text(
              'Правила аренды · версия '
              '${documents.cancellationPolicyVersion}',
            ),
          ),
        ],
        if (canReport) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: safety.isLoading
                ? null
                : () => _report(
                    context,
                    ref,
                    targetType: 'ITEM',
                    targetId: item.id,
                  ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Пожаловаться на объявление'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: safety.isLoading
                ? null
                : () => _report(
                    context,
                    ref,
                    targetType: 'USER',
                    targetId: item.owner.id,
                  ),
            icon: const Icon(Icons.report_outlined),
            label: const Text('Пожаловаться на владельца'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: safety.isLoading
                ? null
                : () => _blockOwner(context, ref),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Заблокировать владельца'),
          ),
          if (safety.hasError)
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

  String _price(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  String _condition(String value) {
    return switch (value) {
      'NEW' => 'Новое',
      'LIKE_NEW' => 'Как новое',
      'GOOD' => 'Хорошее',
      'FAIR' => 'Удовлетворительное',
      _ => 'Не указано',
    };
  }
}

class _ItemPrimaryAction extends ConsumerWidget {
  const _ItemPrimaryAction({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final currentUserId = auth is AuthAuthenticated ? auth.user.id : null;
    final isOwner = currentUserId == item.owner.id;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: FilledButton(
          onPressed: () {
            if (isOwner) {
              context.push('/items/${item.id}/edit');
              return;
            }
            unawaited(
              ref
                  .read(analyticsServiceProvider)
                  .track(AnalyticsEvent.bookingStarted),
            );
            context.push('/items/${item.id}/booking');
          },
          child: Text(isOwner ? 'Управлять объявлением' : 'Выбрать даты'),
        ),
      ),
    );
  }
}

class _PhotoGallery extends StatefulWidget {
  const _PhotoGallery({required this.photos});

  final List<CatalogPhoto> photos;

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.photos
        .map((photo) => photo.previewUrl ?? photo.thumbnailUrl)
        .whereType<String>()
        .toList(growable: false);

    if (urls.isEmpty) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warmSand,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Center(child: Icon(Icons.inventory_2_outlined, size: 56)),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              itemCount: urls.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) => Image.network(
                urls[index],
                semanticLabel: 'Фото объявления ${index + 1} из ${urls.length}',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.warmSand,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 8),
          Text('${_page + 1} / ${urls.length}'),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _ItemError extends StatelessWidget {
  const _ItemError({
    required this.notFound,
    required this.message,
    required this.onRetry,
  });

  final bool notFound;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notFound ? 'Объявление больше недоступно' : message),
            if (!notFound) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ],
        ),
      ),
    );
  }
}
