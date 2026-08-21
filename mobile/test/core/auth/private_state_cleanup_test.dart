import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/auth/private_state_cleanup.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/item/data/create_item_draft_storage.dart';
import 'package:mobile/features/notifications/data/inbox_event.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/profile/domain/data_export_controller.dart';
import 'package:mobile/features/profile/domain/session_controller.dart';
import 'package:mobile/features/support/data/support_models.dart';
import 'package:mobile/features/support/data/support_service.dart';

void main() {
  test(
    'invalidates private provider state before leaving authentication',
    () async {
      final auth = _TestAuthController();
      var sessionBuilds = 0;
      var inboxBuilds = 0;
      var supportBuilds = 0;
      final profileService = _TestProfileService();
      final draftStorage = _TestDraftStorage();
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          profileServiceProvider.overrideWithValue(profileService),
          createItemDraftStorageProvider.overrideWithValue(draftStorage),
          sessionsProvider.overrideWith((ref) async {
            sessionBuilds += 1;
            return const [];
          }),
          inboxEventsProvider.overrideWith((ref) async {
            inboxBuilds += 1;
            return const <InboxEvent>[];
          }),
          supportTicketsProvider.overrideWith((ref) async {
            supportBuilds += 1;
            return const <SupportTicket>[];
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(privateStateCleanupProvider);
      final subscription = container.listen(
        sessionsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final inboxSubscription = container.listen(
        inboxEventsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(inboxSubscription.close);
      final supportSubscription = container.listen(
        supportTicketsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(supportSubscription.close);
      final exportSubscription = container.listen(
        dataExportControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(exportSubscription.close);
      await Future.wait([
        container.read(sessionsProvider.future),
        container.read(inboxEventsProvider.future),
        container.read(supportTicketsProvider.future),
        container.read(dataExportControllerProvider.future),
      ]);
      await container
          .read(dataExportControllerProvider.notifier)
          .create('123456');
      expect(
        container.read(dataExportControllerProvider).value?.profile['id'],
        'user-1',
      );

      auth.setLoading();
      await Future<void>.delayed(Duration.zero);
      await Future.wait([
        container.read(sessionsProvider.future),
        container.read(inboxEventsProvider.future),
        container.read(supportTicketsProvider.future),
      ]);
      expect(await container.read(dataExportControllerProvider.future), isNull);

      expect(sessionBuilds, 2);
      expect(inboxBuilds, 2);
      expect(supportBuilds, 2);
      expect(draftStorage.clearCalls, 1);
    },
  );
}

class _TestDraftStorage extends CreateItemDraftStorage {
  var clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls += 1;
  }
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'user-1',
      phone: '+79991234567',
      role: 'USER',
      isBlocked: false,
    ),
  );

  void setLoading() {
    state = const AuthState.loading();
  }
}

class _TestProfileService extends ProfileService {
  _TestProfileService() : super(Dio());

  @override
  Future<UserStepUpResult> verifyDataExportOtp(String code) async {
    return const UserStepUpResult(
      stepUpToken: 'step-up-token',
      expiresInSeconds: 300,
    );
  }

  @override
  Future<UserDataExport> createDataExport(String stepUpToken) async {
    return UserDataExport(
      schemaVersion: '2026-07-30.1',
      generatedAt: DateTime.utc(2026, 7, 30, 2),
      retentionPolicyVersion: 'ADR-0002/2026-07-27',
      profile: const {'id': 'user-1'},
      listings: const [],
      bookings: const [],
      inbox: const [],
      support: const [],
      reports: const [],
      blocks: const [],
      documentAcceptances: const [],
      financialHistory: const [],
      fileManifest: const [],
      processing: const {'categories': <Object?>[], 'excluded': <Object?>[]},
    );
  }
}
