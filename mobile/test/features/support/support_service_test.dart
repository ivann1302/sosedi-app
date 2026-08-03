import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/support/data/support_models.dart';
import 'package:mobile/features/support/data/support_service.dart';

import '../../support/network_fakes.dart';

void main() {
  test('lists and creates only ordinary support tickets', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      expect(options.path, '/support/tickets');
      if (requestIndex == 1) {
        expect(options.method, 'GET');
        return jsonResponse({
          'success': true,
          'data': [supportTicketJson()],
          'error': null,
        });
      }
      expect(options.method, 'POST');
      expect(options.data, {
        'subject': 'Вопрос о профиле',
        'message': 'Не получается изменить имя в профиле.',
      });
      return jsonResponse({
        'success': true,
        'data': supportTicketJson(),
        'error': null,
      });
    });
    final service = SupportService(Dio()..httpClientAdapter = adapter);
    const draft = CreateSupportTicketDraft(
      subject: 'Вопрос о профиле',
      message: 'Не получается изменить имя в профиле.',
    );

    final tickets = await service.listMine();
    final created = await service.create(draft);

    expect(tickets.single.type, 'GENERAL');
    expect(created.id, 'ticket-1');
    expect(adapter.requests, hasLength(2));
  });

  test('lists and sends text messages for one support ticket', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      expect(options.path, '/support/tickets/ticket-1/messages');
      if (requestIndex == 1) {
        expect(options.method, 'GET');
        return jsonResponse({
          'success': true,
          'data': [supportMessageJson()],
          'error': null,
        });
      }
      expect(options.method, 'POST');
      expect(options.data, {
        'body': 'Уточните, пожалуйста, какие данные нужны.',
        'attachmentIntentIds': <String>[],
      });
      return jsonResponse({
        'success': true,
        'data': supportMessageJson(
          id: 'message-2',
          role: 'USER',
          body: 'Уточните, пожалуйста, какие данные нужны.',
        ),
        'error': null,
      });
    });
    final service = SupportService(Dio()..httpClientAdapter = adapter);

    final messages = await service.listMessages('ticket-1');
    final sent = await service.createMessage(
      'ticket-1',
      'Уточните, пожалуйста, какие данные нужны.',
    );

    expect(messages.single.authorRole, 'SUPPORT');
    expect(messages.single.attachments.single.sha256, 'abc123');
    expect(sent.id, 'message-2');
    expect(adapter.requests, hasLength(2));
  });

  test('uploads a private image before sending its intent id', () async {
    var requestIndex = 0;
    final adapter = CallbackAdapter((options) {
      requestIndex += 1;
      if (requestIndex == 1) {
        return jsonResponse({
          'success': true,
          'data': {
            'intentId': 'intent-1',
            'uploadUrl': 'https://storage.test/private-upload',
            'fields': {'key': 'quarantine/evidence.jpg'},
          },
          'error': null,
        });
      }
      if (requestIndex == 2) {
        return ResponseBody.fromString('', 204);
      }
      return jsonResponse({
        'success': true,
        'data': supportMessageJson(
          id: 'message-3',
          role: 'USER',
          body: 'Прикладываю фото повреждения.',
        ),
        'error': null,
      });
    });
    final service = SupportService(Dio()..httpClientAdapter = adapter);
    final file = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'evidence.jpg',
      mimeType: 'image/jpeg',
    );

    final sent = await service.createMessage(
      'ticket-1',
      'Прикладываю фото повреждения.',
      attachments: [file],
    );

    expect(sent.id, 'message-3');
    expect(adapter.requests, hasLength(3));
    expect(adapter.requests[0].path, '/uploads/presigned-url');
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].data, {
      'purpose': 'SUPPORT_ATTACHMENT',
      'supportTicketId': 'ticket-1',
      'fileName': 'support.jpg',
      'contentType': 'image/jpeg',
      'sizeBytes': 3,
    });
    expect(adapter.requests[1].path, 'https://storage.test/private-upload');
    expect(adapter.requests[1].method, 'POST');
    expect(adapter.requests[1].data, isA<FormData>());
    expect(adapter.requests[1].extra['skipAuth'], isTrue);
    expect(adapter.requests[2].path, '/support/tickets/ticket-1/messages');
    expect(adapter.requests[2].method, 'POST');
    expect(adapter.requests[2].data, {
      'body': 'Прикладываю фото повреждения.',
      'attachmentIntentIds': ['intent-1'],
    });
  });

  test('accepts only an https private attachment download url', () async {
    final valid = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': {
          'downloadUrl': 'https://storage.test/private?signature=secret',
          'expiresInSeconds': 300,
        },
        'error': null,
      }),
    );
    final invalid = CallbackAdapter(
      (_) => jsonResponse({
        'success': true,
        'data': {
          'downloadUrl': 'http://storage.test/private',
          'expiresInSeconds': 300,
        },
        'error': null,
      }),
    );

    final uri = await SupportService(
      Dio()..httpClientAdapter = valid,
    ).getAttachmentDownloadUri('ticket-1', 'attachment-1');
    final rejected = SupportService(
      Dio()..httpClientAdapter = invalid,
    ).getAttachmentDownloadUri('ticket-1', 'attachment-1');

    expect(uri.scheme, 'https');
    await expectLater(
      rejected,
      throwsA(
        isA<ApiException>().having(
          (error) => error.code,
          'code',
          'INVALID_DOWNLOAD_URL',
        ),
      ),
    );
  });
}

Map<String, Object?> supportTicketJson() => {
  'id': 'ticket-1',
  'type': 'GENERAL',
  'bookingId': null,
  'bookingIssueReason': null,
  'subject': 'Вопрос о профиле',
  'message': 'Не получается изменить имя в профиле.',
  'status': 'OPEN',
  'adminResponse': null,
  'respondedAt': null,
  'createdAt': '2026-07-29T12:00:00.000Z',
  'updatedAt': '2026-07-29T12:00:00.000Z',
};

Map<String, Object?> supportMessageJson({
  String id = 'message-1',
  String role = 'SUPPORT',
  String body = 'Опишите, пожалуйста, что именно не получается.',
}) => {
  'id': id,
  'authorRole': role,
  'body': body,
  'attachments': [
    {
      'id': 'attachment-1',
      'sha256': 'abc123',
      'createdAt': '2026-07-29T12:05:00.000Z',
    },
  ],
  'createdAt': '2026-07-29T12:05:00.000Z',
};
