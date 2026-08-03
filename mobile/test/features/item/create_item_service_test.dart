import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/item/data/create_item_models.dart';
import 'package:mobile/features/item/data/create_item_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test(
    'submits the neutral item contract and reads moderation status',
    () async {
      final adapter = CallbackAdapter((options) {
        expect(options.method, 'POST');
        expect(options.path, '/items');
        expect(options.data, draft.toJson());
        expect(
          options.headers['X-Request-Id'],
          '11111111-1111-4111-8111-111111111111',
        );
        return jsonResponse({
          'success': true,
          'data': {...draft.toJson(), 'id': 'item-1', 'status': 'PENDING'},
          'error': null,
        });
      });
      final service = CreateItemService(Dio()..httpClientAdapter = adapter);

      final result = await service.create(
        draft,
        requestId: '11111111-1111-4111-8111-111111111111',
      );

      expect(result.id, 'item-1');
      expect(result.status, 'PENDING');
    },
  );

  test('uploads an item photo through presign and confirm', () async {
    final adapter = CallbackAdapter((options) {
      if (options.path == '/uploads/presigned-url') {
        expect(options.data, {
          'purpose': 'ITEM_PHOTO',
          'itemId': 'item-1',
          'fileName': 'item-0.jpg',
          'contentType': 'image/jpeg',
          'sizeBytes': 4,
        });
        return jsonResponse({
          'success': true,
          'data': {
            'intentId': 'intent-1',
            'uploadUrl': 'https://upload.test/item',
            'fields': {'key': 'quarantine/item/photo.jpg'},
          },
          'error': null,
        });
      }
      if (options.uri.host == 'upload.test') {
        expect(options.data, isA<FormData>());
        return ResponseBody.fromString('', 204);
      }
      if (options.path == '/uploads/item-photos/confirm') {
        expect(options.data, {
          'intentId': 'intent-1',
          'sortOrder': 0,
          'isCover': true,
        });
        return jsonResponse({
          'success': true,
          'data': {'id': 'photo-1', 'itemId': 'item-1'},
          'error': null,
        });
      }
      throw StateError('Unexpected request ${options.path}');
    });
    final service = CreateItemService(Dio()..httpClientAdapter = adapter);
    final photo = XFile.fromData(
      Uint8List.fromList([1, 2, 3, 4]),
      name: 'photo.jpg',
      mimeType: 'image/jpeg',
    );

    try {
      await service.uploadPhotos('item-1', [photo]);
    } catch (error) {
      fail(
        '$error; requests: '
        '${adapter.requests.map((request) => '${request.method} ${request.uri} ${request.data}')}',
      );
    }

    expect(adapter.requests, hasLength(3));
  });

  test('appends a photo without replacing an existing cover', () async {
    final adapter = CallbackAdapter((options) {
      if (options.path == '/uploads/presigned-url') {
        return jsonResponse({
          'success': true,
          'data': {
            'intentId': 'intent-2',
            'uploadUrl': 'https://upload.test/item',
            'fields': {'key': 'quarantine/item/appended.jpg'},
          },
          'error': null,
        });
      }
      if (options.uri.host == 'upload.test') {
        return ResponseBody.fromString('', 204);
      }
      if (options.path == '/uploads/item-photos/confirm') {
        expect(options.data, {
          'intentId': 'intent-2',
          'sortOrder': 3,
          'isCover': false,
        });
        return jsonResponse({
          'success': true,
          'data': {'id': 'photo-2', 'itemId': 'item-1'},
          'error': null,
        });
      }
      throw StateError('Unexpected request ${options.path}');
    });
    final service = CreateItemService(Dio()..httpClientAdapter = adapter);
    final photo = XFile.fromData(
      Uint8List.fromList([1, 2, 3, 4]),
      name: 'appended.jpg',
      mimeType: 'image/jpeg',
    );

    await service.appendPhotos('item-1', [photo], startSortOrder: 3);

    expect(adapter.requests, hasLength(3));
  });
}

const draft = CreateItemDraft(
  categoryId: '22222222-2222-4222-8222-222222222222',
  title: 'Перфоратор',
  description: 'Рабочий перфоратор для домашних работ',
  condition: 'GOOD',
  completeness: 'Кейс и два бура',
  handoverTerms: 'Проверить при передаче',
  pricePerDay: 450,
  publicArea: 'Хамовники',
  address: 'Москва, улица Примерная, 1',
  latitude: 55.75,
  longitude: 37.62,
  ownershipConfirmed: true,
  conditionConfirmed: true,
  completenessConfirmed: true,
  safetyAndMarketplaceRulesAccepted: true,
  listingRulesVersion: '2026-07-28',
);
