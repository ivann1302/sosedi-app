import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/identifiers/uuid_v4.dart';
import '../../../core/analytics/analytics.dart';
import '../data/create_item_models.dart';
import '../data/create_item_service.dart';

final createItemProvider =
    AsyncNotifierProvider.autoDispose<CreateItemController, CreateItemResult?>(
      CreateItemController.new,
      retry: (_, _) => null,
    );

class CreateItemController extends AsyncNotifier<CreateItemResult?> {
  List<XFile> _photos = const [];
  CreateItemDraft? _requestDraft;
  String? _requestId;
  ItemPhotoUploadProgress? _photoProgress;

  @override
  Future<CreateItemResult?> build() async => null;

  Future<void> submit(CreateItemDraft draft, List<XFile> photos) async {
    if (state.isLoading) {
      return;
    }
    if (_requestDraft != draft) {
      _requestDraft = draft;
      _requestId = generateUuidV4();
    }
    state = const AsyncLoading();
    final created = await AsyncValue.guard(
      () => ref
          .read(createItemServiceProvider)
          .create(draft, requestId: _requestId!),
    );
    if (created case AsyncData(:final value)) {
      unawaited(
        ref.read(analyticsServiceProvider).track(AnalyticsEvent.listingCreated),
      );
      _photos = photos;
      _photoProgress = ItemPhotoUploadProgress();
      state = AsyncData(value.copyWith(isUploadingPhotos: photos.isNotEmpty));
      if (photos.isNotEmpty) {
        await _uploadPhotos(value);
      }
      return;
    }
    state = created;
  }

  Future<void> retryPhotos() async {
    final current = state.value;
    if (current == null || _photos.isEmpty || current.isUploadingPhotos) {
      return;
    }
    state = AsyncData(
      current.copyWith(isUploadingPhotos: true, photoUploadFailed: false),
    );
    await _uploadPhotos(current);
  }

  Future<void> _uploadPhotos(CreateItemResult result) async {
    try {
      await ref
          .read(createItemServiceProvider)
          .uploadPhotos(result.id, _photos, progress: _photoProgress);
      state = AsyncData(
        result.copyWith(isUploadingPhotos: false, photoUploadFailed: false),
      );
    } catch (_) {
      state = AsyncData(
        result.copyWith(isUploadingPhotos: false, photoUploadFailed: true),
      );
    }
  }
}
