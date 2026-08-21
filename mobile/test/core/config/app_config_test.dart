import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';

void main() {
  test('keeps local defaults only outside production release', () {
    expect(
      resolveApiBaseUrl(
        apiBaseUrlOverride: '',
        appEnvironment: 'local',
        releaseMode: false,
        targetPlatform: TargetPlatform.android,
      ),
      'http://10.0.2.2:3000/api/v1',
    );
    expect(
      resolveApiBaseUrl(
        apiBaseUrlOverride: '',
        appEnvironment: 'local',
        releaseMode: false,
        targetPlatform: TargetPlatform.iOS,
      ),
      'http://localhost:3000/api/v1',
    );
  });

  test('accepts the explicit public production API', () {
    expect(
      resolveApiBaseUrl(
        apiBaseUrlOverride: 'https://api.sosedi.ru/api/v1',
        appEnvironment: 'production',
        releaseMode: true,
        targetPlatform: TargetPlatform.android,
      ),
      'https://api.sosedi.ru/api/v1',
    );
  });

  test('release mode requires the production environment', () {
    expect(
      () => resolveApiBaseUrl(
        apiBaseUrlOverride: 'https://api.sosedi.ru/api/v1',
        appEnvironment: '',
        releaseMode: true,
        targetPlatform: TargetPlatform.android,
      ),
      throwsStateError,
    );
  });

  test('production rejects local, IP and malformed API URLs', () {
    for (final url in [
      'http://api.sosedi.ru/api/v1',
      'https://localhost/api/v1',
      'https://127.0.0.1/api/v1',
      'https://api.sosedi.test/api/v1',
      'https://api.sosedi.ru/v1',
      'https://api.sosedi.ru/api/v1?debug=true',
    ]) {
      expect(
        () => resolveApiBaseUrl(
          apiBaseUrlOverride: url,
          appEnvironment: 'production',
          releaseMode: false,
          targetPlatform: TargetPlatform.android,
        ),
        throwsStateError,
        reason: url,
      );
    }
  });

  test('demo stubs are available only outside production release', () {
    expect(
      resolveDemoStubsEnabled(
        appEnvironment: 'local',
        releaseMode: false,
        enabled: true,
      ),
      isTrue,
    );
    expect(
      resolveDemoStubsEnabled(
        appEnvironment: 'production',
        releaseMode: false,
        enabled: true,
      ),
      isFalse,
    );
    expect(
      resolveDemoStubsEnabled(
        appEnvironment: 'local',
        releaseMode: true,
        enabled: true,
      ),
      isFalse,
    );
  });
}
