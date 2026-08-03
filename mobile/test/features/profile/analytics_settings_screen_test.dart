import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics.dart';
import 'package:mobile/core/storage/shared_preferences_provider.dart';
import 'package:mobile/features/profile/presentation/analytics_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('keeps analytics disabled before the privacy transport gate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: AnalyticsSettingsScreen()),
      ),
    );

    final analyticsSwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(analyticsSwitch.value, isFalse);
    expect(analyticsSwitch.onChanged, isNull);
    expect(find.textContaining('Недоступно до публикации'), findsOneWidget);
  });

  testWidgets('allows an existing consent to be revoked immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'analytics.consent': 'granted'});
    final preferences = await SharedPreferences.getInstance();
    final transport = _RecordingTransport();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          analyticsTransportProvider.overrideWithValue(transport),
        ],
        child: const MaterialApp(home: AnalyticsSettingsScreen()),
      ),
    );

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(preferences.getString('analytics.consent'), 'denied');
    expect(transport.enabledStates, [false]);
    expect(transport.clearCalls, 1);
  });
}

class _RecordingTransport implements AnalyticsTransport {
  final enabledStates = <bool>[];
  var clearCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<void> clearLocalData() async {
    clearCalls += 1;
  }

  @override
  Future<void> send(AnalyticsPayload payload) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    enabledStates.add(enabled);
  }
}
