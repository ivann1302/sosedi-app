import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/home_screen.dart';

void main() {
  testWidgets('shows borrowing and lending to the same authenticated user', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_AuthenticatedController.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('Беру в аренду'), findsOneWidget);
    expect(find.text('Сдаю'), findsOneWidget);
    expect(find.textContaining('Выберите роль'), findsNothing);
  });
}

class _AuthenticatedController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'user-1',
      phone: '+79991234567',
      role: 'USER',
      isBlocked: false,
      name: 'Анна',
    ),
  );
}
