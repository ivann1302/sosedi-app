import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/item/data/item_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('loads the public item details contract', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/items/item-1');
      return jsonResponse({'success': true, 'data': itemJson(), 'error': null});
    });
    final service = ItemService(Dio()..httpClientAdapter = adapter);

    final item = await service.fetchItem('item-1');

    expect(item.title, 'Перфоратор');
    expect(item.area, 'Хамовники');
    expect(item.pricePerDay, 450);
  });

  test('maps an unavailable item to ITEM_NOT_FOUND', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': false,
        'data': null,
        'error': {'code': 'NOT_FOUND', 'message': 'Не найдено'},
      }, statusCode: 404),
    );
    final service = ItemService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.fetchItem('missing'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'ITEM_NOT_FOUND',
        ),
      ),
    );
  });
}

Map<String, Object?> itemJson() => {
  'id': 'item-1',
  'title': 'Перфоратор',
  'description': 'Рабочий перфоратор',
  'condition': 'GOOD',
  'completeness': 'Кейс и два бура',
  'handoverTerms': 'Проверить при передаче',
  'pricePerDay': 450,
  'depositAmount': null,
  'category': {
    'id': 'category-1',
    'name': 'Инструменты',
    'slug': 'tools',
    'iconName': 'construction',
    'safetyNotice': 'Используйте защитные очки',
  },
  'owner': {
    'id': 'owner-1',
    'name': 'Иван',
    'city': 'Москва',
    'avatarUrl': null,
  },
  'area': 'Хамовники',
  'approximateLocation': {
    'latitude': 55.75,
    'longitude': 37.62,
    'precision': 'SPARSE',
  },
  'distanceBucket': null,
  'photos': <Object?>[],
  'createdAt': '2026-07-29T00:00:00.000Z',
  'updatedAt': '2026-07-29T01:00:00.000Z',
};
