import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/favorites/data/favorite_service.dart';
import 'package:mobile/features/favorites/domain/favorite_controller.dart';

void main() {
  test('toggles one favorite without replacing unrelated cards', () async {
    final service = _FakeFavoriteService([item]);
    final container = ProviderContainer(
      overrides: [favoriteServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(favoriteItemsProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(favoriteItemsProvider.future);
    await container.read(favoriteItemsProvider.notifier).toggle(item);
    expect(container.read(favoriteItemsProvider).value, isEmpty);
    expect(service.removed, [item.id]);

    await container.read(favoriteItemsProvider.notifier).toggle(item);
    expect(container.read(favoriteItemsProvider).value, [item]);
    expect(service.added, [item.id]);
  });

  test('rolls an optimistic favorite change back after an API error', () async {
    final service = _FakeFavoriteService([])..failAdd = true;
    final container = ProviderContainer(
      overrides: [favoriteServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(favoriteItemsProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(favoriteItemsProvider.future);
    await expectLater(
      container.read(favoriteItemsProvider.notifier).toggle(item),
      throwsStateError,
    );

    expect(container.read(favoriteItemsProvider).value, isEmpty);
  });
}

class _FakeFavoriteService extends FavoriteService {
  _FakeFavoriteService(this.items) : super(Dio());

  final List<CatalogItem> items;
  final List<String> added = [];
  final List<String> removed = [];
  var failAdd = false;

  @override
  Future<List<CatalogItem>> list() async => items;

  @override
  Future<void> add(String itemId) async {
    if (failAdd) {
      throw StateError('offline');
    }
    added.add(itemId);
  }

  @override
  Future<void> remove(String itemId) async {
    removed.add(itemId);
  }
}

final item = CatalogItem(
  id: 'item-1',
  title: 'Проектор',
  description: 'Домашний проектор',
  condition: 'GOOD',
  completeness: 'Пульт и кабель',
  handoverTerms: 'Передача лично',
  pricePerDay: 500,
  category: const CatalogCategory(
    id: 'category-1',
    name: 'Для дома',
    slug: 'home',
    safetyNotice: 'Проверьте комплектность',
  ),
  owner: const CatalogOwner(id: 'owner-1', name: 'Иван'),
  area: 'Арбат',
  approximateLocation: const ApproximateLocation(
    latitude: 55.75,
    longitude: 37.65,
    precision: 'SPARSE',
  ),
  photos: const [],
  createdAt: DateTime.utc(2026, 8, 30),
  updatedAt: DateTime.utc(2026, 8, 30),
);
