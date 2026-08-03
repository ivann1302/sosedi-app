import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';
import 'package:mobile/features/notifications/domain/notification_navigation_controller.dart';
import 'package:mobile/features/notifications/domain/notification_open_source.dart';

void main() {
  const eventId = '9df957f9-b014-4547-a083-cab9b9892351';

  test(
    'waits for authentication before resolving a cold-start event',
    () async {
      final auth = _TestAuthController(const AuthState.unauthenticated());
      final inbox = _FakeInboxService('/bookings/booking-1');
      final paths = <String>[];
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          inboxServiceProvider.overrideWithValue(inbox),
          notificationOpenSourceProvider.overrideWithValue(
            const _TestOpenSource(initial: eventId),
          ),
          notificationNavigatorProvider.overrideWithValue(paths.add),
        ],
      );
      addTearDown(container.dispose);

      container.read(notificationNavigationProvider);
      await _flush();

      expect(container.read(notificationNavigationProvider), eventId);
      expect(inbox.requests, isEmpty);
      expect(paths, isEmpty);

      auth.setAuthenticated();
      await _flush();

      expect(inbox.requests, [eventId]);
      expect(paths, ['/bookings/booking-1']);
      expect(container.read(notificationNavigationProvider), isNull);
    },
  );

  test('drops an unknown event without navigating', () async {
    final inbox = _FakeInboxService(
      null,
      error: const ApiException(
        code: 'NOT_FOUND',
        message: 'Событие не найдено',
      ),
    );
    final paths = <String>[];
    final container = _authenticatedContainer(inbox, paths);
    addTearDown(container.dispose);

    await container
        .read(notificationNavigationProvider.notifier)
        .handleEventId(eventId);

    expect(inbox.requests, [eventId]);
    expect(paths, isEmpty);
    expect(container.read(notificationNavigationProvider), isNull);
  });

  test('rejects a payload that is not an opaque UUID v4', () async {
    final inbox = _FakeInboxService('/bookings/booking-1');
    final paths = <String>[];
    final container = _authenticatedContainer(inbox, paths);
    addTearDown(container.dispose);

    await container
        .read(notificationNavigationProvider.notifier)
        .handleEventId('booking-1');

    expect(inbox.requests, isEmpty);
    expect(paths, isEmpty);
  });
}

ProviderContainer _authenticatedContainer(
  _FakeInboxService inbox,
  List<String> paths,
) {
  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => _TestAuthController(const AuthState.authenticated(user: _user)),
      ),
      inboxServiceProvider.overrideWithValue(inbox),
      notificationNavigatorProvider.overrideWithValue(paths.add),
    ],
  )..read(notificationNavigationProvider);
}

const _user = AuthUser(
  id: 'user-1',
  phone: '+79991234567',
  role: 'USER',
  isBlocked: false,
);

class _TestAuthController extends AuthController {
  _TestAuthController(this._initialState);

  final AuthState _initialState;

  @override
  AuthState build() => _initialState;

  void setAuthenticated() {
    state = const AuthState.authenticated(user: _user);
  }
}

class _FakeInboxService extends InboxService {
  _FakeInboxService(this.path, {this.error}) : super(Dio());

  final String? path;
  final ApiException? error;
  final requests = <String>[];

  @override
  Future<String?> resolveNavigationPath(String eventId) async {
    requests.add(eventId);
    if (error case final error?) {
      throw error;
    }
    return path;
  }
}

class _TestOpenSource implements NotificationOpenSource {
  const _TestOpenSource({this.initial});

  final String? initial;

  @override
  Future<String?> initialEventId() async => initial;

  @override
  Stream<String> get openedEventIds => const Stream<String>.empty();
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
