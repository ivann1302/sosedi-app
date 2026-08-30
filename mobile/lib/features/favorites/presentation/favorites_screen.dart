import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../catalog/data/catalog_models.dart';
import '../domain/favorite_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: SafeArea(
        child: favorites.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _FavoriteError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить избранное',
            ),
            onRetry: () => ref.invalidate(favoriteItemsProvider),
          ),
          data: (items) => items.isEmpty
              ? const Center(child: Text('В избранном пока ничего нет'))
              : RefreshIndicator(
                  onRefresh: () async {
                    final _ = await ref.refresh(favoriteItemsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _FavoriteCard(
                      item: items[index],
                      onRemove: () async {
                        try {
                          await ref
                              .read(favoriteItemsProvider.notifier)
                              .toggle(items[index]);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  userFacingError(
                                    error,
                                    fallback: 'Не удалось обновить избранное',
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item, required this.onRemove});

  final CatalogItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cover =
        item.photos.where((photo) => photo.isCover).firstOrNull ??
        item.photos.firstOrNull;
    final coverUrl = cover?.thumbnailUrl ?? cover?.previewUrl;
    return Card(
      child: ListTile(
        onTap: () => context.push('/items/${item.id}'),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.small),
          child: SizedBox.square(
            dimension: 52,
            child: coverUrl == null
                ? const ColoredBox(
                    color: AppColors.warmSand,
                    child: Icon(Icons.inventory_2_outlined),
                  )
                : Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.warmSand,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${_price(item.pricePerDay)} ₽ / день · ${item.area}'),
        trailing: IconButton(
          tooltip: 'Убрать из избранного',
          onPressed: onRemove,
          icon: const Icon(Icons.bookmark),
        ),
      ),
    );
  }

  String _price(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

class _FavoriteError extends StatelessWidget {
  const _FavoriteError({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
