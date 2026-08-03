import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/home_screen.dart';

void main() {
  testWidgets('key home actions remain readable and semantic at 200% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_AuthenticatedController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scenario = find.widgetWithText(ListTile, 'Беру в аренду');
    expect(tester.getSize(scenario).height, greaterThanOrEqualTo(48));
    expect(
      tester
          .getSemantics(scenario)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSize(find.widgetWithText(OutlinedButton, 'Открыть профиль'))
          .height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  test('theme text pairs meet normal-text contrast', () {
    final scheme = AppTheme.light().colorScheme;

    expect(
      _contrast(scheme.onPrimary, scheme.primary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(scheme.onSurface, scheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(scheme.onSecondary, scheme.secondary),
      greaterThanOrEqualTo(4.5),
    );
    expect(_contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(4.5));
  });
}

class _AuthenticatedController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'user-1',
      phone: '+79991234567',
      name: 'Иван',
      role: 'USER',
      isBlocked: false,
    ),
  );
}

double _contrast(Color first, Color second) {
  final light = first.computeLuminance();
  final dark = second.computeLuminance();
  final max = light > dark ? light : dark;
  final min = light > dark ? dark : light;
  return (max + 0.05) / (min + 0.05);
}
