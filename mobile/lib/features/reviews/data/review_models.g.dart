// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParticipantReview _$ParticipantReviewFromJson(Map<String, dynamic> json) =>
    _ParticipantReview(
      id: json['id'] as String,
      author: json['author'] as String,
      rating: (json['rating'] as num).toInt(),
      text: json['text'] as String?,
      published: json['published'] as bool,
      hidden: json['hidden'] as bool,
      publishAt: DateTime.parse(json['publishAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ParticipantReviewToJson(_ParticipantReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author': instance.author,
      'rating': instance.rating,
      'text': instance.text,
      'published': instance.published,
      'hidden': instance.hidden,
      'publishAt': instance.publishAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

_PublicReview _$PublicReviewFromJson(Map<String, dynamic> json) =>
    _PublicReview(
      id: json['id'] as String,
      authorRole: json['authorRole'] as String,
      rating: (json['rating'] as num).toInt(),
      text: json['text'] as String?,
      verifiedRental: json['verifiedRental'] as bool,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PublicReviewToJson(_PublicReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorRole': instance.authorRole,
      'rating': instance.rating,
      'text': instance.text,
      'verifiedRental': instance.verifiedRental,
      'publishedAt': instance.publishedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

_ReviewSummary _$ReviewSummaryFromJson(Map<String, dynamic> json) =>
    _ReviewSummary(
      average: (json['average'] as num?)?.toDouble(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewSummaryToJson(_ReviewSummary instance) =>
    <String, dynamic>{'average': instance.average, 'count': instance.count};

_PublicReviewPage _$PublicReviewPageFromJson(Map<String, dynamic> json) =>
    _PublicReviewPage(
      summary: ReviewSummary.fromJson(json['summary'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => PublicReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$PublicReviewPageToJson(_PublicReviewPage instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
