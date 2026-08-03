import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/support_models.dart';
import '../data/support_service.dart';

final supportCreateProvider =
    AsyncNotifierProvider<SupportCreateController, SupportTicket?>(
      SupportCreateController.new,
      retry: (_, _) => null,
    );

class SupportCreateController extends AsyncNotifier<SupportTicket?> {
  @override
  Future<SupportTicket?> build() async => null;

  Future<bool> submit(CreateSupportTicketDraft draft) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(supportServiceProvider).create(draft),
    );
    if (!state.hasError) {
      ref.invalidate(supportTicketsProvider);
    }
    return !state.hasError;
  }
}
