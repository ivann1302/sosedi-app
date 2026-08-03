import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../data/catalog_models.dart';
import '../data/catalog_service.dart';

final catalogProvider = AsyncNotifierProvider<CatalogController, CatalogState>(
  CatalogController.new,
  retry: (_, _) => null,
);

final catalogCategoriesProvider = FutureProvider<List<CatalogCategory>>(
  (ref) => ref.watch(catalogServiceProvider).fetchCategories(),
  retry: (_, _) => null,
);

class CatalogController extends AsyncNotifier<CatalogState> {
  int _requestId = 0;
  String _search = '';
  String? _categoryId;
  double? _minPrice;
  double? _maxPrice;
  double? _latitude;
  double? _longitude;
  double? _radiusKm;

  @override
  Future<CatalogState> build() {
    _requestId += 1;
    return ref
        .watch(catalogServiceProvider)
        .fetchItems(
          search: _search,
          categoryId: _categoryId,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          latitude: _latitude,
          longitude: _longitude,
          radiusKm: _radiusKm,
        );
  }

  Future<void> refreshCatalog({bool preserveCurrent = true}) async {
    final requestId = ++_requestId;
    final current = preserveCurrent ? state.value : null;
    state = current == null
        ? const AsyncLoading()
        : AsyncData(current.copyWith(isRefreshing: true, refreshError: null));

    final next = await AsyncValue.guard(
      () => ref
          .read(catalogServiceProvider)
          .fetchItems(
            search: _search,
            categoryId: _categoryId,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            latitude: _latitude,
            longitude: _longitude,
            radiusKm: _radiusKm,
          ),
    );
    if (requestId == _requestId) {
      state = switch (next) {
        AsyncData(:final value) => AsyncData(value),
        AsyncError(:final error) when current != null => AsyncData(
          current.copyWith(
            isRefreshing: false,
            refreshError: userFacingError(
              error,
              fallback: 'Не удалось обновить каталог',
            ),
          ),
        ),
        _ => next,
      };
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    final requestId = _requestId;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final next = await AsyncValue.guard(
      () => ref
          .read(catalogServiceProvider)
          .fetchItems(
            offset: current.nextOffset,
            search: _search,
            categoryId: _categoryId,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            latitude: _latitude,
            longitude: _longitude,
            radiusKm: _radiusKm,
          ),
    );
    if (requestId != _requestId) {
      return;
    }

    state = switch (next) {
      AsyncData(:final value) => AsyncData(
        value.copyWith(items: [...current.items, ...value.items]),
      ),
      AsyncError(:final error) => AsyncData(
        current.copyWith(
          isLoadingMore: false,
          refreshError: userFacingError(
            error,
            fallback: 'Не удалось загрузить следующую страницу',
          ),
        ),
      ),
      _ => AsyncData(current),
    };
  }

  Future<void> search(String value) async {
    final normalized = value.trim();
    if (normalized == _search) {
      return;
    }
    _search = normalized;
    await refreshCatalog(preserveCurrent: false);
  }

  Future<void> selectCategory(String? value) async {
    final normalized = value == null || value.isEmpty ? null : value;
    if (normalized == _categoryId) {
      return;
    }
    _categoryId = normalized;
    await refreshCatalog(preserveCurrent: false);
  }

  Future<void> setPriceRange(double? minPrice, double? maxPrice) async {
    if (minPrice == _minPrice && maxPrice == _maxPrice) {
      return;
    }
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    await refreshCatalog(preserveCurrent: false);
  }

  Future<void> setRadius(double? radiusKm) async {
    if (radiusKm == null) {
      if (_radiusKm == null) {
        return;
      }
      _latitude = null;
      _longitude = null;
      _radiusKm = null;
    } else {
      if (radiusKm == _radiusKm) {
        return;
      }
      final position = await ref
          .read(locationServiceProvider)
          .currentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      _radiusKm = radiusKm;
    }
    await refreshCatalog(preserveCurrent: false);
  }
}
