import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/item_photo_image.dart';
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
                  child: _FavoritesGrid(
                    items: items,
                    onRemove: (item) async {
                      try {
                        await ref
                            .read(favoriteItemsProvider.notifier)
                            .toggle(item);
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
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.items, required this.onRemove});

  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = constraints.maxWidth < 600 ? 2 : 3;
        final itemWidth =
            (constraints.maxWidth - 32 - 12 * (columns - 1)) / columns;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            mainAxisExtent: itemWidth + (textScale > 1.5 ? 240 : 116),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _FavoriteCard(
            item: items[index],
            onRemove: () => onRemove(items[index]),
          ),
        );
      },
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
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      onTap: () => context.push('/items/${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.medium),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl == null
                      ? const ItemPhotoPlaceholder()
                      : ItemPhotoImage(
                          source: coverUrl,
                          semanticLabel: 'Фото ${item.title}',
                          fit: BoxFit.cover,
                        ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: SizedBox.square(
                      dimension: 48,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.ink900,
                          foregroundColor: AppColors.surface,
                        ),
                        tooltip: 'Убрать из избранного',
                        onPressed: onRemove,
                        icon: const Icon(Icons.bookmark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_price(item.pricePerDay)} ₽ / день',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            [
              item.area,
              if (item.distanceBucket != null) item.distanceBucket,
            ].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
