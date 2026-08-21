import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/app_shell.dart';

void main() {
  testWidgets('shows the five product destinations in the expected order', (
    tester,
  ) async {
    var selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
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

    await tester.tap(find.text('Брони'));

    expect(selectedIndex, 1);
  });
}
