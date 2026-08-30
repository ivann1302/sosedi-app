import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/app_shell.dart';
import 'package:mobile/core/theme/app_theme.dart';

void main() {
  testWidgets('shows the five product destinations in the expected order', (
    tester,
  ) async {
    var selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppShell(
          currentIndex: 0,
          onDestinationSelected: (index) => selectedIndex = index,
          child: const Center(child: Text('Каталог')),
        ),
      ),
    );

    expect(find.text('Каталог'), findsOneWidget);
    expect(find.text('Найти'), findsOneWidget);
    expect(find.text('Брони'), findsOneWidget);
    expect(find.text('Сдать'), findsOneWidget);
    expect(find.text('Входящие'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);

    for (final destination in <(String, int)>[
      ('Найти', 0),
      ('Брони', 1),
      ('Сдать', 2),
      ('Входящие', 3),
      ('Профиль', 4),
    ]) {
      await tester.tap(find.text(destination.$1));

      expect(selectedIndex, destination.$2);
    }
  });
}
