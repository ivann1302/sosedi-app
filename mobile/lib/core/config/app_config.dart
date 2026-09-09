import 'package:flutter/foundation.dart';

import 'production_url.dart';

class AppConfig {
  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const _appEnvironment = String.fromEnvironment('APP_ENVIRONMENT');
  static const _yandexTilesApiKey = String.fromEnvironment(
    'YANDEX_TILES_API_KEY',
  );

  static String get apiBaseUrl => resolveApiBaseUrl(
    apiBaseUrlOverride: _apiBaseUrlOverride,
    appEnvironment: _appEnvironment,
    releaseMode: kReleaseMode,
    targetPlatform: defaultTargetPlatform,
  );

  static String? get yandexTilesApiKey =>
      resolveProviderApiKey(_yandexTilesApiKey);
}

String? resolveProviderApiKey(String apiKey) {
  final value = apiKey.trim();
  return value.isEmpty ? null : value;
}

String resolveApiBaseUrl({
  required String apiBaseUrlOverride,
  required String appEnvironment,
  required bool releaseMode,
  required TargetPlatform targetPlatform,
}) {
  if (releaseMode && appEnvironment != 'production') {
    throw StateError('Release builds require APP_ENVIRONMENT=production');
  }
  if (releaseMode || appEnvironment == 'production') {
    final uri = Uri.tryParse(apiBaseUrlOverride);
    if (!isCleanPublicHttpsUri(uri) ||
        uri!.path.replaceAll(RegExp(r'/+$'), '') != '/api/v1') {
      throw StateError(
        'Production API_BASE_URL must be a public HTTPS /api/v1 URL',
      );
    }
    return apiBaseUrlOverride;
  }

  if (apiBaseUrlOverride.isNotEmpty) {
    return apiBaseUrlOverride;
  }

  return targetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000/api/v1'
      : 'http://localhost:3000/api/v1';
}
