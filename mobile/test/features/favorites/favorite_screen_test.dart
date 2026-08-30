import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/favorites/data/favorite_service.dart';
import 'package:mobile/features/favorites/presentation/favorites_screen.dart';

void main() {
  testWidgets('shows favorite cards and removes one in place', (tester) async {
    final service = _FakeFavoriteService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [favoriteServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: FavoritesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Избранное'), findsOneWidget);
    expect(find.text('Проектор'), findsOneWidget);

    await tester.tap(find.byTooltip('Убрать из избранного'));
    await tester.pumpAndSettle();

    expect(service.removed, [item.id]);
    expect(find.text('В избранном пока ничего нет'), findsOneWidget);
  });
}

class _FakeFavoriteService extends FavoriteService {
  _FakeFavoriteService() : super(Dio());

  final List<String> removed = [];

  @override
  Future<List<CatalogItem>> list() async => [item];

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
