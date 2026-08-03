import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/profile/data/profile_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('loads the authenticated user profile from users/me', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'GET');
      expect(options.path, '/users/me');

      return jsonResponse({
        'success': true,
        'data': {
          'id': 'user-1',
          'phone': '+79991234567',
          'name': 'Анна',
          'city': 'Москва',
          'avatarUrl': null,
          'role': 'USER',
          'kycStatus': 'VERIFIED',
          'isBlocked': false,
          'createdAt': '2026-07-01T10:00:00.000Z',
          'updatedAt': '2026-07-28T10:00:00.000Z',
        },
        'error': null,
      });
    });
    final service = ProfileService(Dio()..httpClientAdapter = adapter);

    final profile = await service.fetchProfile();

    expect(profile.name, 'Анна');
    expect(profile.city, 'Москва');
    expect(profile.kycStatus, 'VERIFIED');
  });

  test('updates only editable profile fields', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'PATCH');
      expect(options.path, '/users/me');
      expect(options.data, {'name': 'Анна', 'city': 'Казань'});

      return jsonResponse({
        'success': true,
        'data': profileJson(city: 'Казань'),
        'error': null,
      });
    });
    final service = ProfileService(Dio()..httpClientAdapter = adapter);

    final profile = await service.updateProfile(name: 'Анна', city: 'Казань');

    expect(profile.city, 'Казань');
  });

  test('uploads an avatar through presign, quarantine and confirm', () async {
    final adapter = CallbackAdapter((options) {
      if (options.path == '/uploads/presigned-url') {
        expect(options.data, {
          'purpose': 'AVATAR',
          'fileName': 'avatar.jpg',
          'contentType': 'image/jpeg',
          'sizeBytes': 4,
        });
        return jsonResponse({
          'success': true,
          'data': {
            'intentId': 'intent-1',
            'uploadUrl': 'https://upload.test/avatar',
            'fields': {'key': 'quarantine/avatar.jpg', 'Policy': 'signed'},
          },
          'error': null,
        });
      }
      if (options.uri.host == 'upload.test') {
        expect(options.data, isA<FormData>());
        return ResponseBody.fromString('', 204);
      }
      if (options.path == '/uploads/avatars/confirm') {
        expect(options.data, {'intentId': 'intent-1'});
        return jsonResponse({
          'success': true,
          'data': {'avatarUrl': 'https://cdn.test/avatar.webp'},
          'error': null,
        });
      }
      throw StateError('Unexpected request: ${options.path}');
    });
    final service = ProfileService(Dio()..httpClientAdapter = adapter);
    final file = XFile.fromData(
      Uint8List.fromList([1, 2, 3, 4]),
      name: 'avatar.jpg',
      mimeType: 'image/jpeg',
    );

    late final String avatarUrl;
    try {
      avatarUrl = await service.replaceAvatar(file);
    } catch (error) {
      fail(
        '$error; requests: '
        '${adapter.requests.map((request) => '${request.method} ${request.path} ${request.data}')}',
      );
    }

    expect(avatarUrl, 'https://cdn.test/avatar.webp');
    expect(adapter.requests, hasLength(3));
  });

  test('requests account closure and reads its status', () async {
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'DELETE');
      expect(options.path, '/users/me');
      return jsonResponse({
        'success': true,
        'data': {
          'status': 'PENDING_OBLIGATIONS',
          'requestedAt': '2026-07-29T02:00:00.000Z',
          'anonymizedAt': null,
        },
        'error': null,
      });
    });
    final service = ProfileService(Dio()..httpClientAdapter = adapter);

    final result = await service.closeAccount();

    expect(result.status, 'PENDING_OBLIGATIONS');
    expect(result.anonymizedAt, isNull);
  });

  test('creates a data export through the one-time step-up flow', () async {
    const stepUpToken = 'one-time-step-up-token';
    final adapter = CallbackAdapter((options) {
      if (options.path == '/auth/step-up/data-export/otp/request') {
        expect(options.method, 'POST');
        expect(options.uri.toString(), isNot(contains(stepUpToken)));
        return jsonResponse({
          'success': true,
          'data': {'phone': '+79991234567', 'expiresInSeconds': 600},
          'error': null,
        });
      }
      if (options.path == '/auth/step-up/data-export/otp/verify') {
        expect(options.method, 'POST');
        expect(options.data, {'code': '123456'});
        expect(options.extra['skipAuthRefresh'], isTrue);
        return jsonResponse({
          'success': true,
          'data': {'stepUpToken': stepUpToken, 'expiresInSeconds': 300},
          'error': null,
        });
      }
      if (options.path == '/users/me/data-export') {
        expect(options.method, 'POST');
        expect(options.data, {'stepUpToken': stepUpToken});
        expect(options.uri.toString(), isNot(contains(stepUpToken)));
        expect(options.headers.values.join(' '), isNot(contains(stepUpToken)));
        expect(options.extra['skipAuthRefresh'], isTrue);
        return jsonResponse({
          'success': true,
          'data': dataExportJson(),
          'error': null,
        });
      }
      throw StateError('Unexpected request: ${options.path}');
    });
    final service = ProfileService(Dio()..httpClientAdapter = adapter);

    final otp = await service.requestDataExportOtp();
    final stepUp = await service.verifyDataExportOtp('123456');
    final export = await service.createDataExport(stepUp.stepUpToken);

    expect(otp.expiresInSeconds, 600);
    expect(stepUp.expiresInSeconds, 300);
    expect(export.schemaVersion, '2026-07-30.1');
    expect(export.profile['phone'], '+79991234567');
    expect(adapter.requests, hasLength(3));
  });
}

Map<String, Object?> profileJson({String city = 'Москва'}) => {
  'id': 'user-1',
  'phone': '+79991234567',
  'name': 'Анна',
  'city': city,
  'avatarUrl': null,
  'role': 'USER',
  'kycStatus': 'VERIFIED',
  'isBlocked': false,
  'createdAt': '2026-07-01T10:00:00.000Z',
  'updatedAt': '2026-07-28T10:00:00.000Z',
};

Map<String, Object?> dataExportJson() => {
  'schemaVersion': '2026-07-30.1',
  'generatedAt': '2026-07-30T02:00:00.000Z',
  'retentionPolicyVersion': 'ADR-0002/2026-07-27',
  'profile': {'id': 'user-1', 'phone': '+79991234567', 'name': 'Анна'},
  'listings': <Object?>[],
  'bookings': <Object?>[],
  'inbox': <Object?>[],
  'support': <Object?>[],
  'reports': <Object?>[],
  'blocks': <Object?>[],
  'documentAcceptances': <Object?>[],
  'financialHistory': <Object?>[],
  'fileManifest': <Object?>[],
  'processing': {'categories': <Object?>[], 'excluded': <Object?>[]},
};
