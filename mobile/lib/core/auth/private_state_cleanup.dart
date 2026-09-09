import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_controller.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/booking/data/booking_service.dart';
import '../../features/booking/domain/booking_action_controller.dart';
import '../../features/booking/domain/booking_availability_controller.dart';
import '../../features/favorites/domain/favorite_controller.dart';
import '../../features/item/data/owned_items_service.dart';
import '../../features/item/data/create_item_draft_storage.dart';
import '../../features/item/domain/create_item_controller.dart';
import '../../features/item/domain/edit_item_controller.dart';
import '../../features/notifications/data/inbox_service.dart';
import '../../features/notifications/domain/inbox_open_controller.dart';
import '../../features/notifications/domain/inbox_controller.dart';
import '../../features/notifications/domain/notification_navigation_controller.dart';
import '../../features/profile/data/profile_service.dart';
import '../../features/profile/domain/account_closure_controller.dart';
import '../../features/profile/domain/data_export_controller.dart';
import '../../features/profile/domain/profile_editor_controller.dart';
import '../../features/profile/domain/session_controller.dart';
import '../../features/safety/data/safety_service.dart';
import '../../features/safety/domain/safety_action_controller.dart';
import '../../features/support/data/support_service.dart';
import '../../features/support/domain/support_create_controller.dart';
import '../../features/support/domain/support_message_create_controller.dart';

final privateStateCleanupProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    final leavingAccount =
        previous is AuthAuthenticated &&
        (next is! AuthAuthenticated || previous.user.id != next.user.id);
    final enteringAccount =
        next is AuthAuthenticated &&
        (previous is! AuthAuthenticated || previous.user.id != next.user.id);
    if (leavingAccount) {
      unawaited(ref.read(createItemDraftStorageProvider).clear());
    }
    if (leavingAccount || enteringAccount) {
      ref.invalidate(profileProvider);
      ref.invalidate(sessionsProvider);
      ref.invalidate(ownedItemsProvider);
      ref.invalidate(favoriteItemsProvider);
      ref.invalidate(unavailablePeriodsProvider);
      ref.invalidate(myBookingsProvider);
      ref.invalidate(bookingDetailsProvider);
      ref.invalidate(bookingActsProvider);
      ref.invalidate(createItemProvider);
      ref.invalidate(editItemProvider);
      ref.invalidate(editItemAvailabilityProvider);
      ref.invalidate(editItemPhotoProvider);
      ref.invalidate(hideOwnedItemProvider);
      ref.invalidate(bookingActionProvider);
      ref.invalidate(bookingAvailabilityProvider);
      ref.invalidate(inboxEventsProvider);
      ref.invalidate(inboxControllerProvider);
      ref.invalidate(inboxOpenProvider);
      ref.invalidate(supportTicketsProvider);
      ref.invalidate(supportTicketProvider);
      ref.invalidate(supportMessagesProvider);
      ref.invalidate(supportCreateProvider);
      ref.invalidate(supportMessageCreateProvider);
      ref.invalidate(blockedUsersProvider);
      ref.invalidate(safetyActionProvider);
      ref.invalidate(accountClosureControllerProvider);
      ref.invalidate(dataExportControllerProvider);
      ref.invalidate(profileEditorControllerProvider);
      ref.invalidate(sessionControllerProvider);
      ref.invalidate(notificationNavigationProvider);
    }
  });
});
