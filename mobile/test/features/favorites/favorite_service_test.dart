import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/favorites/data/favorite_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('lists private favorite cards', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/items/favorites');
      return jsonResponse({
        'success': true,
        'data': [favoriteItemJson],
        'error': null,
      });
    });
    final service = FavoriteService(Dio()..httpClientAdapter = adapter);

    final items = await service.list();

    expect(items.single.id, favoriteItemJson['id']);
    expect(items.single.title, 'Перфоратор');
  });

  test('uses idempotent add and scoped remove endpoints', () async {
    final adapter = CallbackAdapter((options) {
      return jsonResponse({
        'success': true,
        'data': {'itemId': favoriteItemJson['id']},
        'error': null,
      });
    });
    final service = FavoriteService(Dio()..httpClientAdapter = adapter);

    await service.add(favoriteItemJson['id']! as String);
    await service.remove(favoriteItemJson['id']! as String);

    expect(adapter.requests[0].method, 'PUT');
    expect(
      adapter.requests[0].path,
      '/items/${favoriteItemJson['id']}/favorite',
    );
    expect(adapter.requests[1].method, 'DELETE');
    expect(
      adapter.requests[1].path,
      '/items/${favoriteItemJson['id']}/favorite',
    );
  });
}

final favoriteItemJson = <String, Object?>{
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
  'distanceBucket': null,
  'photos': <Object>[],
  'createdAt': '2026-07-29T00:00:00.000Z',
  'updatedAt': '2026-07-29T01:00:00.000Z',
};
