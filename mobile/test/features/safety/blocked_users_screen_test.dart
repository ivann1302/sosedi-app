import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

class _FakeSafetyService extends SafetyService {
  _FakeSafetyService() : super(Dio());

  final blockedUsers = <BlockedUser>[blockedUser];
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
