import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/profile/presentation/account_closure_screen.dart';

void main() {
  testWidgets('requires confirmation and shows the closure request status', (
    tester,
  ) async {
    final service = _FakeProfileService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: AccountClosureScreen()),
      ),
    );

    final submit = find.widgetWithText(FilledButton, 'Закрыть аккаунт');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(service.closeCalls, 1);
    expect(find.text('Запрос принят'), findsOneWidget);
    expect(find.textContaining('активных обязательств'), findsOneWidget);
  });
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService() : super(Dio());

  int closeCalls = 0;

  @override
  Future<AccountClosureResult> closeAccount() async {
    closeCalls += 1;
    return AccountClosureResult(
      status: 'PENDING_OBLIGATIONS',
      requestedAt: DateTime.utc(2026, 7, 29, 2),
      anonymizedAt: null,
    );
  }
}
