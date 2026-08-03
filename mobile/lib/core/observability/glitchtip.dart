import 'dart:async';
import 'dart:collection';

import 'package:sentry_flutter/sentry_flutter.dart';

const redactedDiagnosticValue = '[REDACTED]';

const _glitchTipDsn = String.fromEnvironment('GLITCHTIP_DSN');
const _appEnvironment = String.fromEnvironment(
  'APP_ENVIRONMENT',
  defaultValue: 'development',
);
const _appRelease = String.fromEnvironment('APP_RELEASE');

const _sensitiveKeys = {
  'authorization',
  'proxyauthorization',
  'accesstoken',
  'refreshtoken',
  'admintoken',
  'token',
  'jwt',
  'cookie',
  'cookies',
  'setcookie',
  'phone',
  'phonenumber',
  'mobile',
  'address',
  'pickupaddress',
  'dropoffaddress',
  'exactaddress',
  'coordinates',
  'exactcoordinates',
  'kyc',
  'kycdocument',
  'kycpayload',
  'passport',
  'passportnumber',
  'selfie',
  'paymentpayload',
  'paymentdata',
  'paymentdetails',
  'providerpayload',
  'cardnumber',
  'pan',
  'cvv',
  'cvc',
  'presignedurl',
  'uploadurl',
  'downloadurl',
  'secret',
  'clientsecret',
  'apikey',
  'otp',
  'otpcode',
  'verificationcode',
  'password',
};

const _droppedKeys = {
  'abspath',
  'contextline',
  'precontext',
  'postcontext',
  'vars',
};

Future<void> runWithGlitchTip(FutureOr<void> Function() appRunner) async {
  if (_glitchTipDsn.isEmpty) {
    await appRunner();
    return;
  }

  _validateGlitchTipDsn(_glitchTipDsn);
  await SentryFlutter.init(
    (options) {
      options
        ..dsn = _glitchTipDsn
        ..environment = _appEnvironment
        ..sendDefaultPii = false
        ..maxRequestBodySize = MaxRequestBodySize.never
        ..attachScreenshot = false
        ..tracesSampleRate = 0
        ..enableLogs = false
        ..beforeSend = scrubGlitchTipEvent
        ..beforeBreadcrumb = scrubGlitchTipBreadcrumb;
      if (_appRelease.isNotEmpty) {
        options.release = _appRelease;
      }
    },
    appRunner: appRunner,
  );
}

SentryEvent scrubGlitchTipEvent(SentryEvent event, Hint hint) {
  final eventJson = event.toJson()
    ..remove('user')
    ..remove('request');
  final contexts = eventJson['contexts'];
  if (contexts is Map) {
    contexts
      ..remove('response')
      ..remove('feedback');
  }
  final sanitizedEvent = SentryEvent.fromJson(
    Map<String, dynamic>.from(redactDiagnosticData(eventJson) as Map),
  );

  hint.attachments.clear();
  hint
    ..screenshot = null
    ..viewHierarchy = null;
  return sanitizedEvent;
}

Breadcrumb? scrubGlitchTipBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
  if (breadcrumb == null) {
    return null;
  }
  breadcrumb.message = _redactNullableText(breadcrumb.message);
  final data = breadcrumb.data;
  if (data != null) {
    breadcrumb.data = Map<String, dynamic>.from(
      redactDiagnosticData(data) as Map,
    );
  }
  return breadcrumb;
}

dynamic redactDiagnosticData(dynamic value) {
  return _redactValue(value, HashSet<Object>.identity());
}

String redactDiagnosticText(String value) {
  return value
      .replaceAll(
        RegExp(
          r'https?://[^\s,;]*(?:x-amz-|x-goog-|signature=)[^\s,;]*',
          caseSensitive: false,
        ),
        '[REDACTED_URL]',
      )
      .replaceAll(
        RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
        'Bearer $redactedDiagnosticValue',
      )
      .replaceAll(
        RegExp(r'\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
        redactedDiagnosticValue,
      )
      .replaceAllMapped(
        RegExp(r'\b(cookie|set-cookie)\s*:\s*[^,\r\n]*',
            caseSensitive: false),
        (match) => '${match.group(1)}: $redactedDiagnosticValue',
      )
      .replaceAll(
        RegExp(
          r'(?:\+7|8)[\s(-]*\d{3}[\s)-]*\d{3}[\s-]*\d{2}[\s-]*\d{2}\b',
        ),
        redactedDiagnosticValue,
      )
      .replaceAllMapped(
        RegExp(r'\b(otp|код)(\s*[:=]\s*|\s+)\d{4,8}\b',
            caseSensitive: false),
        (match) => '${match.group(1)}: $redactedDiagnosticValue',
      );
}

dynamic _redactValue(dynamic value, Set<Object> seen) {
  if (value is String) {
    return redactDiagnosticText(value);
  }
  if (value == null || value is num || value is bool) {
    return value;
  }
  if (seen.contains(value)) {
    return '[Circular]';
  }
  seen.add(value as Object);

  if (value is List) {
    return value.map((entry) => _redactValue(entry, seen)).toList();
  }
  if (value is Set) {
    return value.map((entry) => _redactValue(entry, seen)).toList();
  }
  if (value is Map) {
    final redacted = <String, dynamic>{};
    value.forEach((key, entry) {
      final stringKey = key.toString();
      if (_isDroppedKey(stringKey)) {
        return;
      }
      redacted[stringKey] = _isSensitiveKey(stringKey)
          ? redactedDiagnosticValue
          : _redactValue(entry, seen);
    });
    return redacted;
  }
  return redactDiagnosticText(value.toString());
}

String? _redactNullableText(String? value) {
  return value == null ? null : redactDiagnosticText(value);
}

bool _isSensitiveKey(String key) {
  final normalized = _normalizeKey(key);
  return _sensitiveKeys.contains(normalized) ||
      normalized.endsWith('token') ||
      normalized.endsWith('secret');
}

bool _isDroppedKey(String key) => _droppedKeys.contains(_normalizeKey(key));

String _normalizeKey(String key) {
  return key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
}

void _validateGlitchTipDsn(String dsn) {
  final uri = Uri.tryParse(dsn);
  final host = uri?.host.toLowerCase() ?? '';
  if (uri == null ||
      uri.scheme != 'https' ||
      host.isEmpty ||
      host == 'sentry.io' ||
      host.endsWith('.sentry.io')) {
    throw StateError(
      'GLITCHTIP_DSN должен указывать на self-hosted HTTPS GlitchTip',
    );
  }
}
