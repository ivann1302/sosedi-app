import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reviews/data/review_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('creates and reads only the review fields exposed by the API', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      if (requestIndex == 1) {
        return jsonResponse({
          'success': true,
          'data': [_participantReviewJson()],
          'error': null,
        });
      }
      if (requestIndex == 2) {
        return jsonResponse({
          'success': true,
          'data': _participantReviewJson(),
          'error': null,
        });
      }
      return jsonResponse({
        'success': true,
        'data': {
          'summary': {'average': 4.5, 'count': 2},
          'items': [_publicReviewJson()],
          'nextCursor': null,
        },
        'error': null,
      });
    });
    final service = ReviewService(Dio()..httpClientAdapter = adapter);

    final own = await service.listForBooking('booking-1');
    await service.create(
      bookingId: 'booking-1',
      rating: 5,
      text: '  Всё прошло отлично.  ',
      clientReviewId: '11111111-1111-4111-8111-111111111111',
    );
    final public = await service.listPublic('owner-1');

    expect(own.single.author, 'SELF');
    expect(public.summary.average, 4.5);
    expect(public.items.single.verifiedRental, isTrue);
    expect(adapter.requests[0].path, '/bookings/booking-1/reviews');
    expect(adapter.requests[1].method, 'POST');
    expect(adapter.requests[1].data, {
      'clientReviewId': '11111111-1111-4111-8111-111111111111',
      'rating': 5,
      'text': 'Всё прошло отлично.',
    });
    expect(adapter.requests[2].path, '/users/owner-1/reviews');
  });
}

Map<String, Object?> _participantReviewJson() => {
  'id': 'review-1',
  'author': 'SELF',
  'rating': 5,
  'text': 'Всё прошло отлично.',
  'published': false,
  'hidden': false,
  'publishAt': '2026-08-23T12:00:00.000Z',
  'createdAt': '2026-08-09T12:00:00.000Z',
};

Map<String, Object?> _publicReviewJson() => {
  'id': 'review-public-1',
  'authorRole': 'BORROWER',
  'rating': 5,
  'text': 'Всё прошло отлично.',
  'verifiedRental': true,
  'publishedAt': '2026-08-09T12:00:00.000Z',
  'createdAt': '2026-08-09T12:00:00.000Z',
};
