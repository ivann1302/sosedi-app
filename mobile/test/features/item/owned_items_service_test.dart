import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/item/data/owned_item_models.dart';
import 'package:mobile/features/item/data/owned_items_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('loads only the authenticated actor private listings', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/items/mine');
      return jsonResponse({
        'success': true,
        'data': [ownedItemJson()],
        'error': null,
      });
    });
    final service = OwnedItemsService(Dio()..httpClientAdapter = adapter);

    final items = await service.fetchOwnedItems();

    expect(items.single.title, 'Перфоратор');
    expect(items.single.status, 'PENDING');
    expect(items.single.publicArea, 'Хамовники');
    expect(items.single.condition, 'GOOD');
    expect(items.single.completeness, 'Кейс и два бура');
    expect(items.single.address, 'Москва, улица Примерная, 1');
    expect(items.single.latitude, 55.75);
  });

  test(
    'updates the complete mutable item contract and reads PENDING',
    () async {
      const update = UpdateItemDraft(
        title: 'Перфоратор Bosch',
        description: 'Обновлённое подробное описание перфоратора',
        categoryId: 'category-1',
        condition: 'LIKE_NEW',
        completeness: 'Кейс, два бура и ограничитель',
        handoverTerms: 'Проверить при встрече',
        pricePerDay: 500,
        publicArea: 'Арбат',
        address: 'Москва, улица Новый Арбат, 1',
        latitude: 55.752,
        longitude: 37.6,
      );
      final adapter = CallbackAdapter((options) {
        expect(options.method, 'PATCH');
        expect(options.path, '/items/item-1');
        expect(options.data, update.toJson());
        return jsonResponse({
          'success': true,
          'data': {...ownedItemJson(), ...update.toJson(), 'status': 'PENDING'},
          'error': null,
        });
      });
      final service = OwnedItemsService(Dio()..httpClientAdapter = adapter);

      final item = await service.updateItem('item-1', update);

      expect(item.title, 'Перфоратор Bosch');
      expect(item.status, 'PENDING');
    },
  );

  test('preserves a safe update conflict from the backend', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': false,
        'data': null,
        'error': {
          'code': 'ITEM_NOT_EDITABLE',
          'message': 'Объявление нельзя изменить',
        },
      }, statusCode: 409),
    );
    final service = OwnedItemsService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.updateItem(
        'item-1',
        const UpdateItemDraft(
          title: 'Перфоратор',
          description: 'Подробное описание перфоратора',
          categoryId: 'category-1',
          condition: 'GOOD',
          completeness: 'Кейс и два бура',
          handoverTerms: 'Проверить при передаче',
          pricePerDay: 450,
          publicArea: 'Хамовники',
          address: 'Москва, улица Примерная, 1',
          latitude: 55.75,
          longitude: 37.62,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'ITEM_NOT_EDITABLE',
        ),
      ),
    );
  });

  test('hides an owned item through the protected endpoint', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'PATCH');
      expect(options.path, '/items/item-1/hide');
      return jsonResponse({
        'success': true,
        'data': {...ownedItemJson(), 'status': 'HIDDEN'},
        'error': null,
      });
    });
    final service = OwnedItemsService(Dio()..httpClientAdapter = adapter);

    final item = await service.hideItem('item-1');

    expect(item.status, 'HIDDEN');
  });

  test('rejects a malformed private listing response', () async {
    final adapter = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': [
          {'id': 'item-1'},
        ],
        'error': null,
      }),
    );
    final service = OwnedItemsService(Dio()..httpClientAdapter = adapter);

    await expectLater(
      service.fetchOwnedItems(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'INVALID_RESPONSE',
        ),
      ),
    );
  });

  test('lists, creates and removes owner unavailable periods', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      expect(options.path, startsWith('/items/item-1/unavailable-periods'));
      if (requestIndex == 1) {
        expect(options.method, 'GET');
        return jsonResponse({
          'success': true,
          'data': [unavailablePeriodJson()],
          'error': null,
        });
      }
      if (requestIndex == 2) {
        expect(options.method, 'POST');
        expect(options.data, {
          'startDate': '2026-08-01',
          'endDate': '2026-08-03',
        });
        return jsonResponse({
          'success': true,
          'data': unavailablePeriodJson(),
          'error': null,
        });
      }
      expect(options.method, 'DELETE');
      expect(options.path, '/items/item-1/unavailable-periods/period-1');
      return jsonResponse({'success': true, 'data': null, 'error': null});
    });
    final service = OwnedItemsService(Dio()..httpClientAdapter = adapter);

    final periods = await service.fetchUnavailablePeriods('item-1');
    final created = await service.createUnavailablePeriod(
      'item-1',
      const CreateUnavailablePeriodDraft(
        startDate: '2026-08-01',
        endDate: '2026-08-03',
      ),
    );
    await service.deleteUnavailablePeriod('item-1', 'period-1');

    expect(periods.single.id, 'period-1');
    expect(created.startDate, DateTime.utc(2026, 8));
    expect(adapter.requests, hasLength(3));
  });
}

Map<String, Object?> ownedItemJson() => {
  'id': 'item-1',
  'title': 'Перфоратор',
  'description': 'Рабочий перфоратор для домашних работ',
  'condition': 'GOOD',
  'completeness': 'Кейс и два бура',
  'handoverTerms': 'Проверить при передаче',
  'status': 'PENDING',
  'publicArea': 'Хамовники',
  'address': 'Москва, улица Примерная, 1',
  'latitude': 55.75,
  'longitude': 37.62,
  'pricePerDay': 450,
  'depositAmount': null,
  'category': {
    'id': 'category-1',
    'name': 'Инструменты',
    'slug': 'tools',
    'iconName': null,
    'safetyNotice': 'Используйте защитные очки',
  },
  'rejectReason': null,
  'photos': <Object?>[],
  'updatedAt': '2026-07-29T01:00:00.000Z',
};

Map<String, Object?> unavailablePeriodJson() => {
  'id': 'period-1',
  'itemId': 'item-1',
  'startDate': '2026-08-01T00:00:00.000Z',
  'endDate': '2026-08-03T00:00:00.000Z',
  'createdAt': '2026-07-29T01:00:00.000Z',
};
