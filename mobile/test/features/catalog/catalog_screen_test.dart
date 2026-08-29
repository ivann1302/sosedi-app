import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/location/location_service.dart';
import 'package:mobile/core/permissions/app_permissions.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/catalog/data/catalog_service.dart';
import 'package:mobile/features/catalog/presentation/catalog_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('shows loading while the catalog request is pending', (
    tester,
  ) async {
    final pending = Completer<CatalogState>();
    final service = _FakeCatalogService([() => pending.future]);
    await tester.pumpWidget(_app(service));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(_state([]));
    await tester.pumpAndSettle();
  });

  testWidgets('shows catalog card without an exact location', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item]),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Перфоратор'), findsOneWidget);
    expect(find.text('450 ₽ / день'), findsOneWidget);
    expect(find.text('Инструменты · Хамовники'), findsOneWidget);
    expect(find.textContaining('улица'), findsNothing);
  });

  testWidgets('switches the loaded catalog to the local demo map', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item]),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Карта (демо)'));
    await tester.pumpAndSettle();

    expect(find.text('Приблизительное расположение'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('demo-map-marker-item-1')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Точные адреса не показываются'),
      findsOneWidget,
    );
  });

  testWidgets('keeps search and category while switching list and map', (
    tester,
  ) async {
    final drill = item.copyWith(id: 'item-2', title: 'Дрель');
    final service = _FakeCatalogService([
      _page([item]),
      _page([drill]),
      _page([drill]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'дрель');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Инструменты'));
    await tester.pumpAndSettle();

    expect(service.searches, ['', 'дрель', 'дрель']);
    expect(service.categoryIds, [null, null, 'category-1']);
    expect(find.text('Дрель'), findsOneWidget);

    await tester.tap(find.text('Карта (демо)'));
    await tester.pumpAndSettle();

    expect(find.text('Приблизительное расположение'), findsOneWidget);
    expect(find.text('Дрель'), findsOneWidget);
    expect(service.searches, hasLength(3));

    await tester.tap(find.text('Список'));
    await tester.pumpAndSettle();

    final category = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Инструменты'),
    );
    expect(find.text('дрель'), findsOneWidget);
    expect(category.selected, isTrue);
    expect(find.text('Дрель'), findsOneWidget);
    expect(service.searches, hasLength(3));
  });

  testWidgets('keeps the selected map item after returning from the list', (
    tester,
  ) async {
    final drill = item.copyWith(
      id: 'item-2',
      title: 'Дрель',
      approximateLocation: const ApproximateLocation(
        latitude: 55.76,
        longitude: 37.64,
        precision: 'SPARSE',
      ),
    );
    final service = _FakeCatalogService([
      _page([item, drill]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Карта (демо)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-map-marker-item-2')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('demo-map-selected-item-2')),
      findsOneWidget,
    );

    await tester.tap(find.text('Список'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Карта (демо)'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('demo-map-selected-item-2')),
      findsOneWidget,
    );
    expect(service.searches, hasLength(1));
  });

  testWidgets('opens the selected map item and restores the map on back', (
    tester,
  ) async {
    final drill = item.copyWith(
      id: 'item-2',
      title: 'Дрель',
      approximateLocation: const ApproximateLocation(
        latitude: 55.76,
        longitude: 37.64,
        precision: 'SPARSE',
      ),
    );
    final service = _FakeCatalogService([
      _page([item, drill]),
    ]);
    final router = GoRouter(
      initialLocation: '/catalog',
      routes: [
        GoRoute(path: '/catalog', builder: (_, _) => const CatalogScreen()),
        GoRoute(
          path: '/items/:id',
          builder: (_, state) => Scaffold(
            appBar: AppBar(),
            body: Text('Карточка ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogServiceProvider.overrideWithValue(service)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Карта (демо)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-map-marker-item-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.text('Карточка item-2'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Приблизительное расположение'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('demo-map-selected-item-2')),
      findsOneWidget,
    );
    expect(service.searches, hasLength(1));
  });

  testWidgets('keeps the demo map usable on a small screen at 200% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final service = _FakeCatalogService([
      _page([item]),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const CatalogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Показать демо-карту'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Приблизительное расположение'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('demo-map-marker-item-1')),
      findsOneWidget,
    );
    expect(find.text('Открыть'), findsOneWidget);
  });

  testWidgets('shows an empty catalog', (tester) async {
    await tester.pumpWidget(_app(_FakeCatalogService([_page([])])));
    await tester.pumpAndSettle();

    expect(find.text('Пока нет доступных вещей'), findsOneWidget);
  });

  testWidgets('retries after a catalog error', (tester) async {
    var attempts = 0;
    final service = _FakeCatalogService([
      () async {
        attempts += 1;
        throw Exception('offline');
      },
      () async {
        attempts += 1;
        return _state([item]);
      },
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить каталог'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Перфоратор'), findsOneWidget);
  });

  testWidgets('loads the next server page on demand', (tester) async {
    final second = item.copyWith(id: 'item-2', title: 'Дрель');
    final service = _FakeCatalogService([
      _page([item], hasMore: true, nextOffset: 1),
      _page([second], nextOffset: 2),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Показать ещё'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Показать ещё'));
    await tester.pumpAndSettle();

    expect(service.offsets, [0, 1]);
    expect(find.text('Перфоратор'), findsOneWidget);
    expect(find.text('Дрель'), findsOneWidget);
  });

  testWidgets('submits server search and resets the page', (tester) async {
    final drill = item.copyWith(id: 'item-2', title: 'Дрель');
    final service = _FakeCatalogService([
      _page([item]),
      _page([drill]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  дрель  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(service.searches, ['', 'дрель']);
    expect(service.offsets, [0, 0]);
    expect(find.text('Дрель'), findsOneWidget);
  });

  testWidgets('filters the catalog by a public category', (tester) async {
    final service = _FakeCatalogService([
      _page([item]),
      _page([item]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Инструменты'));
    await tester.pumpAndSettle();

    expect(service.categoryIds, [null, 'category-1']);
    expect(service.offsets, [0, 0]);
  });

  testWidgets('validates and submits a server price range', (tester) async {
    final service = _FakeCatalogService([
      _page([item]),
      _page([item]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Цена за день'), findsNothing);
    await tester.tap(find.text('Фильтры'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'От'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'До'), '500');
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();

    expect(service.minPrices, [null, 100]);
    expect(service.maxPrices, [null, 500]);
    expect(service.offsets, [0, 0]);
  });

  testWidgets('filters the catalog by radius after explicit permission', (
    tester,
  ) async {
    final service = _FakeCatalogService([
      _page([item]),
      _page([item]),
    ]);
    await tester.pumpWidget(
      _app(
        service,
        permissionGateway: const _GrantedPermissionGateway(),
        locationService: const _FakeLocationService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Без ограничения'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('До 5 км').last);
    await tester.pumpAndSettle();

    expect(service.latitudes, [null, 55.75]);
    expect(service.longitudes, [null, 37.62]);
    expect(service.radii, [null, 5]);
    expect(service.offsets, [0, 0]);
  });

  testWidgets('keeps dates in the compact filter row', (tester) async {
    final service = _FakeCatalogService([
      _page([item]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Даты'), findsOneWidget);
    expect(find.text('Цена за день'), findsNothing);

    await tester.tap(find.text('Даты'));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('opens an item and returns to the same catalog', (tester) async {
    final service = _FakeCatalogService([
      _page([item]),
    ]);
    final router = GoRouter(
      initialLocation: '/catalog',
      routes: [
        GoRoute(path: '/catalog', builder: (_, _) => const CatalogScreen()),
        GoRoute(
          path: '/items/:id',
          builder: (_, state) => Scaffold(
            appBar: AppBar(),
            body: Text('Карточка ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogServiceProvider.overrideWithValue(service)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перфоратор'));
    await tester.pumpAndSettle();
    expect(find.text('Карточка item-1'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Перфоратор'), findsOneWidget);
  });
}

Widget _app(
  CatalogService service, {
  AppPermissionGateway? permissionGateway,
  LocationService? locationService,
}) {
  return ProviderScope(
    overrides: [
      catalogServiceProvider.overrideWithValue(service),
      if (permissionGateway != null)
        appPermissionGatewayProvider.overrideWithValue(permissionGateway),
      if (locationService != null)
        locationServiceProvider.overrideWithValue(locationService),
    ],
    child: const MaterialApp(home: CatalogScreen()),
  );
}

class _FakeLocationService extends LocationService {
  const _FakeLocationService();

  @override
  Future<GeoPoint> currentPosition() async =>
      (latitude: 55.75, longitude: 37.62);
}

class _GrantedPermissionGateway implements AppPermissionGateway {
  const _GrantedPermissionGateway();

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<PermissionStatus> request(AppPermission permission) async =>
      PermissionStatus.granted;
}

Future<CatalogState> Function() _page(
  List<CatalogItem> items, {
  bool hasMore = false,
  int? nextOffset,
}) {
  return () async => _state(items, hasMore: hasMore, nextOffset: nextOffset);
}

CatalogState _state(
  List<CatalogItem> items, {
  bool hasMore = false,
  int? nextOffset,
}) {
  return CatalogState(
    items: items,
    hasMore: hasMore,
    nextOffset: nextOffset ?? items.length,
  );
}

class _FakeCatalogService extends CatalogService {
  _FakeCatalogService(this.responses) : super(Dio());

  final List<Future<CatalogState> Function()> responses;
  final List<int> offsets = [];
  final List<String> searches = [];
  final List<String?> categoryIds = [];
  final List<double?> minPrices = [];
  final List<double?> maxPrices = [];
  final List<double?> latitudes = [];
  final List<double?> longitudes = [];
  final List<double?> radii = [];
  int _index = 0;

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
    searches.add(search);
    categoryIds.add(categoryId);
    minPrices.add(minPrice);
    maxPrices.add(maxPrice);
    latitudes.add(latitude);
    longitudes.add(longitude);
    radii.add(radiusKm);
    return responses[_index++]();
  }

  @override
  Future<List<CatalogCategory>> fetchCategories() async => [item.category];
}

final item = CatalogItem(
  id: 'item-1',
  title: 'Перфоратор',
  description: 'Рабочий',
  condition: 'GOOD',
  completeness: 'Кейс',
  handoverTerms: 'Проверить при передаче',
  pricePerDay: 450,
  depositAmount: 2000,
  category: const CatalogCategory(
    id: 'category-1',
    name: 'Инструменты',
    slug: 'tools',
    safetyNotice: 'Используйте защитные очки',
  ),
  owner: const CatalogOwner(id: 'owner-1', name: 'Иван', city: 'Москва'),
  area: 'Хамовники',
  approximateLocation: const ApproximateLocation(
    latitude: 55.75,
    longitude: 37.62,
    precision: 'SPARSE',
  ),
  photos: const [],
  createdAt: DateTime.utc(2026, 7, 29),
  updatedAt: DateTime.utc(2026, 7, 29),
);
