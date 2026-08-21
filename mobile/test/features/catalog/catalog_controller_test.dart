import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/catalog/data/catalog_service.dart';
import 'package:mobile/features/catalog/domain/catalog_controller.dart';

void main() {
  test('ignores an old pagination response after refresh', () async {
    final service = _ControlledCatalogService();
    final container = ProviderContainer(
      overrides: [catalogServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final initial = container.read(catalogProvider.future);
    service.calls[0].complete(_state('initial', hasMore: true));
    await initial;

    final loadMore = container.read(catalogProvider.notifier).loadMore();
    final refresh = container.read(catalogProvider.notifier).refreshCatalog();
    service.calls[2].complete(_state('fresh'));
    await refresh;
    service.calls[1].complete(_state('stale'));
    await loadMore;

    expect(container.read(catalogProvider).value?.items.single.id, 'fresh');
    expect(service.offsets, [0, 1, 0]);
  });

  test('keeps loaded items stale when refresh is offline', () async {
    final service = _ControlledCatalogService();
    final container = ProviderContainer(
      overrides: [catalogServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final initial = container.read(catalogProvider.future);
    service.calls[0].complete(_state('initial'));
    await initial;

    final refresh = container.read(catalogProvider.notifier).refreshCatalog();
    expect(container.read(catalogProvider).value?.isRefreshing, isTrue);
    service.calls[1].completeError(
      const ApiException(
        code: 'OFFLINE',
        message: 'Нет подключения к интернету',
      ),
    );
    await refresh;

    final state = container.read(catalogProvider).value!;
    expect(state.items.single.id, 'initial');
    expect(state.isRefreshing, isFalse);
    expect(state.refreshError, 'Нет подключения к интернету');
  });

  test('uses the current position for radius refresh and pagination', () async {
    final service = _ControlledCatalogService();
    final container = ProviderContainer(
      overrides: [
        catalogServiceProvider.overrideWithValue(service),
        locationServiceProvider.overrideWithValue(const _FakeLocationService()),
      ],
    );
    addTearDown(container.dispose);

    final initial = container.read(catalogProvider.future);
    service.calls[0].complete(_state('initial'));
    await initial;

    final filter = container.read(catalogProvider.notifier).setRadius(5);
    await Future<void>.delayed(Duration.zero);
    service.calls[1].complete(_state('nearby', hasMore: true));
    await filter;
    final loadMore = container.read(catalogProvider.notifier).loadMore();
    service.calls[2].complete(_state('next'));
    await loadMore;

    expect(service.latitudes, [null, 55.75, 55.75]);
    expect(service.longitudes, [null, 37.62, 37.62]);
    expect(service.radii, [null, 5, 5]);
    expect(service.offsets, [0, 0, 1]);
  });

  test('uses the selected dates for refresh and pagination', () async {
    final service = _ControlledCatalogService();
    final container = ProviderContainer(
      overrides: [catalogServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final initial = container.read(catalogProvider.future);
    service.calls[0].complete(_state('initial'));
    await initial;

    final filter = container
        .read(catalogProvider.notifier)
        .setAvailability('2026-08-12', '2026-08-14');
    await Future<void>.delayed(Duration.zero);
    service.calls[1].complete(_state('available', hasMore: true));
    await filter;
    final loadMore = container.read(catalogProvider.notifier).loadMore();
    service.calls[2].complete(_state('next'));
    await loadMore;

    expect(service.availableFrom, [null, '2026-08-12', '2026-08-12']);
    expect(service.availableTo, [null, '2026-08-14', '2026-08-14']);
  });
}

class _FakeLocationService extends LocationService {
  const _FakeLocationService();

  @override
  Future<GeoPoint> currentPosition() async =>
      (latitude: 55.75, longitude: 37.62);
}

class _ControlledCatalogService extends CatalogService {
  _ControlledCatalogService() : super(Dio());

  final List<Completer<CatalogState>> calls = [];
  final List<int> offsets = [];
  final List<double?> latitudes = [];
  final List<double?> longitudes = [];
  final List<double?> radii = [];
  final List<String?> availableFrom = [];
  final List<String?> availableTo = [];

  @override
  Future<CatalogState> fetchItems({
    int limit = 20,
    int offset = 0,
    String search = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? availableFrom,
    String? availableTo,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) {
    offsets.add(offset);
    latitudes.add(latitude);
    longitudes.add(longitude);
    radii.add(radiusKm);
    this.availableFrom.add(availableFrom);
    this.availableTo.add(availableTo);
    final completer = Completer<CatalogState>();
    calls.add(completer);
    return completer.future;
  }
}

CatalogState _state(String id, {bool hasMore = false}) {
  return CatalogState(
    items: [
      CatalogItem(
        id: id,
        title: id,
        description: id,
        condition: 'GOOD',
        completeness: 'Кейс',
        handoverTerms: 'Передача',
        pricePerDay: 100,
        category: const CatalogCategory(
          id: 'category',
          name: 'Категория',
          slug: 'category',
          safetyNotice: 'Безопасность',
        ),
        owner: const CatalogOwner(id: 'owner'),
        area: 'Район',
        approximateLocation: const ApproximateLocation(
          latitude: 55,
          longitude: 37,
          precision: 'SPARSE',
        ),
        photos: const [],
        createdAt: DateTime.utc(2026, 7, 29),
        updatedAt: DateTime.utc(2026, 7, 29),
      ),
    ],
    hasMore: hasMore,
    nextOffset: 1,
  );
}
