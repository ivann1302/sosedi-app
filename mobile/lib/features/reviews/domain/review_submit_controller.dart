import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/identifiers/uuid_v4.dart';
import '../data/review_models.dart';
import '../data/review_service.dart';

final reviewSubmitProvider =
    AsyncNotifierProvider<ReviewSubmitController, ParticipantReview?>(
      ReviewSubmitController.new,
      retry: (_, _) => null,
    );

class ReviewSubmitController extends AsyncNotifier<ParticipantReview?> {
  String? _draftKey;
  String? _clientReviewId;

  @override
  Future<ParticipantReview?> build() async => null;

  Future<bool> submit({
    required String bookingId,
    required int rating,
    required String? text,
  }) async {
    if (state.isLoading) {
      return false;
    }
    final normalized = text?.trim();
    final draftKey = '$bookingId:$rating:${normalized ?? ''}';
    if (_draftKey != draftKey) {
      _draftKey = draftKey;
      _clientReviewId = generateUuidV4();
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(reviewServiceProvider)
          .create(
            bookingId: bookingId,
            rating: rating,
            text: normalized?.isEmpty == true ? null : normalized,
            clientReviewId: _clientReviewId!,
          ),
    );
    if (state.hasError) {
      return false;
    }
    _draftKey = null;
    _clientReviewId = null;
    ref.invalidate(bookingReviewsProvider(bookingId));
    ref.invalidate(publicReviewsProvider);
    return true;
  }
}
