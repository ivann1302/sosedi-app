import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/core/network/dio_provider.dart';
import 'package:mobile/core/storage/onboarding_storage.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('browses as a guest and resumes a private tab after OTP', (
    tester,
  ) async {
    final auth = _SmokeAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          onboardingCompletedProvider.overrideWith(
            _SmokeOnboardingController.new,
          ),
          apiCompatibilityCheckProvider.overrideWith((ref) async {}),
        ],
        child: const SosediApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Всё нужное уже рядом'), findsOneWidget);
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Смотреть вещи'));
    await tester.pumpAndSettle();

    expect(find.text('Найти'), findsOneWidget);
    expect(find.text('Брони'), findsOneWidget);
    expect(find.text('Сдать'), findsOneWidget);
    expect(find.text('Входящие'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();

    expect(find.text('Рады видеть вас'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '+7 999 123 45 67');
    await tester.tap(find.text('Получить код'));
    await tester.pumpAndSettle();

    expect(find.text('Введите код'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Найти'), findsOneWidget);
    expect(find.text('Брони'), findsOneWidget);
    expect(find.text('Сдать'), findsOneWidget);
    expect(find.text('Входящие'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
    expect(auth.requestOtpCalls, 1);
    expect(auth.verifyOtpCalls, 1);
  });
}

class _SmokeOnboardingController extends OnboardingController {
  @override
  bool build() => false;

  @override
  Future<void> markCompleted() async {
    state = true;
  }
}

class _SmokeAuthController extends AuthController {
  var requestOtpCalls = 0;
  var verifyOtpCalls = 0;

  @override
  AuthState build() => const AuthState.unauthenticated();

  @override
  Future<bool> requestOtp(String rawPhone) async {
    requestOtpCalls += 1;
    state = const AuthState.codeSent(
      phone: '+79991234567',
      expiresInSeconds: 300,
    );
    return true;
  }

  @override
  Future<bool> verifyOtp(String code) async {
    verifyOtpCalls += 1;
    state = const AuthState.authenticated(
      user: AuthUser(
        id: '11111111-1111-4111-8111-111111111111',
        phone: '+79991234567',
        role: 'USER',
        isBlocked: false,
      ),
    );
    return true;
  }
}
