import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/support_models.dart';
import '../data/support_service.dart';

final supportMessageCreateProvider =
    AsyncNotifierProvider<SupportMessageCreateController, SupportMessage?>(
      SupportMessageCreateController.new,
      retry: (_, _) => null,
    );

class SupportMessageCreateController extends AsyncNotifier<SupportMessage?> {
  @override
  Future<SupportMessage?> build() async => null;

  Future<bool> submit({
    required String ticketId,
    required String body,
    List<XFile> attachments = const [],
  }) async {
    if (state.isLoading) {
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(supportServiceProvider)
          .createMessage(ticketId, body, attachments: attachments),
    );
    if (!state.hasError) {
      ref.invalidate(supportMessagesProvider(ticketId));
      ref.invalidate(supportTicketsProvider);
    }
    return !state.hasError;
  }
}
