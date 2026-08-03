import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class NotificationOpenSource {
  Future<String?> initialEventId();

  Stream<String> get openedEventIds;
}

final notificationOpenSourceProvider = Provider<NotificationOpenSource>((ref) {
  return const NoopNotificationOpenSource();
});

class NoopNotificationOpenSource implements NotificationOpenSource {
  const NoopNotificationOpenSource();

  @override
  Future<String?> initialEventId() async => null;

  @override
  Stream<String> get openedEventIds => const Stream<String>.empty();
}
