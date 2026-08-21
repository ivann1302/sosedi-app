import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/catalog/data/catalog_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('loads and maps the first stable catalog page', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/items');
      expect(options.queryParameters, {
        'limit': 21,
        'offset': 0,
        'sort': 'newest',
        'search': 'дрель',
        'availableFrom': '2026-08-12',
        'availableTo': '2026-08-14',
        'minPrice': 100.0,
        'maxPrice': 500.0,
        'latitude': 55.75,
        'longitude': 37.62,
        'radiusKm': 5.0,
      });
      return jsonResponse({
        'success': true,
        'data': [catalogItemJson()],
        'error': null,
      });
    });
    final service = CatalogService(Dio()..httpClientAdapter = adapter);

    final page = await service.fetchItems(
      search: 'дрель',
      availableFrom: '2026-08-12',
      availableTo: '2026-08-14',
      minPrice: 100,
      maxPrice: 500,
      latitude: 55.75,
      longitude: 37.62,
      radiusKm: 5,
    );

    expect(page.items, hasLength(1));
    expect(page.hasMore, isFalse);
    expect(page.nextOffset, 1);
    expect(page.items.single.title, 'Перфоратор');
    expect(page.items.single.pricePerDay, 450);
    expect(page.items.single.area, 'Хамовники');
    expect(page.items.single.approximateLocation.latitude, 55.75);
    expect(page.items.single.photos.single.isCover, isTrue);
  });

  test('loads only public listing categories', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/categories');
      return jsonResponse({
        'success': true,
        'data': [
          {
            ...(catalogItemJson()['category']! as Map<String, Object?>),
            'sortOrder': 1,
            'isActive': true,
            'isAllowedForListings': true,
            'listingPolicy': 'ALLOWED',
            'createdAt': '2026-07-01T00:00:00.000Z',
            'updatedAt': '2026-07-01T00:00:00.000Z',
          },
        ],
        'error': null,
      });
    });
    final service = CatalogService(Dio()..httpClientAdapter = adapter);

    final categories = await service.fetchCategories();

    expect(categories.single.name, 'Инструменты');
  });
}

Map<String, Object?> catalogItemJson() => {
  'id': '11111111-1111-4111-8111-111111111111',
  'title': 'Перфоратор',
  'description': 'Рабочий перфоратор',
  'condition': 'GOOD',
  'completeness': 'Кейс и два бура',
  'handoverTerms': 'Проверить при передаче',
  'pricePerDay': 450,
  'depositAmount': 2000.50,
  'category': {
    'id': '22222222-2222-4222-8222-222222222222',
    'name': 'Инструменты',
    'slug': 'tools',
    'iconName': 'construction',
    'safetyNotice': 'Используйте защитные очки',
  },
  'owner': {
    'id': '33333333-3333-4333-8333-333333333333',
    'name': 'Иван',
    'city': 'Москва',
    'avatarUrl': null,
  },
  'area': 'Хамовники',
  'approximateLocation': {
    'latitude': 55.75,
    'longitude': 37,
    'precision': 'SPARSE',
  },
  'distanceBucket': 'FROM_1_TO_3_KM',
  'photos': [
    {
      'id': '44444444-4444-4444-8444-444444444444',
      'thumbnailUrl': null,
      'previewUrl': null,
      'sortOrder': 0,
      'isCover': true,
      'createdAt': '2026-07-29T00:00:00.000Z',
    },
  ],
  'createdAt': '2026-07-29T00:00:00.000Z',
  'updatedAt': '2026-07-29T01:00:00.000Z',
};
