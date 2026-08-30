import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/otp_screen.dart';
import 'package:mobile/features/auth/presentation/phone_screen.dart';

void main() {
  testWidgets('keeps guest browsing separate from unpublished rules', (
    tester,
  ) async {
    final controller = _ScreenAuthController(const AuthState.unauthenticated());
    await _pumpScreen(tester, controller, const PhoneScreen());

    expect(
      find.textContaining('Смотреть каталог можно без входа'),
      findsOneWidget,
    );
    expect(find.textContaining('согласие с правилами'), findsNothing);
  });

  testWidgets('does not request OTP for an invalid phone', (tester) async {
    final controller = _ScreenAuthController(const AuthState.unauthenticated());
    await _pumpScreen(tester, controller, const PhoneScreen());

    await tester.enterText(find.byType(EditableText), '123');
    await tester.tap(find.text('Получить код'));
    await tester.pump();

    expect(controller.requestOtpCalls, 0);
    expect(find.text('Введите телефон в формате +7XXXXXXXXXX'), findsOneWidget);
  });

  testWidgets('disables the phone submit button while sending', (tester) async {
    final controller = _ScreenAuthController(
      const AuthState.unauthenticated(isSubmitting: true),
    );
    await _pumpScreen(tester, controller, const PhoneScreen());

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Получить код'),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('shows an OTP request error and enables the form again', (
    tester,
  ) async {
    final controller = _ScreenAuthController(
      const AuthState.unauthenticated(),
      requestOtpResult: false,
    );
    await _pumpScreen(tester, controller, const PhoneScreen());

    await tester.enterText(find.byType(EditableText), '+7 999 123 45 67');
    await tester.tap(find.text('Получить код'));
    await tester.pump();

    expect(controller.requestOtpCalls, 1);
    expect(find.text('Слишком много попыток'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Получить код'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('does not verify an invalid OTP', (tester) async {
    final controller = _ScreenAuthController(codeSentState);
    await _pumpScreen(tester, controller, const OtpScreen());

    await tester.enterText(find.byType(EditableText), '123');
    await tester.tap(find.text('Продолжить'));
    await tester.pump();

    expect(controller.verifyOtpCalls, 0);
    expect(find.text('Код должен состоять из 6 цифр'), findsOneWidget);
  });

  testWidgets('shows an OTP verification error and enables the form again', (
    tester,
  ) async {
    final controller = _ScreenAuthController(
      codeSentState,
      verifyOtpResult: false,
    );
    await _pumpScreen(tester, controller, const OtpScreen());

    await tester.enterText(find.byType(EditableText), '000000');
    await tester.tap(find.text('Продолжить'));
    await tester.pump();

    expect(controller.verifyOtpCalls, 1);
    expect(find.text('Неверный код'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Продолжить'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('opens find after successful OTP verification', (tester) async {
    final controller = _ScreenAuthController(codeSentState);
    final router = GoRouter(
      initialLocation: '/auth/otp',
      routes: [
        GoRoute(path: '/auth/otp', builder: (_, _) => const OtpScreen()),
        GoRoute(
          path: '/catalog',
          builder: (_, _) => const Scaffold(body: Text('Найти')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '123456');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(controller.verifyOtpCalls, 1);
    expect(find.text('Найти'), findsOneWidget);
  });

  testWidgets('resumes a protected intent after successful OTP verification', (
    tester,
  ) async {
    final controller = _ScreenAuthController(codeSentState);
    final router = GoRouter(
      initialLocation: '/auth/otp',
      routes: [
        GoRoute(
          path: '/auth/otp',
          builder: (_, _) => const OtpScreen(returnTo: '/items/item-1/booking'),
        ),
        GoRoute(
          path: '/items/:id/booking',
          builder: (_, state) =>
              Scaffold(body: Text('Бронь ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => controller)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(EditableText), '123456');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(find.text('Бронь item-1'), findsOneWidget);
  });
}

const codeSentState = AuthState.codeSent(
  phone: '+79991234567',
  expiresInSeconds: 300,
);

const user = AuthUser(
  id: 'user-1',
  phone: '+79991234567',
  role: 'USER',
  isBlocked: false,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  _ScreenAuthController controller,
  Widget screen,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => controller)],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}

class _ScreenAuthController extends AuthController {
  _ScreenAuthController(
    this.initialState, {
    this.requestOtpResult = true,
    this.verifyOtpResult = true,
  });

  final AuthState initialState;
  final bool requestOtpResult;
  final bool verifyOtpResult;
  int requestOtpCalls = 0;
  int verifyOtpCalls = 0;

  @override
  AuthState build() => initialState;

  @override
  Future<bool> requestOtp(String rawPhone) async {
    requestOtpCalls += 1;
    if (requestOtpResult) {
      state = codeSentState;
      return true;
    }

    state = const AuthState.unauthenticated(
      errorMessage: 'Слишком много попыток',
    );
    return false;
  }

  @override
  Future<bool> verifyOtp(String code) async {
    verifyOtpCalls += 1;
    if (verifyOtpResult) {
      state = const AuthState.authenticated(user: user);
      return true;
    }

    state = const AuthState.codeSent(
      phone: '+79991234567',
      expiresInSeconds: 300,
      errorMessage: 'Неверный код',
    );
    return false;
  }
}
