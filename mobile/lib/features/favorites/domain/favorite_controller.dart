import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_models.dart';
import '../data/favorite_service.dart';

final favoriteItemsProvider =
    AsyncNotifierProvider.autoDispose<FavoriteController, List<CatalogItem>>(
      FavoriteController.new,
      retry: (_, _) => null,
    );

class FavoriteController extends AsyncNotifier<List<CatalogItem>> {
  final Set<String> _mutatingItemIds = {};

  @override
  Future<List<CatalogItem>> build() {
    return ref.watch(favoriteServiceProvider).list();
  }

  Future<void> toggle(CatalogItem item) async {
    if (!_mutatingItemIds.add(item.id)) {
      return;
    }

    final previous = state.value ?? await future;
    final wasFavorite = previous.any((value) => value.id == item.id);
    final next = wasFavorite
        ? previous.where((value) => value.id != item.id).toList(growable: false)
        : [item, ...previous];
    state = AsyncData(next);

    try {
      final service = ref.read(favoriteServiceProvider);
      if (wasFavorite) {
        await service.remove(item.id);
      } else {
        await service.add(item.id);
      }
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _mutatingItemIds.remove(item.id);
    }
  }
}
