import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'booking_models.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.watch(dioProvider));
});

final myBookingsProvider = FutureProvider.autoDispose<List<ParticipantBooking>>(
  (ref) => ref.watch(bookingServiceProvider).listMine(),
  retry: (_, _) => null,
);

final bookingDetailsProvider = FutureProvider.autoDispose
    .family<ParticipantBooking, String>(
      (ref, id) => ref.watch(bookingServiceProvider).getDetails(id),
      retry: (_, _) => null,
    );

final bookingActsProvider = FutureProvider.autoDispose
    .family<List<BookingAct>, String>(
      (ref, bookingId) => ref.watch(bookingServiceProvider).listActs(bookingId),
      retry: (_, _) => null,
    );

final bookingMessagesProvider = FutureProvider.autoDispose
    .family<BookingMessagePage, String>(
      (ref, bookingId) =>
          ref.watch(bookingServiceProvider).listMessages(bookingId),
      retry: (_, _) => null,
    );

class BookingService {
  const BookingService(this._dio);

  final Dio _dio;

  Future<String> create({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
    required String offerVersion,
    required String cancellationPolicyVersion,
    required String requestId,
  }) async {
    final body = await _post(
      '/bookings',
      data: {
        'itemId': itemId,
        'startDate': _apiDate(startDate),
        'endDate': _apiDate(endDate),
        'offerVersion': offerVersion,
        'cancellationPolicyVersion': cancellationPolicyVersion,
        'offerAccepted': true,
        'rentalRulesAccepted': true,
      },
      options: Options(headers: {'X-Request-Id': requestId}),
      fallback: 'Не удалось отправить заявку',
    );
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(body, (json) {
      if (json is! Map<String, dynamic>) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать созданное бронирование',
        );
      }
      return json;
    });
    final data = _data(envelope, 'Не удалось отправить заявку');
    final id = data['id'];
    if (id is! String || id.isEmpty) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать созданное бронирование',
      );
    }
    return id;
  }

  Future<ItemAvailability> checkAvailability({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final body = await _get(
      '/items/$itemId/availability',
      queryParameters: {
        'startDate': _apiDate(startDate),
        'endDate': _apiDate(endDate),
      },
    );
    final envelope = ApiEnvelope<ItemAvailability>.fromJson(
      body,
      (json) => ItemAvailability.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось проверить доступность');
  }

  Future<List<ParticipantBooking>> listMine() async {
    final body = await _get('/bookings');
    final envelope = ApiEnvelope<List<ParticipantBooking>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map(
            (value) =>
                ParticipantBooking.fromJson(value! as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
    return _data(envelope, 'Не удалось загрузить бронирования');
  }

  Future<ParticipantBooking> getDetails(String id) async {
    final body = await _get('/bookings/$id');
    final envelope = ApiEnvelope<ParticipantBooking>.fromJson(
      body,
      (json) => ParticipantBooking.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось загрузить бронирование');
  }

  Future<BookingMessagePage> listMessages(
    String bookingId, {
    String? cursor,
    int limit = 50,
  }) async {
    final queryParameters = <String, Object?>{'limit': limit};
    if (cursor case final cursor?) {
      queryParameters['cursor'] = cursor;
    }
    final body = await _get(
      '/bookings/$bookingId/messages',
      queryParameters: queryParameters,
    );
    final envelope = ApiEnvelope<BookingMessagePage>.fromJson(
      body,
      (json) => BookingMessagePage.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось загрузить сообщения');
  }

  Future<BookingMessage> sendMessage({
    required String bookingId,
    required String body,
    required String clientMessageId,
  }) async {
    final response = await _post(
      '/bookings/$bookingId/messages',
      data: {'body': body.trim(), 'clientMessageId': clientMessageId},
      fallback: 'Не удалось отправить сообщение',
    );
    final envelope = ApiEnvelope<BookingMessage>.fromJson(
      response,
      (json) => BookingMessage.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось отправить сообщение');
  }

  Future<void> markMessagesRead(String bookingId) async {
    final body = await _patch('/bookings/$bookingId/messages/read');
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
      body,
      (json) => json! as Map<String, dynamic>,
    );
    _data(envelope, 'Не удалось отметить сообщения прочитанными');
  }

  Future<void> blockCounterparty(String bookingId) async {
    final body = await _post(
      '/bookings/$bookingId/messages/block-counterparty',
      fallback: 'Не удалось заблокировать собеседника',
    );
    final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
      body,
      (json) => json! as Map<String, dynamic>,
    );
    _data(envelope, 'Не удалось заблокировать собеседника');
  }

  Future<void> confirm(String id, {required String requestId}) async {
    return _command(
      '/bookings/$id/confirm',
      requestId: requestId,
      fallback: 'Не удалось подтвердить бронирование',
    );
  }

  Future<void> cancel(String id, {required String requestId}) async {
    return _command(
      '/bookings/$id/cancel',
      requestId: requestId,
      fallback: 'Не удалось отменить заявку',
    );
  }

  Future<BookingIssueReceipt> reportIssue({
    required String bookingId,
    required String reason,
    required String details,
  }) async {
    final subject = switch (reason) {
      'OWNER_NO_SHOW' => 'Владелец не пришёл',
      'BORROWER_NO_SHOW' => 'Арендатор не пришёл',
      'ITEM_FAULTY' => 'Вещь неисправна при передаче',
      'EARLY_RETURN' => 'Досрочный возврат',
      'LATE_RETURN' => 'Просроченный возврат',
      'ITEM_DAMAGED' => 'Повреждение вещи',
      'ITEM_LOST' => 'Потеря вещи',
      _ => 'Проблема с бронированием',
    };
    final body = await _post(
      '/support/tickets',
      data: {
        'bookingId': bookingId,
        'bookingIssueReason': reason,
        'subject': subject,
        'message': details.trim(),
      },
      fallback: 'Не удалось отправить обращение',
    );
    final envelope = ApiEnvelope<BookingIssueReceipt>.fromJson(
      body,
      (json) => BookingIssueReceipt.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось отправить обращение');
  }

  Future<List<BookingAct>> listActs(String bookingId) async {
    final body = await _get('/bookings/$bookingId/acts');
    final envelope = ApiEnvelope<List<BookingAct>>.fromJson(
      body,
      (json) => (json! as List<dynamic>)
          .map((value) => BookingAct.fromJson(value! as Map<String, dynamic>))
          .toList(growable: false),
    );
    return _data(envelope, 'Не удалось загрузить акты');
  }

  Future<BookingAct> createAct({
    required String bookingId,
    required String stage,
    required XFile photo,
    HandoverReadinessInput? readiness,
  }) async {
    final intentId = await _uploadBookingEvidence(bookingId, photo);
    final body = await _post(
      '/bookings/$bookingId/acts',
      data: {
        'stage': stage,
        'intentId': intentId,
        if (readiness != null) 'readiness': readiness.toJson(),
      },
      fallback: 'Не удалось создать акт',
    );
    final envelope = ApiEnvelope<BookingAct>.fromJson(
      body,
      (json) => BookingAct.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось создать акт');
  }

  Future<BookingAct> confirmAct({
    required String bookingId,
    required String actId,
    required String requestId,
  }) async {
    final body = await _post(
      '/bookings/$bookingId/acts/$actId/confirm',
      options: Options(headers: {'X-Request-Id': requestId}),
      fallback: 'Не удалось подтвердить акт',
    );
    final envelope = ApiEnvelope<BookingAct>.fromJson(
      body,
      (json) => BookingAct.fromJson(json! as Map<String, dynamic>),
    );
    return _data(envelope, 'Не удалось подтвердить акт');
  }

  Future<Uri> getEvidenceDownloadUri(
    String bookingId,
    String evidenceId,
  ) async {
    final body = await _get(
      '/bookings/$bookingId/evidence/$evidenceId/download-url',
    );
    final envelope = ApiEnvelope<_PrivateDownload>.fromJson(
      body,
      (json) => _PrivateDownload.fromJson(json! as Map<String, dynamic>),
    );
    final download = _data(envelope, 'Не удалось открыть снимок');
    final uri = Uri.tryParse(download.downloadUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const ApiException(
        code: 'INVALID_DOWNLOAD_URL',
        message: 'Сервис вернул небезопасную ссылку на снимок',
      );
    }
    return uri;
  }

  Future<String> _uploadBookingEvidence(String bookingId, XFile photo) async {
    final bytes = await photo.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const ApiException(
        code: 'INVALID_FILE_SIZE',
        message: 'Снимок должен быть не больше 10 МБ',
      );
    }
    final contentType = _contentType(photo);
    final fileName = photo.name.isEmpty
        ? 'booking-evidence.${_extension(contentType)}'
        : photo.name;
    final body = await _post(
      '/uploads/presigned-url',
      data: {
        'purpose': 'BOOKING_EVIDENCE',
        'bookingId': bookingId,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': bytes.length,
      },
      fallback: 'Не удалось начать загрузку снимка',
    );
    final envelope = ApiEnvelope<_PresignedBookingUpload>.fromJson(
      body,
      (json) => _PresignedBookingUpload.fromJson(json! as Map<String, dynamic>),
    );
    final upload = _data(envelope, 'Не удалось начать загрузку снимка');
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
        code: 'EVIDENCE_UPLOAD_FAILED',
        message: 'Не удалось загрузить снимок',
      );
    }
    return upload.intentId;
  }

  Future<void> _command(
    String path, {
    required String requestId,
    required String fallback,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        options: Options(headers: {'X-Request-Id': requestId}),
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw ApiException(code: 'INVALID_RESPONSE', message: fallback);
      }
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _dioException(error, fallback);
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
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
      throw _dioException(error, 'Не удалось загрузить данные');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Object? data,
    Options? options,
    required String fallback,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: options,
      );
      final body = response.data;
      if (body == null) {
        throw ApiException(code: 'INVALID_RESPONSE', message: fallback);
      }
      return body;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _dioException(error, fallback);
    }
  }

  Future<Map<String, dynamic>> _patch(String path) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(path);
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
      throw _dioException(error, 'Не удалось обновить данные');
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

  ApiException _dioException(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final apiError = data['error'];
      if (apiError is Map<String, dynamic>) {
        return ApiException(
          code: apiError['code']?.toString() ?? 'API_ERROR',
          message: apiError['message']?.toString() ?? fallback,
        );
      }
    }
    return apiExceptionFromDio(error, fallback: fallback);
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

class _PresignedBookingUpload {
  const _PresignedBookingUpload({
    required this.intentId,
    required this.uploadUrl,
    required this.fields,
  });

  factory _PresignedBookingUpload.fromJson(Map<String, dynamic> json) {
    return _PresignedBookingUpload(
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

String _apiDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
