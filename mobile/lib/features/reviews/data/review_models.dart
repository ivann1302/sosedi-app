import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_models.freezed.dart';
part 'review_models.g.dart';

@freezed
abstract class ParticipantReview with _$ParticipantReview {
  const factory ParticipantReview({
    required String id,
    required String author,
    required int rating,
    required String? text,
    required bool published,
    required bool hidden,
    required DateTime publishAt,
    required DateTime createdAt,
  }) = _ParticipantReview;

  factory ParticipantReview.fromJson(Map<String, dynamic> json) =>
      _$ParticipantReviewFromJson(json);
}

@freezed
abstract class PublicReview with _$PublicReview {
  const factory PublicReview({
    required String id,
    required String authorRole,
    required int rating,
    required String? text,
    required bool verifiedRental,
    required DateTime publishedAt,
    required DateTime createdAt,
  }) = _PublicReview;

  factory PublicReview.fromJson(Map<String, dynamic> json) =>
      _$PublicReviewFromJson(json);
}

@freezed
abstract class ReviewSummary with _$ReviewSummary {
  const factory ReviewSummary({required double? average, required int count}) =
      _ReviewSummary;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) =>
      _$ReviewSummaryFromJson(json);
}

@freezed
abstract class PublicReviewPage with _$PublicReviewPage {
  const factory PublicReviewPage({
    required ReviewSummary summary,
    required List<PublicReview> items,
    required String? nextCursor,
  }) = _PublicReviewPage;

  factory PublicReviewPage.fromJson(Map<String, dynamic> json) =>
      _$PublicReviewPageFromJson(json);
}
