import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../data/profile_service.dart';

final profileEditorControllerProvider =
    NotifierProvider<ProfileEditorController, AsyncValue<void>>(
      ProfileEditorController.new,
    );

class ProfileEditorController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> updateProfile({
    required String name,
    required String city,
  }) {
    return _run(
      () => ref
          .read(profileServiceProvider)
          .updateProfile(name: name, city: city),
    );
  }

  Future<bool> replaceAvatar(XFile file) {
    return _run(() => ref.read(profileServiceProvider).replaceAvatar(file));
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    if (state.isLoading) {
      return false;
    }

    state = const AsyncLoading();
    try {
      await action();
      ref.invalidate(profileProvider);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      final message = error is ApiException
          ? error.message
          : 'Не удалось сохранить изменения';
      state = AsyncError(message, stackTrace);
      return false;
    }
  }
}
