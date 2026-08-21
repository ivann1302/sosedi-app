import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_provider.dart';
import 'inbox_event.dart';

final inboxServiceProvider = Provider<InboxService>((ref) {
  return InboxService(ref.watch(dioProvider));
});

final inboxEventsProvider = FutureProvider.autoDispose<List<InboxEvent>>(
  (ref) => ref.watch(inboxServiceProvider).list(),
  retry: (_, _) => null,
);

class InboxService {
  const InboxService(this._dio);

  final Dio _dio;

  Future<List<InboxEvent>> list() async {
    final body = await _request(() => _dio.get('/inbox'));
    final envelope = ApiEnvelope<List<InboxEvent>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map((value) => InboxEvent.fromJson(value! as Map<String, dynamic>))
          .toList(growable: false),
    );
    return _data(envelope, 'Не удалось загрузить уведомления');
  }

  Future<InboxEvent> markRead(String eventId) async {
    final body = await _request(() => _dio.patch('/inbox/$eventId/read'));
    final envelope = ApiEnvelope<InboxEvent>.fromJson(
      body,
      (json) => InboxEvent.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось отметить уведомление');
  }

  Future<String?> resolveNavigationPath(String eventId) async {
    final body = await _request(() => _dio.get('/inbox/$eventId'));
    final envelope = ApiEnvelope<InboxEventDetails>.fromJson(
      body,
      (json) => InboxEventDetails.fromJson(json! as Map<String, dynamic>),
    );
    final event = envelope.data;
    if (!envelope.success || event == null || event.eventId != eventId) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось открыть уведомление',
      );
    }

    final bookingId = event.bookingId;
    if (bookingId != null) {
      return event.eventType == 'BOOKING_MESSAGE_CREATED'
          ? '/bookings/$bookingId/chat'
          : '/bookings/$bookingId';
    }
    final supportTicketId = event.supportTicketId;
    if (supportTicketId != null) {
      return '/support/$supportTicketId';
    }
    final itemId = event.itemId;
    return itemId == null ? null : '/items/$itemId/edit';
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать уведомления',
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      final body = error.response?.data;
      final apiError = body is Map<String, dynamic> ? body['error'] : null;
      throw ApiException(
        code: apiError is Map<String, dynamic>
            ? apiError['code']?.toString() ?? 'API_ERROR'
            : 'NETWORK_ERROR',
        message: apiError is Map<String, dynamic>
            ? apiError['message']?.toString() ??
                  'Не удалось загрузить уведомления'
            : 'Не удалось загрузить уведомления',
      );
    }
  }

  T _data<T>(ApiEnvelope<T> envelope, String fallback) {
    final data = envelope.data;
    if (envelope.success && data != null) {
      return data;
    }
    throw ApiException(
      code: envelope.error?.code ?? 'API_ERROR',
      message: envelope.error?.message ?? fallback,
    );
  }
}
