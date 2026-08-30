// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InboxEvent _$InboxEventFromJson(Map<String, dynamic> json) => _InboxEvent(
  eventId: json['eventId'] as String,
  bookingId: json['bookingId'] as String?,
  supportTicketId: json['supportTicketId'] as String?,
  itemId: json['itemId'] as String?,
  eventType: json['eventType'] as String,
  readAt: json['readAt'] == null
      ? null
      : DateTime.parse(json['readAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$InboxEventToJson(_InboxEvent instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'bookingId': instance.bookingId,
      'supportTicketId': instance.supportTicketId,
      'itemId': instance.itemId,
      'eventType': instance.eventType,
      'readAt': instance.readAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

_InboxEventDetails _$InboxEventDetailsFromJson(Map<String, dynamic> json) =>
    _InboxEventDetails(
      eventId: json['eventId'] as String,
      eventType: json['eventType'] as String,
      bookingId: json['bookingId'] as String?,
      supportTicketId: json['supportTicketId'] as String?,
      itemId: json['itemId'] as String?,
    );

Map<String, dynamic> _$InboxEventDetailsToJson(_InboxEventDetails instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'eventType': instance.eventType,
      'bookingId': instance.bookingId,
      'supportTicketId': instance.supportTicketId,
      'itemId': instance.itemId,
    };

_InboxPage _$InboxPageFromJson(Map<String, dynamic> json) => _InboxPage(
  items: (json['items'] as List<dynamic>)
      .map((e) => InboxEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$InboxPageToJson(_InboxPage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
