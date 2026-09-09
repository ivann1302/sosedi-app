import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/catalog/data/catalog_service.dart';
import 'package:mobile/features/catalog/presentation/catalog_screen.dart';
import 'package:mobile/shared/widgets/inline_select_field.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

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
    expect(find.text('Хамовники'), findsOneWidget);
    expect(find.textContaining('улица'), findsNothing);
  });

  testWidgets('shows only the unclipped filter trigger by default', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item]),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ActionChip, 'Фильтры'), findsOneWidget);
    expect(find.text('Даты'), findsNothing);
    expect(find.text('Сначала новые'), findsNothing);
    expect(find.text('Все категории'), findsNothing);
    expect(find.text('Инструменты'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a 48px cloud search without a resting outline', (
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

    final field = find.byType(TextField);
    final decoration = tester.widget<TextField>(field).decoration!;

    expect(tester.getSize(field).height, 48);
    expect(decoration.fillColor, AppColors.cloud);
    expect(
      decoration.enabledBorder,
      isA<OutlineInputBorder>().having(
        (border) => border.borderSide,
        'borderSide',
        BorderSide.none,
      ),
    );
  });

  testWidgets('shows four complete products above phone navigation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final items = [
      for (var index = 1; index <= 4; index += 1)
        item.copyWith(id: 'item-$index', title: 'Вещь $index'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogServiceProvider.overrideWithValue(
            _FakeCatalogService([_page(items)]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: CatalogScreen(),
            bottomNavigationBar: SizedBox(height: 72),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final grid = find.byKey(const ValueKey('catalog-grid'));
    final fourth = find.bySemanticsLabel(RegExp('Открыть объявление Вещь 4'));
    expect(fourth, findsOneWidget);
    expect(
      tester.getBottomLeft(fourth).dy,
      lessThanOrEqualTo(tester.getBottomLeft(grid).dy),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('updates categories while the filter sheet stays open', (
    tester,
  ) async {
    final categories = Completer<List<CatalogCategory>>();
    final service = _FakeCatalogService([
      _page([item]),
    ], categories: categories.future);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Фильтры'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Инструменты'), findsNothing);

    categories.complete([item.category]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.widgetWithText(InlineSelectField<String>, 'Все категории'),
      findsOneWidget,
    );
    expect(find.text('Фильтры'), findsWidgets);
  });

  testWidgets('keeps the full-height filter sheet below the iOS status bar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 500);
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item]),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Фильтры'));
    await tester.pumpAndSettle();

    final title = find.text('Фильтры').last;
    expect(tester.getTopLeft(title).dy, greaterThanOrEqualTo(59));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows only the essential catalog filters', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item]),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Фильтры'));
    await tester.pumpAndSettle();

    expect(find.text('Даты'), findsWidgets);
    expect(
      find.byKey(const ValueKey('catalog-category-filter')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('catalog-area-filter')), findsOneWidget);
    expect(find.text('Цена за день'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Сортировка'), findsNothing);
    expect(find.text('Радиус поиска'), findsNothing);
    expect(find.textContaining('геолокац'), findsNothing);
  });

  testWidgets('lays out the themed price filter on a phone width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final service = _FakeCatalogService([
      _page([item]),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CatalogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Фильтры'));
    await tester.pump();

    expect(find.text('Цена за день'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps two catalog results reachable in a grid at 200% text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final drill = item.copyWith(id: 'item-2', title: 'Дрель');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogServiceProvider.overrideWithValue(
            _FakeCatalogService([
              _page([item, drill]),
            ]),
          ),
        ],
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

    final grid = find.byKey(const ValueKey('catalog-grid'));
    expect(grid, findsOneWidget);
    expect(
      tester.widget<GridView>(grid).gridDelegate,
      isA<SliverGridDelegateWithFixedCrossAxisCount>().having(
        (delegate) => delegate.crossAxisCount,
        'crossAxisCount',
        2,
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Открыть объявление Перфоратор')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Открыть объявление Дрель')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('switches the loaded catalog to the Yandex map', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item]),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Карта'), findsOneWidget);
    expect(find.textContaining('демо', findRichText: true), findsNothing);
    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
      'https://tiles.api-maps.yandex.ru/v1/tiles/'
      '?x={x}&y={y}&z={z}&lang=ru_RU&l=map'
      '&projection=web_mercator&apikey=tiles-key',
    );
    expect(find.text('Адреса указаны приблизительно'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-map-marker-item-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-1')),
      findsNothing,
    );
  });

  testWidgets('shows catalog list and map together on a wide screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item]),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('catalog-wide-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-wide-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Карта'), findsNothing);
    expect(find.text('Список'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('catalog-map-marker-item-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('catalog-grid')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-1')),
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
    await tester.tap(find.text('Фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Инструменты').last);
    await tester.pumpAndSettle();

    expect(service.searches, ['', 'дрель', 'дрель']);
    expect(service.categoryIds, [null, null, 'category-1']);
    expect(find.text('Дрель'), findsOneWidget);

    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();

    expect(find.text('Адреса указаны приблизительно'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-map-marker-item-2')),
      findsOneWidget,
    );
    expect(service.searches, hasLength(3));

    await tester.tap(find.text('Список'));
    await tester.pumpAndSettle();

    expect(find.text('дрель'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Инструменты'), findsOneWidget);
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

    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-map-marker-item-2')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-2')),
      findsOneWidget,
    );

    await tester.tap(find.text('Список'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-2')),
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
        GoRoute(
          path: '/catalog',
          builder: (_, _) => CatalogScreen(
            yandexTilesApiKey: 'tiles-key',
            mapTileProvider: _TransparentTileProvider(),
          ),
        ),
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

    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-map-marker-item-2')));
    await tester.pumpAndSettle();
    expect(find.text('Открыть'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('catalog-map-selected-item-2')));
    await tester.pumpAndSettle();

    expect(find.text('Карточка item-2'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Адреса указаны приблизительно'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-2')),
      findsOneWidget,
    );
    expect(service.searches, hasLength(1));
  });

  testWidgets('keeps the Yandex map usable on a small screen at 200% text', (
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
          home: CatalogScreen(
            yandexTilesApiKey: 'tiles-key',
            mapTileProvider: _TransparentTileProvider(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Показать карту'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Адреса указаны приблизительно'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-map-marker-item-1')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(FlutterMap)).width,
      tester.view.physicalSize.width,
    );
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-1')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('catalog-map-marker-item-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-1')),
      findsOneWidget,
    );
    expect(find.text('Открыть'), findsNothing);
  });

  testWidgets('closes the selected map item from the card and empty map', (
    tester,
  ) async {
    final service = _FakeCatalogService([
      _page([item]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('catalog-map-marker-item-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-1')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Закрыть карточку'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-1')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('catalog-map-marker-item-1')));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    map.options.onTap!(
      const TapPosition(Offset.zero, Offset.zero),
      const LatLng(55.8, 37.7),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('catalog-map-selected-item-1')),
      findsNothing,
    );
  });

  testWidgets('clusters nearby map items and expands them on tap', (
    tester,
  ) async {
    final nearby = item.copyWith(
      id: 'item-2',
      title: 'Дрель',
      approximateLocation: const ApproximateLocation(
        latitude: 55.751,
        longitude: 37.621,
        precision: 'SPARSE',
      ),
    );
    await tester.pumpWidget(
      _app(
        _FakeCatalogService([
          _page([item, nearby]),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();

    final cluster = find.byKey(const ValueKey('catalog-map-cluster-2'));
    expect(cluster, findsOneWidget);
    await tester.tap(cluster);
    await tester.pumpAndSettle();

    expect(cluster, findsNothing);
    expect(
      find.byKey(const ValueKey('catalog-map-marker-item-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('catalog-map-marker-item-2')),
      findsOneWidget,
    );
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
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('catalog-grid')),
        matching: find.byType(Scrollable),
      ),
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

    await tester.tap(find.text('Фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Инструменты').last);
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

  testWidgets('filters by a server-provided area without coordinates', (
    tester,
  ) async {
    final service = _FakeCatalogService([
      _page([item]),
      _page([item]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-area-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Хамовники').last);
    await tester.pumpAndSettle();

    expect(service.areas, [null, 'Хамовники']);
    expect(service.latitudes, [null, null]);
    expect(service.longitudes, [null, null]);
  });

  testWidgets('opens date controls from the filter sheet', (tester) async {
    final service = _FakeCatalogService([
      _page([item]),
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Даты'), findsNothing);
    expect(find.text('Цена за день'), findsNothing);

    await tester.tap(find.text('Фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InputChip, 'Даты'));
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

Widget _app(CatalogService service, {String yandexTilesApiKey = 'tiles-key'}) {
  return ProviderScope(
    overrides: [catalogServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      home: CatalogScreen(
        yandexTilesApiKey: yandexTilesApiKey,
        mapTileProvider: _TransparentTileProvider(),
      ),
    ),
  );
}

class _TransparentTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
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
  _FakeCatalogService(
    this.responses, {
    Future<List<CatalogCategory>>? categories,
  }) : _categories = categories ?? Future.value([item.category]),
       super(Dio());

  final List<Future<CatalogState> Function()> responses;
  final Future<List<CatalogCategory>> _categories;
  final List<int> offsets = [];
  final List<String> searches = [];
  final List<String?> categoryIds = [];
  final List<double?> minPrices = [];
  final List<double?> maxPrices = [];
  final List<double?> latitudes = [];
  final List<double?> longitudes = [];
  final List<double?> radii = [];
  final List<String> sorts = [];
  final List<String?> areas = [];
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
    String sort = 'newest',
    String? area,
  }) {
    offsets.add(offset);
    searches.add(search);
    categoryIds.add(categoryId);
    minPrices.add(minPrice);
    maxPrices.add(maxPrice);
    latitudes.add(latitude);
    longitudes.add(longitude);
    radii.add(radiusKm);
    sorts.add(sort);
    areas.add(area);
    return responses[_index++]();
  }

  @override
  Future<List<CatalogCategory>> fetchCategories() => _categories;

  @override
  Future<List<String>> fetchAreas() async => ['Арбат', 'Хамовники'];
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
