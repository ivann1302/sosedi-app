import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/profile_models.dart';
import '../data/profile_service.dart';

final dataExportControllerProvider =
    AsyncNotifierProvider.autoDispose<DataExportController, UserDataExport?>(
      DataExportController.new,
      retry: (_, _) => null,
    );

class DataExportController extends AsyncNotifier<UserDataExport?> {
  @override
  Future<UserDataExport?> build() async => null;

  Future<bool> requestOtp() async {
    if (state.isLoading) {
      return false;
    }

    state = const AsyncLoading();
    try {
      await ref.read(profileServiceProvider).requestDataExportOtp();
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(_message(error), stackTrace);
      return false;
    }
  }

  Future<void> create(String code) async {
    if (state.isLoading || state.value != null) {
      return;
    }

    state = const AsyncLoading();
    try {
      final service = ref.read(profileServiceProvider);
      final stepUp = await service.verifyDataExportOtp(code);
      final export = await service.createDataExport(stepUp.stepUpToken);
      state = AsyncData(export);
    } catch (error, stackTrace) {
      state = AsyncError(_message(error), stackTrace);
    }
  }

  String _message(Object error) {
    return error is ApiException
        ? error.message
        : 'Не удалось подготовить экспорт';
  }
}
