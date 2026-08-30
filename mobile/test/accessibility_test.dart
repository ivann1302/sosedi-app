import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/app_shell.dart';
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
    expect(
      tester
          .widget<Text>(find.textContaining('Здравствуйте,').first)
          .style
          ?.fontWeight,
      FontWeight.w700,
    );
    semantics.dispose();
  });

  testWidgets('selected navigation foreground meets normal-text contrast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppShell(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          child: const SizedBox(),
        ),
      ),
    );

    final selectedIcon = find.byIcon(Icons.search);
    final selectedLabel = find.text('Найти');
    final iconColor = IconTheme.of(tester.element(selectedIcon)).color!;
    final labelStyle = DefaultTextStyle.of(tester.element(selectedLabel)).style;

    expect(_contrast(iconColor, AppColors.canvas), greaterThanOrEqualTo(4.5));
    expect(
      _contrast(labelStyle.color!, AppColors.canvas),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      NavigationBarTheme.of(
        tester.element(find.byType(NavigationBar)),
      ).labelTextStyle?.resolve({WidgetState.selected})?.fontWeight,
      FontWeight.w600,
    );
  });

  testWidgets('focused input boundary meets non-text contrast on its fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: TextField(autofocus: true)),
      ),
    );
    await tester.pump();

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    final focusedBorder = decoration.focusedBorder! as OutlineInputBorder;

    expect(decoration.fillColor, AppColors.cloud);
    expect(
      _contrast(focusedBorder.borderSide.color, decoration.fillColor!),
      greaterThanOrEqualTo(3),
    );
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
