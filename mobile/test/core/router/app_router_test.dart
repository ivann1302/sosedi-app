import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/compatibility/compatibility_gate.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/storage/onboarding_storage.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';

void main() {
  const user = AuthUser(
    id: 'user-1',
    phone: '+79991234567',
    role: 'USER',
    isBlocked: false,
  );

  final cases =
      <
        ({
          String description,
          AuthState authState,
          bool onboardingCompleted,
          String location,
          String? expected,
        })
      >[
        (
          description: 'requires onboarding before auth state is considered',
          authState: const AuthState.loading(),
          onboardingCompleted: false,
          location: '/',
          expected: '/onboarding',
        ),
        (
          description: 'allows the onboarding screen on first launch',
          authState: const AuthState.authenticated(user: user),
          onboardingCompleted: false,
          location: '/onboarding',
          expected: null,
        ),
        (
          description: 'sends any other first-launch route to onboarding',
          authState: const AuthState.unauthenticated(),
          onboardingCompleted: false,
          location: '/catalog',
          expected: '/onboarding',
        ),
        (
          description:
              'keeps the splash route while session restore is loading',
          authState: const AuthState.loading(),
          onboardingCompleted: true,
          location: '/',
          expected: null,
        ),
        (
          description: 'sends protected routes to splash while loading',
          authState: const AuthState.loading(),
          onboardingCompleted: true,
          location: '/home',
          expected: '/',
        ),
        (
          description: 'sends authenticated root to home',
          authState: const AuthState.authenticated(user: user),
          onboardingCompleted: true,
          location: '/',
          expected: '/home',
        ),
        (
          description: 'sends authenticated onboarding to home',
          authState: const AuthState.authenticated(user: user),
          onboardingCompleted: true,
          location: '/onboarding',
          expected: '/home',
        ),
        (
          description: 'sends authenticated auth routes to home',
          authState: const AuthState.authenticated(user: user),
          onboardingCompleted: true,
          location: '/auth/otp',
          expected: '/home',
        ),
        (
          description: 'allows authenticated protected routes',
          authState: const AuthState.authenticated(user: user),
          onboardingCompleted: true,
          location: '/catalog',
          expected: null,
        ),
        (
          description: 'allows unauthenticated phone route',
          authState: const AuthState.unauthenticated(),
          onboardingCompleted: true,
          location: '/auth/phone',
          expected: null,
        ),
        (
          description: 'rejects OTP route before a code is sent',
          authState: const AuthState.unauthenticated(),
          onboardingCompleted: true,
          location: '/auth/otp',
          expected: '/auth/phone',
        ),
        (
          description: 'allows OTP route after a code is sent',
          authState: const AuthState.codeSent(
            phone: '+79991234567',
            expiresInSeconds: 300,
          ),
          onboardingCompleted: true,
          location: '/auth/otp',
          expected: null,
        ),
        (
          description: 'allows phone route after a code is sent',
          authState: const AuthState.codeSent(
            phone: '+79991234567',
            expiresInSeconds: 300,
          ),
          onboardingCompleted: true,
          location: '/auth/phone',
          expected: null,
        ),
        (
          description: 'protects home from unauthenticated users',
          authState: const AuthState.unauthenticated(),
          onboardingCompleted: true,
          location: '/home',
          expected: '/auth/phone',
        ),
        (
          description: 'protects future routes from unauthenticated users',
          authState: const AuthState.unauthenticated(),
          onboardingCompleted: true,
          location: '/booking/booking-1',
          expected: '/auth/phone',
        ),
      ];

  for (final testCase in cases) {
    test(testCase.description, () {
      expect(
        appRedirect(
          testCase.authState,
          testCase.onboardingCompleted,
          testCase.location,
        ),
        testCase.expected,
      );
    });
  }

  test('forces the update route before onboarding or authentication', () {
    const requirement = UpdateRequirement(
      code: 'MOBILE_UPDATE_REQUIRED',
      message: 'Требуется обновление',
      minimumVersion: '2.0.0',
    );

    expect(
      appRedirect(
        const AuthState.unauthenticated(),
        false,
        '/onboarding',
        updateRequirement: requirement,
      ),
      '/update-required',
    );
    expect(
      appRedirect(
        const AuthState.authenticated(user: user),
        true,
        '/update-required',
        updateRequirement: requirement,
      ),
      isNull,
    );
  });

  test('keeps one router instance across auth and onboarding updates', () {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => _TestAuthController(const AuthState.loading()),
        ),
        onboardingCompletedProvider.overrideWith(
          () => _TestOnboardingController(true),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    final authController =
        container.read(authControllerProvider.notifier) as _TestAuthController;
    authController.setAuthState(const AuthState.unauthenticated());

    expect(identical(container.read(appRouterProvider), router), isTrue);

    final onboardingController =
        container.read(onboardingCompletedProvider.notifier)
            as _TestOnboardingController;
    onboardingController.setCompleted(false);

    expect(identical(container.read(appRouterProvider), router), isTrue);
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  void setAuthState(AuthState value) {
    state = value;
  }
}

class _TestOnboardingController extends OnboardingController {
  _TestOnboardingController(this._initialState);

  final bool _initialState;

  @override
  bool build() => _initialState;

  void setCompleted(bool value) {
    state = value;
  }
}
