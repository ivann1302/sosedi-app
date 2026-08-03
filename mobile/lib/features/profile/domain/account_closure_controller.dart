import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/profile_models.dart';
import '../data/profile_service.dart';

final accountClosureControllerProvider = NotifierProvider<
  AccountClosureController,
  AsyncValue<AccountClosureResult?>
>(AccountClosureController.new);

class AccountClosureController
    extends Notifier<AsyncValue<AccountClosureResult?>> {
  @override
  AsyncValue<AccountClosureResult?> build() => const AsyncData(null);

  Future<void> closeAccount() async {
    if (state.isLoading || state.value != null) {
      return;
    }

    state = const AsyncLoading();
    try {
      final result = await ref.read(profileServiceProvider).closeAccount();
      state = AsyncData(result);
    } catch (error, stackTrace) {
      final message = error is ApiException
          ? error.message
          : 'Не удалось отправить запрос';
      state = AsyncError(message, stackTrace);
    }
  }
}
