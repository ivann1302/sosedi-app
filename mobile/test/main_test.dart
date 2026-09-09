import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mobile/core/network/dio_provider.dart';
import 'package:mobile/core/storage/onboarding_storage.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('uses Russian form validation messages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _LifecycleAuthController()),
          apiCompatibilityCheckProvider.overrideWith((ref) async {}),
          onboardingCompletedProvider.overrideWith(
            () => _CompletedOnboardingController(),
          ),
        ],
        child: const SosediApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      FormBuilderValidators.minLength(3)('a'),
      'Длина значения должна быть больше или равна 3.',
    );
  });

  testWidgets('revalidates an authenticated session when the app resumes', (
    tester,
  ) async {
    final controller = _LifecycleAuthController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => controller),
          apiCompatibilityCheckProvider.overrideWith((ref) async {}),
          onboardingCompletedProvider.overrideWith(
            () => _CompletedOnboardingController(),
          ),
        ],
        child: const SosediApp(),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(controller.resumeValidations, 1);
  });
}

class _LifecycleAuthController extends AuthController {
  var resumeValidations = 0;

  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'user-1',
      phone: '+79991234567',
      role: 'USER',
      isBlocked: false,
    ),
  );

  @override
  Future<void> validateSessionOnResume() async {
    resumeValidations += 1;
  }
}

class _CompletedOnboardingController extends OnboardingController {
  @override
  bool build() => true;
}
