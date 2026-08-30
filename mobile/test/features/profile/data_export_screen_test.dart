import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/profile/presentation/data_export_screen.dart';

void main() {
  testWidgets(
    'requires a fresh SMS code and renders the in-memory JSON export',
    (tester) async {
      final service = _FakeProfileService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileServiceProvider.overrideWithValue(service)],
          child: const MaterialApp(home: DataExportScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('data-export-code-field')),
        findsNothing,
      );

      await tester.tap(find.text('Получить код'));
      await tester.pumpAndSettle();

      expect(service.requestCalls, 1);
      expect(
        find.byKey(const ValueKey('data-export-code-field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('data-export-code-field')),
        '123456',
      );
      await tester.tap(find.text('Подготовить экспорт'));
      await tester.pumpAndSettle();

      expect(service.verifiedCode, '123456');
      expect(service.exportToken, 'step-up-token');
      expect(find.text('Экспорт готов'), findsOneWidget);
      expect(find.textContaining('2026-08-30.1'), findsWidgets);
      expect(find.textContaining('+79991234567'), findsOneWidget);
      expect(find.byKey(const ValueKey('data-export-json')), findsOneWidget);
    },
  );

  testWidgets('opens the assisted export fallback when SMS is unavailable', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/profile/data-export',
      routes: [
        GoRoute(
          path: '/profile/data-export',
          builder: (_, _) => const DataExportScreen(),
        ),
        GoRoute(
          path: '/support/export',
          builder: (_, _) => const Scaffold(body: Text('Поддержка экспорта')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileServiceProvider.overrideWithValue(_FakeProfileService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Обратиться в поддержку'));
    await tester.pumpAndSettle();

    expect(find.text('Поддержка экспорта'), findsOneWidget);
  });
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService() : super(Dio());

  int requestCalls = 0;
  String? verifiedCode;
  String? exportToken;

  @override
  Future<OtpRequestResult> requestDataExportOtp() async {
    requestCalls += 1;
    return const OtpRequestResult(phone: '+79991234567', expiresInSeconds: 600);
  }

  @override
  Future<UserStepUpResult> verifyDataExportOtp(String code) async {
    verifiedCode = code;
    return const UserStepUpResult(
      stepUpToken: 'step-up-token',
      expiresInSeconds: 300,
    );
  }

  @override
  Future<UserDataExport> createDataExport(String stepUpToken) async {
    exportToken = stepUpToken;
    return UserDataExport(
      schemaVersion: '2026-08-30.1',
      generatedAt: DateTime.utc(2026, 7, 30, 2),
      retentionPolicyVersion: 'ADR-0002/2026-07-27',
      profile: const {'id': 'user-1', 'phone': '+79991234567', 'name': 'Анна'},
      listings: const [],
      bookings: const [],
      inbox: const [],
      support: const [],
      reports: const [],
      blocks: const [],
      favorites: const [],
      documentAcceptances: const [],
      financialHistory: const [],
      fileManifest: const [],
      processing: const {'categories': <Object?>[], 'excluded': <Object?>[]},
    );
  }
}
