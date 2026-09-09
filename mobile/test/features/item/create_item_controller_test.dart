import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/item/data/create_item_models.dart';
import 'package:mobile/features/item/data/create_item_service.dart';
import 'package:mobile/features/item/domain/create_item_controller.dart';

import 'create_item_service_test.dart';
import '../../support/network_fakes.dart';

void main() {
  for (final expired in [false, true]) {
    test(
      expired
          ? 'restarts only an expired photo intent'
          : 'resumes a photo batch after a lost confirmation without duplicates',
      () async {
        var presigns = 0;
        var uploads = 0;
        var loseConfirmation = true;
        final confirmed = <String>{};
        final adapter = CallbackAdapter((options) {
          if (options.path == '/items') {
            return jsonResponse({
              'success': true,
              'data': {'id': 'item-1', 'status': 'PENDING'},
              'error': null,
            });
          }
          if (options.path == '/uploads/presigned-url') {
            presigns += 1;
            return jsonResponse({
              'success': true,
              'data': {
                'intentId': 'intent-$presigns',
                'uploadUrl': 'https://upload.test/item',
                'fields': {'key': 'photo-$presigns'},
              },
              'error': null,
            });
          }
          if (options.uri.host == 'upload.test') {
            uploads += 1;
            return ResponseBody.fromString('', 204);
          }
          if (options.path == '/uploads/item-photos/confirm') {
            final data = options.data as Map<String, dynamic>;
            if (expired && data['intentId'] == 'intent-2') {
              return jsonResponse({
                'success': false,
                'data': null,
                'error': {
                  'code': 'VALIDATION_ERROR',
                  'message': 'Upload intent истёк',
                },
              }, statusCode: 400);
            }
            confirmed.add(data['intentId'] as String);
            if (!expired && data['sortOrder'] == 1 && loseConfirmation) {
              loseConfirmation = false;
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              );
            }
            return jsonResponse({
              'success': true,
              'data': {'id': data['intentId'], 'itemId': 'item-1'},
              'error': null,
            });
          }
          throw StateError('Unexpected request ${options.path}');
        });
        final container = ProviderContainer(
          overrides: [
            createItemServiceProvider.overrideWithValue(
              CreateItemService(Dio()..httpClientAdapter = adapter),
            ),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(createItemProvider, (_, _) {});
        addTearDown(subscription.close);
        await container.read(createItemProvider.future);
        final controller = container.read(createItemProvider.notifier);
        await controller.submit(draft, [
          for (var i = 0; i < 2; i++)
            XFile.fromData(
              Uint8List.fromList([1, 2, 3]),
              name: 'photo-$i.jpg',
              mimeType: 'image/jpeg',
            ),
        ]);
        expect(
          container.read(createItemProvider).value?.photoUploadFailed,
          isTrue,
        );
        await controller.retryPhotos();
        expect(
          container.read(createItemProvider).value?.photoUploadFailed,
          isFalse,
        );
        expect(
          confirmed,
          expired ? {'intent-1', 'intent-3'} : {'intent-1', 'intent-2'},
        );
        expect(presigns, expired ? 3 : 2);
        expect(uploads, expired ? 3 : 2);
      },
    );
  }

  test('retries photos on the same created item without a duplicate', () async {
    final service = _RetryPhotoService();
    final container = ProviderContainer(
      overrides: [createItemServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      createItemProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final photo = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'photo.jpg',
      mimeType: 'image/jpeg',
    );

    await container.read(createItemProvider.future);
    await container.read(createItemProvider.notifier).submit(draft, [photo]);

    expect(service.createCalls, 1);
    expect(service.requestIds.single, isNotEmpty);
    expect(service.uploadCalls, 1);
    expect(container.read(createItemProvider).value?.photoUploadFailed, isTrue);

    await container.read(createItemProvider.notifier).retryPhotos();

    expect(service.createCalls, 1);
    expect(service.uploadCalls, 2);
    expect(
      container.read(createItemProvider).value?.photoUploadFailed,
      isFalse,
    );
  });

  test('reuses the request ID only while retrying the same draft', () async {
    final service = _RetryPhotoService(failFirstCreate: true);
    final container = ProviderContainer(
      overrides: [createItemServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      createItemProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(createItemProvider.future);
    final controller = container.read(createItemProvider.notifier);

    await controller.submit(draft, const []);
    await controller.submit(draft, const []);
    await controller.submit(draft.copyWith(title: 'Другой проектор'), const []);

    expect(service.requestIds[0], service.requestIds[1]);
    expect(service.requestIds[2], isNot(service.requestIds[1]));
  });
}

class _RetryPhotoService extends CreateItemService {
  _RetryPhotoService({this.failFirstCreate = false}) : super(Dio());

  final bool failFirstCreate;
  int createCalls = 0;
  int uploadCalls = 0;
  final requestIds = <String>[];

  @override
  Future<CreateItemResult> create(
    CreateItemDraft draft, {
    required String requestId,
  }) async {
    createCalls += 1;
    requestIds.add(requestId);
    if (failFirstCreate && createCalls == 1) {
      throw Exception('offline');
    }
    return const CreateItemResult(id: 'item-1', status: 'PENDING');
  }

  @override
  Future<void> uploadPhotos(
    String itemId,
    List<XFile> photos, {
    ItemPhotoUploadProgress? progress,
  }) async {
    uploadCalls += 1;
    if (uploadCalls == 1) {
      throw Exception('offline');
    }
  }
}
