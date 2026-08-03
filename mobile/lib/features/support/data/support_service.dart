import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'support_models.dart';

final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService(ref.watch(dioProvider));
});

final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>(
  (ref) => ref.watch(supportServiceProvider).listMine(),
  retry: (_, _) => null,
);

final supportTicketProvider = FutureProvider.autoDispose
    .family<SupportTicket, String>((ref, ticketId) async {
      final tickets = await ref.watch(supportTicketsProvider.future);
      return tickets.firstWhere(
        (ticket) => ticket.id == ticketId,
        orElse: () => throw const ApiException(
          code: 'SUPPORT_TICKET_NOT_FOUND',
          message: 'Обращение не найдено',
        ),
      );
    }, retry: (_, _) => null);

final supportMessagesProvider = FutureProvider.autoDispose
    .family<List<SupportMessage>, String>(
      (ref, ticketId) =>
          ref.watch(supportServiceProvider).listMessages(ticketId),
      retry: (_, _) => null,
    );

class SupportService {
  const SupportService(this._dio);

  final Dio _dio;

  Future<List<SupportTicket>> listMine() async {
    final body = await _request(() => _dio.get('/support/tickets'));
    final envelope = ApiEnvelope<List<SupportTicket>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map(
            (ticket) => SupportTicket.fromJson(ticket! as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
    return _data(envelope, 'Не удалось загрузить обращения');
  }

  Future<SupportTicket> create(CreateSupportTicketDraft draft) async {
    final body = await _request(
      () => _dio.post('/support/tickets', data: draft.toJson()),
    );
    final envelope = ApiEnvelope<SupportTicket>.fromJson(
      body,
      (json) => SupportTicket.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось отправить обращение');
  }

  Future<List<SupportMessage>> listMessages(String ticketId) async {
    final body = await _request(
      () => _dio.get('/support/tickets/$ticketId/messages'),
    );
    final envelope = ApiEnvelope<List<SupportMessage>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map(
            (message) =>
                SupportMessage.fromJson(message! as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
    return _data(envelope, 'Не удалось загрузить переписку');
  }

  Future<SupportMessage> createMessage(
    String ticketId,
    String body, {
    List<XFile> attachments = const [],
  }) async {
    if (attachments.length > 3) {
      throw const ApiException(
        code: 'TOO_MANY_ATTACHMENTS',
        message: 'К сообщению можно добавить не больше 3 фото',
      );
    }
    final attachmentIntentIds = <String>[];
    for (final attachment in attachments) {
      attachmentIntentIds.add(
        await _uploadSupportAttachment(ticketId, attachment),
      );
    }
    final response = await _request(
      () => _dio.post(
        '/support/tickets/$ticketId/messages',
        data: {'body': body.trim(), 'attachmentIntentIds': attachmentIntentIds},
      ),
    );
    final envelope = ApiEnvelope<SupportMessage>.fromJson(
      response,
      (json) => SupportMessage.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось отправить сообщение');
  }

  Future<Uri> getAttachmentDownloadUri(
    String ticketId,
    String attachmentId,
  ) async {
    final body = await _request(
      () => _dio.get(
        '/support/tickets/$ticketId/attachments/$attachmentId/download-url',
      ),
    );
    final envelope = ApiEnvelope<_PrivateDownload>.fromJson(
      body,
      (json) => _PrivateDownload.fromJson(json! as Map<String, dynamic>),
    );
    final download = _data(envelope, 'Не удалось открыть вложение');
    final uri = Uri.tryParse(download.downloadUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const ApiException(
        code: 'INVALID_DOWNLOAD_URL',
        message: 'Сервис вернул небезопасную ссылку на вложение',
      );
    }
    return uri;
  }

  Future<String> _uploadSupportAttachment(String ticketId, XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const ApiException(
        code: 'INVALID_FILE_SIZE',
        message: 'Каждое фото должно быть не больше 10 МБ',
      );
    }
    final contentType = _contentType(file);
    final fileName = file.name.isEmpty
        ? 'support.${_extension(contentType)}'
        : file.name;
    final body = await _request(
      () => _dio.post(
        '/uploads/presigned-url',
        data: {
          'purpose': 'SUPPORT_ATTACHMENT',
          'supportTicketId': ticketId,
          'fileName': fileName,
          'contentType': contentType,
          'sizeBytes': bytes.length,
        },
      ),
    );
    final envelope = ApiEnvelope<_PresignedSupportUpload>.fromJson(
      body,
      (json) => _PresignedSupportUpload.fromJson(json! as Map<String, dynamic>),
    );
    final upload = _data(envelope, 'Не удалось начать загрузку вложения');
    try {
      await _dio.post<void>(
        upload.uploadUrl,
        data: FormData.fromMap({
          ...upload.fields,
          'file': MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: DioMediaType.parse(contentType),
          ),
        }),
        options: Options(
          responseType: ResponseType.plain,
          extra: const {'skipAuth': true, 'skipAuthRefresh': true},
        ),
      );
    } on DioException {
      throw const ApiException(
        code: 'ATTACHMENT_UPLOAD_FAILED',
        message: 'Не удалось загрузить вложение',
      );
    }
    return upload.intentId;
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать ответ',
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Поддержка временно недоступна',
      );
    }
  }

  T _data<T>(ApiEnvelope<T> envelope, String fallback) {
    final data = envelope.data;
    if (envelope.success && data != null) {
      return data;
    }
    throw ApiException(
      code: envelope.error?.code ?? 'API_ERROR',
      message: envelope.error?.message ?? fallback,
    );
  }

  String _contentType(XFile file) {
    final declared = file.mimeType;
    if (declared == 'image/jpeg' ||
        declared == 'image/png' ||
        declared == 'image/webp') {
      return declared!;
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (name.endsWith('.png')) {
      return 'image/png';
    }
    if (name.endsWith('.webp')) {
      return 'image/webp';
    }
    throw const ApiException(
      code: 'INVALID_FILE_TYPE',
      message: 'Выберите JPEG, PNG или WebP',
    );
  }

  String _extension(String contentType) => switch (contentType) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => throw const ApiException(
      code: 'INVALID_FILE_TYPE',
      message: 'Выберите JPEG, PNG или WebP',
    ),
  };
}

class _PresignedSupportUpload {
  const _PresignedSupportUpload({
    required this.intentId,
    required this.uploadUrl,
    required this.fields,
  });

  factory _PresignedSupportUpload.fromJson(Map<String, dynamic> json) {
    return _PresignedSupportUpload(
      intentId: json['intentId']! as String,
      uploadUrl: json['uploadUrl']! as String,
      fields: (json['fields']! as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value! as String),
      ),
    );
  }

  final String intentId;
  final String uploadUrl;
  final Map<String, String> fields;
}

class _PrivateDownload {
  const _PrivateDownload({required this.downloadUrl});

  factory _PrivateDownload.fromJson(Map<String, dynamic> json) {
    return _PrivateDownload(downloadUrl: json['downloadUrl']! as String);
  }

  final String downloadUrl;
}
