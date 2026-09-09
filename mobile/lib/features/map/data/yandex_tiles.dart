const yandexTilesReferer = 'https://sosedi-app.ru/';

String buildYandexTileUrlTemplate(String apiKey) {
  final encodedKey = Uri.encodeComponent(apiKey);
  return 'https://tiles.api-maps.yandex.ru/v1/tiles/'
      '?x={x}&y={y}&z={z}&lang=ru_RU&l=map'
      '&projection=web_mercator&apikey=$encodedKey';
}
