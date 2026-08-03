import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_models.freezed.dart';
part 'support_models.g.dart';

@freezed
abstract class SupportTicket with _$SupportTicket {
  const factory SupportTicket({
    required String id,
    required String type,
    required String? bookingId,
    required String? bookingIssueReason,
    required String subject,
    required String message,
    required String status,
    required String? adminResponse,
    required DateTime? respondedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SupportTicket;

  factory SupportTicket.fromJson(Map<String, dynamic> json) =>
      _$SupportTicketFromJson(json);
}

@freezed
abstract class CreateSupportTicketDraft with _$CreateSupportTicketDraft {
  const factory CreateSupportTicketDraft({
    required String subject,
    required String message,
  }) = _CreateSupportTicketDraft;

  factory CreateSupportTicketDraft.fromJson(Map<String, dynamic> json) =>
      _$CreateSupportTicketDraftFromJson(json);
}

@freezed
abstract class SupportAttachment with _$SupportAttachment {
  const factory SupportAttachment({
    required String id,
    required String sha256,
    required DateTime createdAt,
  }) = _SupportAttachment;

  factory SupportAttachment.fromJson(Map<String, dynamic> json) =>
      _$SupportAttachmentFromJson(json);
}

@freezed
abstract class SupportMessage with _$SupportMessage {
  const factory SupportMessage({
    required String id,
    required String authorRole,
    required String body,
    required List<SupportAttachment> attachments,
    required DateTime createdAt,
  }) = _SupportMessage;

  factory SupportMessage.fromJson(Map<String, dynamic> json) =>
      _$SupportMessageFromJson(json);
}
