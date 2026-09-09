import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_error_mapper.dart';
import '../../../core/network/dio_provider.dart';
import 'create_item_models.dart';

final createItemServiceProvider = Provider<CreateItemService>((ref) {
  return CreateItemService(ref.watch(dioProvider));
});

class CreateItemService {
  const CreateItemService(this._dio);

  final Dio _dio;

  Future<CreateItemResult> create(
    CreateItemDraft draft, {
    required String requestId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/items',
        data: draft.toJson(),
        options: Options(headers: {'X-Request-Id': requestId}),
      );
      final body = response.data;
      if (body == null) {
        throw const ApiException(
          code: 'INVALID_RESPONSE',
          message: 'Не удалось прочитать объявление',
        );
      }

      final envelope = ApiEnvelope<CreateItemResult>.fromJson(
        body,
        (json) => CreateItemResult.fromJson(json! as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось создать объявление',
      );
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw apiExceptionFromDio(
        error,
        fallback: 'Не удалось создать объявление',
      );
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать объявление',
      );
    }
  }

  Future<void> uploadPhotos(
    String itemId,
    List<XFile> photos, {
    ItemPhotoUploadProgress? progress,
  }) async {
    final batch = progress ?? ItemPhotoUploadProgress();
    for (var index = batch._completed; index < photos.length; index += 1) {
      await _uploadPhoto(
        itemId: itemId,
        file: photos[index],
        sortOrder: index,
        isCover: index == 0,
        progress: batch,
      );
      batch._completed += 1;
      batch._pendingConfirmation = null;
    }
  }

  Future<void> appendPhotos(
    String itemId,
    List<XFile> photos, {
    required int startSortOrder,
  }) async {
    for (var index = 0; index < photos.length; index += 1) {
      await _uploadPhoto(
        itemId: itemId,
        file: photos[index],
        sortOrder: startSortOrder + index,
        isCover: startSortOrder == 0 && index == 0,
      );
    }
  }

  Future<void> _uploadPhoto({
    required String itemId,
    required XFile file,
    required int sortOrder,
    required bool isCover,
    ItemPhotoUploadProgress? progress,
  }) async {
    final pending = progress?._pendingConfirmation;
    if (pending != null) {
      await _confirmPhoto(pending, sortOrder, isCover, progress);
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const ApiException(
        code: 'INVALID_FILE_SIZE',
        message: 'Каждое фото должно быть не больше 10 МБ',
      );
    }
    final contentType = _contentType(file);
    final fileName = file.name.isEmpty
        ? 'item-$sortOrder.${_extension(contentType)}'
        : file.name;

    try {
      final presignResponse = await _dio.post<Map<String, dynamic>>(
        '/uploads/presigned-url',
        data: {
          'purpose': 'ITEM_PHOTO',
          'itemId': itemId,
          'fileName': fileName,
          'contentType': contentType,
          'sizeBytes': bytes.length,
        },
      );
      final upload = _readUpload(presignResponse);

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

      // Keep the intent if the server commits but its response is lost.
      progress?._pendingConfirmation = upload.intentId;
      await _confirmPhoto(upload.intentId, sortOrder, isCover, progress);
    } on ApiException {
      rethrow;
    } on DioException {
      throw const ApiException(
        code: 'PHOTO_UPLOAD_FAILED',
        message: 'Не удалось загрузить фото',
      );
    }
  }

  Future<void> _confirmPhoto(
    String intentId,
    int sortOrder,
    bool isCover,
    ItemPhotoUploadProgress? progress,
  ) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/uploads/item-photos/confirm',
        data: {
          'intentId': intentId,
          'sortOrder': sortOrder,
          'isCover': isCover,
        },
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      // A definitive validation rejection (including expiry) did not commit.
      // Transient/ambiguous failures must keep the same idempotent intent.
      if (error.response?.statusCode == 400 &&
          body is Map<String, dynamic> &&
          body['error'] is Map<String, dynamic> &&
          (body['error'] as Map<String, dynamic>)['code'] ==
              'VALIDATION_ERROR') {
        progress?._pendingConfirmation = null;
      }
      rethrow;
    }
  }

  _PresignedItemUpload _readUpload(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось начать загрузку фото',
      );
    }
    try {
      final envelope = ApiEnvelope<_PresignedItemUpload>.fromJson(
        body,
        (json) => _PresignedItemUpload.fromJson(json! as Map<String, dynamic>),
      );
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Не удалось начать загрузку фото',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось начать загрузку фото',
      );
    }
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

  String _extension(String contentType) {
    return switch (contentType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw const ApiException(
        code: 'INVALID_FILE_TYPE',
        message: 'Выберите JPEG, PNG или WebP',
      ),
    };
  }
}

/// In-memory progress owned by one publication; never persisted in a draft.
class ItemPhotoUploadProgress {
  int _completed = 0;
  String? _pendingConfirmation;
}

class _PresignedItemUpload {
  const _PresignedItemUpload({
    required this.intentId,
    required this.uploadUrl,
    required this.fields,
  });

  factory _PresignedItemUpload.fromJson(Map<String, dynamic> json) {
    return _PresignedItemUpload(
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
