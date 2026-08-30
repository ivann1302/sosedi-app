import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../catalog/data/catalog_models.dart';
import '../domain/favorite_controller.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({required this.item, super.key});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authControllerProvider) is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    final favorites = ref.watch(favoriteItemsProvider);
    final isFavorite =
        favorites.value?.any((value) => value.id == item.id) ?? false;
    return SizedBox.square(
      dimension: 48,
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.ink900,
          foregroundColor: AppColors.surface,
        ),
        tooltip: isFavorite ? 'Убрать из избранного' : 'Добавить в избранное',
        onPressed: () async {
          try {
            await ref.read(favoriteItemsProvider.notifier).toggle(item);
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
        icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
      ),
    );
  }
}
