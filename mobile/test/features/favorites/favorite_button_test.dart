import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/favorites/data/favorite_service.dart';
import 'package:mobile/features/favorites/presentation/favorite_button.dart';

void main() {
  testWidgets('authenticated user can add a public item to favorites', (
    tester,
  ) async {
    final service = _FakeFavoriteService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_AuthenticatedController.new),
          favoriteServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(body: FavoriteButton(item: item)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Добавить в избранное'));
    await tester.pumpAndSettle();

    expect(service.added, [item.id]);
    expect(find.byTooltip('Убрать из избранного'), findsOneWidget);
  });
}

class _AuthenticatedController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'user-1',
      phone: '+79991234567',
      role: 'USER',
      isBlocked: false,
    ),
  );
}

class _FakeFavoriteService extends FavoriteService {
  _FakeFavoriteService() : super(Dio());

  final List<String> added = [];

  @override
  Future<List<CatalogItem>> list() async => [];

  @override
  Future<void> add(String itemId) async {
    added.add(itemId);
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
