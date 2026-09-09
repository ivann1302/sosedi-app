import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/map/presentation/map_point_picker_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/map/data/yandex_tiles.dart';

void main() {
  testWidgets('Tiles requests identify the app for domain restrictions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MapPointPickerScreen(initialPoint: null, apiKey: 'fixture-key'),
        ),
      ),
    );
    final layer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(layer.tileProvider.headers['Referer'], 'https://sosedi-app.ru/');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'builds the official Web Mercator tile URL without changing markers',
    () {
      expect(
        buildYandexTileUrlTemplate('tiles-key'),
        'https://tiles.api-maps.yandex.ru/v1/tiles/'
        '?x={x}&y={y}&z={z}&lang=ru_RU&l=map'
        '&projection=web_mercator&apikey=tiles-key',
      );
    },
  );

  test('encodes an unexpected key value as a query parameter', () {
    expect(
      buildYandexTileUrlTemplate('key with +'),
      endsWith('key%20with%20%2B'),
    );
  });
}
