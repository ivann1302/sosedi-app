import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/safety/data/safety_models.dart';
import 'package:mobile/features/safety/data/safety_service.dart';
import 'package:mobile/features/safety/presentation/blocked_users_screen.dart';

void main() {
  testWidgets('lists and explicitly unblocks a user', (tester) async {
    final service = _FakeSafetyService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [safetyServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Анна'), findsOneWidget);
    await tester.tap(find.text('Разблокировать'));
    await tester.pumpAndSettle();
    expect(find.text('Разблокировать пользователя?'), findsOneWidget);
    expect(service.unblockCalls, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Разблокировать'),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.unblockCalls, 1);
    expect(find.text('Заблокированных пользователей нет'), findsOneWidget);
  });

  testWidgets('keeps the unblock action readable at compact 200% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.reset);
    final service = _FakeSafetyService(user: compactBlockedUser);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [safetyServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const BlockedUsersScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final name = find.text('Александр Петров');
    expect(tester.getSize(name).width, greaterThanOrEqualTo(120));
    final action = find.widgetWithText(TextButton, 'Разблокировать');
    expect(action.hitTestable(), findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Разблокировать пользователя?'), findsOneWidget);
    expect(service.unblockCalls, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Разблокировать'),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.unblockCalls, 1);
    expect(find.text('Заблокированных пользователей нет'), findsOneWidget);
  });
}

class _FakeSafetyService extends SafetyService {
  _FakeSafetyService({BlockedUser? user})
    : blockedUsers = [user ?? blockedUser],
      super(Dio());

  final List<BlockedUser> blockedUsers;
  var unblockCalls = 0;

  @override
  Future<List<BlockedUser>> listBlockedUsers() async => [...blockedUsers];

  @override
  Future<void> unblockUser(String userId) async {
    unblockCalls += 1;
    blockedUsers.removeWhere((value) => value.blocked.id == userId);
  }
}

final blockedUser = BlockedUser(
  id: 'block-1',
  blocked: const BlockedUserSummary(id: 'user-2', name: 'Анна'),
  createdAt: DateTime.utc(2026, 7, 30),
);

final compactBlockedUser = BlockedUser(
  id: 'block-compact',
  blocked: const BlockedUserSummary(
    id: 'user-compact',
    name: 'Александр Петров',
  ),
  createdAt: DateTime.utc(2026, 7, 30),
);
