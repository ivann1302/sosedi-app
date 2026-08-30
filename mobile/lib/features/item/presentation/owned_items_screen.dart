import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/owned_item_models.dart';
import '../data/owned_items_service.dart';
import '../domain/edit_item_controller.dart';

class OwnedItemsScreen extends ConsumerWidget {
  const OwnedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(ownedItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои объявления')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/items/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: SafeArea(
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Error(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить объявления',
            ),
            onRetry: () => ref.invalidate(ownedItemsProvider),
          ),
          data: (value) => value.isEmpty
              ? const _EmptyOwnedItems()
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(ownedItemsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _OwnedItemCard(item: value[index]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _OwnedItemCard extends ConsumerWidget {
  const _OwnedItemCard({required this.item});

  final OwnedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hide = ref.watch(hideOwnedItemProvider);
    return Column(
      children: [
        InkWell(
          onTap: item.status == 'APPROVED'
              ? () => context.push('/items/${item.id}')
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _OwnedItemPhoto(item: item),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_price(item.pricePerDay)} ₽ / день',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status(item.status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.status == 'REJECTED'
                              ? AppColors.error
                              : AppColors.slate700,
                        ),
                      ),
                      if (item.rejectReason != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.rejectReason!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<_OwnedItemAction>(
                  tooltip: 'Действия с объявлением',
                  onSelected: (action) {
                    switch (action) {
                      case _OwnedItemAction.edit:
                        context.push('/items/${item.id}/edit');
                      case _OwnedItemAction.hide:
                        if (!hide.isLoading) {
                          _hide(context, ref);
                        }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _OwnedItemAction.edit,
                      child: Text('Редактировать'),
                    ),
                    if (item.status != 'HIDDEN')
                      const PopupMenuItem(
                        value: _OwnedItemAction.hide,
                        child: Text('Скрыть объявление'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _hide(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Скрыть объявление?'),
        content: const Text(
          'Оно исчезнет из каталога. Вернуть его на модерацию можно через '
          'редактирование.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Скрыть'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final success = await ref
        .read(hideOwnedItemProvider.notifier)
        .hide(item.id);
    if (!context.mounted) {
      return;
    }
    final action = ref.read(hideOwnedItemProvider);
    final message = success
        ? 'Объявление скрыто'
        : userFacingError(
            action.error!,
            fallback: 'Не удалось скрыть объявление',
          );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _status(String status) {
    return switch (status) {
      'PENDING' => 'На модерации',
      'APPROVED' => 'Опубликовано',
      'REJECTED' => 'Нужны исправления',
      'HIDDEN' => 'Скрыто',
      _ => status,
    };
  }

  String _price(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

enum _OwnedItemAction { edit, hide }

class _OwnedItemPhoto extends StatelessWidget {
  const _OwnedItemPhoto({required this.item});

  final OwnedItem item;

  @override
  Widget build(BuildContext context) {
    final coverPhoto =
        item.photos.where((photo) => photo.isCover).firstOrNull ??
        item.photos.firstOrNull;
    final url = coverPhoto?.thumbnailUrl ?? coverPhoto?.previewUrl;

    if (url == null) {
      return const ColoredBox(
        color: AppColors.warmSand,
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: AppColors.slate800,
          ),
        ),
      );
    }

    return Image.network(
      url,
      semanticLabel: 'Фото ${item.title}',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.warmSand,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.slate800),
        ),
      ),
    );
  }
}

class _EmptyOwnedItems extends StatelessWidget {
  const _EmptyOwnedItems();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppColors.slate700,
            ),
            const SizedBox(height: 12),
            Text(
              'У вас пока нет объявлений',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Добавьте первую вещь — она появится в каталоге после проверки.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
