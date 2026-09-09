import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/map/data/yandex_tiles.dart';

void main() {
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
