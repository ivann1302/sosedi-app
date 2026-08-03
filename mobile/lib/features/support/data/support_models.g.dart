// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SupportTicket _$SupportTicketFromJson(Map<String, dynamic> json) =>
    _SupportTicket(
      id: json['id'] as String,
      type: json['type'] as String,
      bookingId: json['bookingId'] as String?,
      bookingIssueReason: json['bookingIssueReason'] as String?,
      subject: json['subject'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      adminResponse: json['adminResponse'] as String?,
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SupportTicketToJson(_SupportTicket instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'bookingId': instance.bookingId,
      'bookingIssueReason': instance.bookingIssueReason,
      'subject': instance.subject,
      'message': instance.message,
      'status': instance.status,
      'adminResponse': instance.adminResponse,
      'respondedAt': instance.respondedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_CreateSupportTicketDraft _$CreateSupportTicketDraftFromJson(
  Map<String, dynamic> json,
) => _CreateSupportTicketDraft(
  subject: json['subject'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$CreateSupportTicketDraftToJson(
  _CreateSupportTicketDraft instance,
) => <String, dynamic>{
  'subject': instance.subject,
  'message': instance.message,
};

_SupportAttachment _$SupportAttachmentFromJson(Map<String, dynamic> json) =>
    _SupportAttachment(
      id: json['id'] as String,
      sha256: json['sha256'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SupportAttachmentToJson(_SupportAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sha256': instance.sha256,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_SupportMessage _$SupportMessageFromJson(Map<String, dynamic> json) =>
    _SupportMessage(
      id: json['id'] as String,
      authorRole: json['authorRole'] as String,
      body: json['body'] as String,
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => SupportAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SupportMessageToJson(_SupportMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorRole': instance.authorRole,
      'body': instance.body,
      'attachments': instance.attachments,
      'createdAt': instance.createdAt.toIso8601String(),
    };
