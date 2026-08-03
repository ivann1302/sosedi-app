import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/create_item_service.dart';
import '../data/owned_item_models.dart';
import '../data/owned_items_service.dart';

final editItemProvider = AsyncNotifierProvider<EditItemController, OwnedItem?>(
  EditItemController.new,
  retry: (_, _) => null,
);

final editItemAvailabilityProvider =
    AsyncNotifierProvider<EditItemAvailabilityController, void>(
      EditItemAvailabilityController.new,
      retry: (_, _) => null,
    );

final editItemPhotoProvider =
    AsyncNotifierProvider<EditItemPhotoController, void>(
      EditItemPhotoController.new,
      retry: (_, _) => null,
    );

final hideOwnedItemProvider =
    AsyncNotifierProvider<HideOwnedItemController, void>(
      HideOwnedItemController.new,
      retry: (_, _) => null,
    );

class EditItemController extends AsyncNotifier<OwnedItem?> {
  @override
  Future<OwnedItem?> build() async => null;

  Future<void> submit(String id, UpdateItemDraft draft) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ownedItemsServiceProvider).updateItem(id, draft),
    );
    if (!state.hasError) {
      ref.invalidate(ownedItemsProvider);
    }
  }
}

class EditItemAvailabilityController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> add(String itemId, CreateUnavailablePeriodDraft draft) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(ownedItemsServiceProvider)
          .createUnavailablePeriod(itemId, draft);
    });
    if (!state.hasError) {
      ref.invalidate(unavailablePeriodsProvider(itemId));
    }
    return !state.hasError;
  }

  Future<bool> remove(String itemId, String periodId) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(ownedItemsServiceProvider)
          .deleteUnavailablePeriod(itemId, periodId),
    );
    if (!state.hasError) {
      ref.invalidate(unavailablePeriodsProvider(itemId));
    }
    return !state.hasError;
  }
}

class EditItemPhotoController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> append(
    String itemId,
    List<XFile> photos, {
    required int startSortOrder,
  }) async {
    if (state.isLoading || photos.isEmpty) {
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(createItemServiceProvider)
          .appendPhotos(itemId, photos, startSortOrder: startSortOrder),
    );
    if (!state.hasError) {
      ref.invalidate(ownedItemsProvider);
    }
    return !state.hasError;
  }
}

class HideOwnedItemController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> hide(String itemId) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ownedItemsServiceProvider).hideItem(itemId),
    );
    if (!state.hasError) {
      ref.invalidate(ownedItemsProvider);
    }
    return !state.hasError;
  }
}
