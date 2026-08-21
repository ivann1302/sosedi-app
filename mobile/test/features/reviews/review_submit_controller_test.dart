import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reviews/data/review_models.dart';
import 'package:mobile/features/reviews/data/review_service.dart';
import 'package:mobile/features/reviews/domain/review_submit_controller.dart';

void main() {
  test('reuses the client review ID when the same draft is retried', () async {
    final service = _RetryReviewService();
    final container = ProviderContainer(
      overrides: [reviewServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    await container.read(reviewSubmitProvider.future);
    final controller = container.read(reviewSubmitProvider.notifier);

    await controller.submit(
      bookingId: 'booking-1',
      rating: 5,
      text: 'Всё прошло отлично.',
    );
    await controller.submit(
      bookingId: 'booking-1',
      rating: 5,
      text: 'Всё прошло отлично.',
    );

    expect(service.clientReviewIds, hasLength(2));
    expect(service.clientReviewIds.first, service.clientReviewIds.last);
  });
}

class _RetryReviewService extends ReviewService {
  _RetryReviewService() : super(Dio());

  final clientReviewIds = <String>[];

  @override
  Future<ParticipantReview> create({
    required String bookingId,
    required int rating,
    required String? text,
    required String clientReviewId,
  }) async {
    clientReviewIds.add(clientReviewId);
    if (clientReviewIds.length == 1) {
      throw Exception('offline after commit');
    }
    return ParticipantReview(
      id: 'review-1',
      author: 'SELF',
      rating: rating,
      text: text,
      published: false,
      hidden: false,
      publishAt: DateTime.utc(2026, 8, 23),
      createdAt: DateTime.utc(2026, 8, 9),
    );
  }
}
