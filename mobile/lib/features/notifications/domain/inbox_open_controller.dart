import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/inbox_event.dart';
import '../data/inbox_service.dart';
import 'inbox_controller.dart';

final inboxOpenProvider = AsyncNotifierProvider<InboxOpenController, String?>(
  InboxOpenController.new,
  retry: (_, _) => null,
);

class InboxOpenController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> open(InboxEvent event) async {
    if (state.isLoading) {
      return null;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(inboxServiceProvider);
      if (event.readAt == null) {
        await service.markRead(event.eventId);
      }
      final path = await service.resolveNavigationPath(event.eventId);
      ref.invalidate(inboxEventsProvider);
      ref.invalidate(inboxControllerProvider);
      return path;
    });
    return state.value;
  }
}
