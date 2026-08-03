import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics.dart';
import 'package:mobile/core/storage/onboarding_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingTransport implements AnalyticsTransport {
  final payloads = <Map<String, Object>>[];
  final enabledStates = <bool>[];
  var clearCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<void> clearLocalData() async {
    clearCalls += 1;
  }

  @override
  Future<void> send(AnalyticsPayload payload) async {
    payloads.add(payload.toMap());
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    enabledStates.add(enabled);
  }
}

void main() {
  test(
    'sends only allowlisted payload after consent and stops on opt-out',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final transport = _RecordingTransport();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          analyticsTransportProvider.overrideWithValue(transport),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(analyticsServiceProvider);
      await service.track(AnalyticsEvent.catalogOpened);
      expect(transport.payloads, isEmpty);

      await container.read(analyticsConsentProvider.notifier).setGranted(true);
      await service.track(AnalyticsEvent.catalogOpened);

      expect(transport.enabledStates, [true]);
      expect(transport.payloads, [
        {'event': 'catalog_opened', 'schema_version': 1},
      ]);
      expect(transport.payloads.single.keys, {'event', 'schema_version'});
      expect(transport.payloads.toString(), isNot(contains('phone')));
      expect(transport.payloads.toString(), isNot(contains('address')));

      await container.read(analyticsConsentProvider.notifier).setGranted(false);
      await service.track(AnalyticsEvent.bookingStarted);

      expect(transport.enabledStates, [true, false]);
      expect(transport.clearCalls, 1);
      expect(transport.payloads, hasLength(1));
      expect(container.read(analyticsConsentProvider), AnalyticsConsent.denied);
    },
  );

  test(
    'cannot grant consent before a transport passes the privacy gate',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(analyticsConsentProvider.notifier).setGranted(true),
        throwsA(isA<StateError>()),
      );
      expect(
        container.read(analyticsConsentProvider),
        AnalyticsConsent.unknown,
      );
    },
  );

  test('persists onboarding and emits its allowlisted event', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final transport = _RecordingTransport();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        analyticsTransportProvider.overrideWithValue(transport),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(onboardingCompletedProvider), isFalse);
    await container.read(analyticsConsentProvider.notifier).setGranted(true);
    await container.read(onboardingCompletedProvider.notifier).markCompleted();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(onboardingCompletedProvider), isTrue);
    expect(preferences.getBool('onboarding.completed'), isTrue);
    expect(transport.payloads, [
      {'event': 'onboarding_completed', 'schema_version': 1},
    ]);
  });
}
