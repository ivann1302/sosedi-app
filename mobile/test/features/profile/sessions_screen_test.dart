import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/features/profile/domain/session_controller.dart';
import 'package:mobile/features/profile/presentation/sessions_screen.dart';

import '../../support/network_fakes.dart';

void main() {
  testWidgets('shows current and other sessions and revokes the selected one', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(service),
          sessionsProvider.overrideWith((ref) async => sessions),
        ],
        child: const MaterialApp(home: SessionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Это устройство'), findsOneWidget);
    expect(find.text('Другое устройство'), findsOneWidget);
    await tester.tap(find.byTooltip('Завершить сессию'));
    await tester.pumpAndSettle();

    expect(service.revokedSessionId, sessions.last.sessionId);
  });

  test('shows a safe error when session revocation fails', () async {
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(_FailingAuthService())],
    );
    addTearDown(container.dispose);

    await container
        .read(sessionControllerProvider.notifier)
        .revoke('33333333-3333-4333-8333-333333333333');

    expect(container.read(sessionControllerProvider), isA<AsyncError<void>>());
    expect(
      container.read(sessionControllerProvider).error,
      'Не удалось завершить выбранную сессию',
    );
  });
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio(), MemoryTokenStorage());

  String? revokedSessionId;

  @override
  Future<void> revokeSession(String sessionId) async {
    revokedSessionId = sessionId;
  }
}

class _FailingAuthService extends AuthService {
  _FailingAuthService() : super(Dio(), MemoryTokenStorage());

  @override
  Future<void> revokeSession(String sessionId) {
    throw const ApiException(
      code: 'SESSION_REVOKE_FAILED',
      message: 'Не удалось завершить выбранную сессию',
    );
  }
}

final sessions = [
  UserSession(
    sessionId: '11111111-1111-4111-8111-111111111111',
    installationId: '22222222-2222-4222-8222-222222222222',
    createdAt: DateTime.utc(2026, 7, 29),
    lastSeenAt: DateTime.utc(2026, 7, 29, 1),
    isCurrent: true,
  ),
  UserSession(
    sessionId: '33333333-3333-4333-8333-333333333333',
    installationId: '44444444-4444-4444-8444-444444444444',
    createdAt: DateTime.utc(2026, 7, 28),
    lastSeenAt: DateTime.utc(2026, 7, 28, 23),
    isCurrent: false,
  ),
];
