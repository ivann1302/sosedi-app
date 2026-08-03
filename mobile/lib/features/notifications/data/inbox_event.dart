import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbox_event.freezed.dart';
part 'inbox_event.g.dart';

@freezed
abstract class InboxEvent with _$InboxEvent {
  const factory InboxEvent({
    required String eventId,
    required String? bookingId,
    required String? supportTicketId,
    required String? itemId,
    required String eventType,
    required DateTime? readAt,
    required DateTime createdAt,
  }) = _InboxEvent;

  factory InboxEvent.fromJson(Map<String, dynamic> json) =>
      _$InboxEventFromJson(json);
}

@freezed
abstract class InboxEventDetails with _$InboxEventDetails {
  const factory InboxEventDetails({
    required String eventId,
    required String eventType,
    String? bookingId,
    String? supportTicketId,
    String? itemId,
  }) = _InboxEventDetails;

  factory InboxEventDetails.fromJson(Map<String, dynamic> json) =>
      _$InboxEventDetailsFromJson(json);
}
