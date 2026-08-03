import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/item/data/owned_item_models.dart';
import 'package:mobile/features/item/data/owned_items_service.dart';
import 'package:mobile/features/item/presentation/owned_items_screen.dart';

void main() {
  testWidgets('shows moderation statuses for the actor listings', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ownedItemsProvider.overrideWith((ref) async => items)],
        child: const MaterialApp(home: OwnedItemsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Перфоратор'), findsOneWidget);
    expect(find.textContaining('На модерации'), findsOneWidget);
    expect(find.text('Проектор'), findsOneWidget);
    expect(find.textContaining('Нужны исправления'), findsOneWidget);
    expect(find.textContaining('Добавьте комплект'), findsOneWidget);
  });

  testWidgets('hides an owned listing only after confirmation', (tester) async {
    final service = _FakeOwnedItemsService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownedItemsProvider.overrideWith((ref) async => [items.first]),
          ownedItemsServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: OwnedItemsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Скрыть объявление'));
    await tester.pumpAndSettle();
    expect(service.hiddenItemId, isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Скрыть'));
    await tester.pumpAndSettle();

    expect(service.hiddenItemId, 'item-1');
    expect(find.text('Объявление скрыто'), findsOneWidget);
  });

  testWidgets('shows a safe conflict when an active rental blocks hiding', (
    tester,
  ) async {
    final service = _FakeOwnedItemsService(fail: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownedItemsProvider.overrideWith((ref) async => [items.first]),
          ownedItemsServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: OwnedItemsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Скрыть объявление'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Скрыть'));
    await tester.pumpAndSettle();

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>();
    expect(texts, contains('Сначала завершите активную аренду'));
  });
}

class _FakeOwnedItemsService extends OwnedItemsService {
  _FakeOwnedItemsService({this.fail = false}) : super(Dio());

  final bool fail;
  String? hiddenItemId;

  @override
  Future<OwnedItem> hideItem(String id) async {
    if (fail) {
      throw const ApiException(
        code: 'ITEM_HAS_UNFINISHED_BOOKINGS',
        message: 'Сначала завершите активную аренду',
      );
    }
    hiddenItemId = id;
    return items.first.copyWith(status: 'HIDDEN');
  }
}

final items = [
  OwnedItem(
    id: 'item-1',
    title: 'Перфоратор',
    description: 'Рабочий перфоратор для домашних работ',
    condition: 'GOOD',
    completeness: 'Кейс и два бура',
    handoverTerms: 'Проверить при передаче',
    status: 'PENDING',
    publicArea: 'Хамовники',
    address: 'Москва, улица Примерная, 1',
    latitude: 55.75,
    longitude: 37.62,
    pricePerDay: 450,
    depositAmount: null,
    category: category,
    updatedAt: DateTime.utc(2026, 7, 29),
    photos: const [],
  ),
  OwnedItem(
    id: 'item-2',
    title: 'Проектор',
    description: 'Проектор для домашнего кинотеатра',
    condition: 'GOOD',
    completeness: 'Проектор и кабель питания',
    handoverTerms: 'Проверить при передаче',
    status: 'REJECTED',
    publicArea: 'Арбат',
    address: 'Москва, улица Новый Арбат, 1',
    latitude: 55.752,
    longitude: 37.6,
    pricePerDay: 500,
    depositAmount: null,
    category: category,
    rejectReason: 'Добавьте комплект',
    updatedAt: DateTime.utc(2026, 7, 29),
    photos: const [],
  ),
];

const category = CatalogCategory(
  id: 'category-1',
  name: 'Инструменты',
  slug: 'tools',
  safetyNotice: 'Используйте защитные очки',
);
