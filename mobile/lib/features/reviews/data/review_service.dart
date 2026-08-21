import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'review_models.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(ref.watch(dioProvider));
});

final bookingReviewsProvider = FutureProvider.autoDispose
    .family<List<ParticipantReview>, String>(
      (ref, bookingId) =>
          ref.watch(reviewServiceProvider).listForBooking(bookingId),
      retry: (_, _) => null,
    );

final publicReviewsProvider = FutureProvider.autoDispose
    .family<PublicReviewPage, String>(
      (ref, targetUserId) =>
          ref.watch(reviewServiceProvider).listPublic(targetUserId),
      retry: (_, _) => null,
    );

class ReviewService {
  const ReviewService(this._dio);

  final Dio _dio;

  Future<List<ParticipantReview>> listForBooking(String bookingId) async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/bookings/$bookingId/reviews'),
    );
    final envelope = ApiEnvelope<List<ParticipantReview>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map(
            (value) =>
                ParticipantReview.fromJson(value! as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
    return _data(envelope, 'Не удалось загрузить отзывы по аренде');
  }

  Future<ParticipantReview> create({
    required String bookingId,
    required int rating,
    required String? text,
    required String clientReviewId,
  }) async {
    final body = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/bookings/$bookingId/reviews',
        data: {
          'clientReviewId': clientReviewId,
          'rating': rating,
          if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        },
      ),
    );
    final envelope = ApiEnvelope<ParticipantReview>.fromJson(
      body,
      (json) => ParticipantReview.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось отправить отзыв');
  }

  Future<PublicReviewPage> listPublic(String targetUserId) async {
    final body = await _request(
      () => _dio.get<Map<String, dynamic>>('/users/$targetUserId/reviews'),
    );
    final envelope = ApiEnvelope<PublicReviewPage>.fromJson(
      body,
      (json) => PublicReviewPage.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось загрузить отзывы владельца');
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final body = (await request()).data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать ответ',
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(error, fallback: 'Отзывы временно недоступны');
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
