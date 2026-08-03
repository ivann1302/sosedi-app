import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/shared_preferences_provider.dart';

enum AnalyticsEvent {
  appOpened('app_opened'),
  onboardingCompleted('onboarding_completed'),
  otpRequested('otp_requested'),
  loginCompleted('login_completed'),
  catalogOpened('catalog_opened'),
  bookingStarted('booking_started'),
  listingStarted('listing_started'),
  listingCreated('listing_created');

  const AnalyticsEvent(this.wireName);

  final String wireName;
}

enum AnalyticsConsent { unknown, granted, denied }

class AnalyticsPayload {
  const AnalyticsPayload(this.event);

  final AnalyticsEvent event;

  Map<String, Object> toMap() => {'event': event.wireName, 'schema_version': 1};
}

abstract interface class AnalyticsTransport {
  bool get isConfigured;

  Future<void> setCollectionEnabled(bool enabled);

  Future<void> send(AnalyticsPayload payload);

  Future<void> clearLocalData();
}

class DisabledAnalyticsTransport implements AnalyticsTransport {
  const DisabledAnalyticsTransport();

  @override
  bool get isConfigured => false;

  @override
  Future<void> clearLocalData() async {}

  @override
  Future<void> send(AnalyticsPayload payload) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

class AnalyticsStorage {
  const AnalyticsStorage(this._preferences);

  static const _consentKey = 'analytics.consent';

  final SharedPreferences _preferences;

  AnalyticsConsent get consent {
    return switch (_preferences.getString(_consentKey)) {
      'granted' => AnalyticsConsent.granted,
      'denied' => AnalyticsConsent.denied,
      _ => AnalyticsConsent.unknown,
    };
  }

  Future<void> setConsent(AnalyticsConsent consent) {
    return _preferences.setString(_consentKey, consent.name);
  }
}

class AnalyticsService {
  const AnalyticsService(this._getStorage, this._transport);

  final AnalyticsStorage Function() _getStorage;
  final AnalyticsTransport _transport;

  bool get isAvailable => _transport.isConfigured;

  Future<void> track(AnalyticsEvent event) async {
    if (!_transport.isConfigured ||
        _getStorage().consent != AnalyticsConsent.granted) {
      return;
    }
    await _transport.send(AnalyticsPayload(event));
  }

  Future<void> setConsent(AnalyticsConsent consent) async {
    if (consent == AnalyticsConsent.granted) {
      if (!_transport.isConfigured) {
        throw StateError('Analytics transport is not configured');
      }
      await _transport.setCollectionEnabled(true);
      await _getStorage().setConsent(consent);
      return;
    }

    await _getStorage().setConsent(consent);
    await _transport.setCollectionEnabled(false);
    await _transport.clearLocalData();
  }
}

final analyticsTransportProvider = Provider<AnalyticsTransport>((ref) {
  return const DisabledAnalyticsTransport();
});

final analyticsStorageProvider = Provider<AnalyticsStorage>((ref) {
  return AnalyticsStorage(ref.watch(sharedPreferencesProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    () => ref.read(analyticsStorageProvider),
    ref.watch(analyticsTransportProvider),
  );
});

final analyticsConsentProvider =
    NotifierProvider<AnalyticsConsentController, AnalyticsConsent>(
      AnalyticsConsentController.new,
    );

class AnalyticsConsentController extends Notifier<AnalyticsConsent> {
  @override
  AnalyticsConsent build() {
    return ref.watch(analyticsStorageProvider).consent;
  }

  bool get isAvailable => ref.read(analyticsServiceProvider).isAvailable;

  Future<void> setGranted(bool granted) async {
    final consent = granted
        ? AnalyticsConsent.granted
        : AnalyticsConsent.denied;
    await ref.read(analyticsServiceProvider).setConsent(consent);
    state = consent;
  }
}
