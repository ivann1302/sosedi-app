import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
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
              ? const Center(child: Text('У вас пока нет объявлений'))
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
    return Card(
      child: ListTile(
        onTap: item.status == 'APPROVED'
            ? () => context.push('/items/${item.id}')
            : null,
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(item.title),
        subtitle: Text(
          '${_status(item.status)} · ${_price(item.pricePerDay)} ₽ / день'
          '${item.rejectReason == null ? '' : '\n${item.rejectReason}'}',
        ),
        isThreeLine: item.rejectReason != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.status != 'HIDDEN')
              IconButton(
                onPressed: hide.isLoading ? null : () => _hide(context, ref),
                tooltip: 'Скрыть объявление',
                icon: const Icon(Icons.visibility_off_outlined),
              ),
            IconButton(
              onPressed: () => context.push('/items/${item.id}/edit'),
              tooltip: 'Редактировать',
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
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
