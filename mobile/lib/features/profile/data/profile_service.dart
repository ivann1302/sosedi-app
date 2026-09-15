import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_models.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/data/auth_models.dart';
import 'profile_models.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(dioProvider));
});

final profileProvider = FutureProvider.autoDispose<UserProfile>(
  (ref) => ref.watch(profileServiceProvider).fetchProfile(),
  retry: (_, _) => null,
);

class ProfileService {
  const ProfileService(this._dio);

  final Dio _dio;

  Future<UserProfile> fetchProfile() {
    return _profileRequest(() => _dio.get<Map<String, dynamic>>('/users/me'));
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String city,
  }) {
    return _profileRequest(
      () => _dio.patch<Map<String, dynamic>>(
        '/users/me',
        data: {'name': name, 'city': city},
      ),
    );
  }

  Future<String> replaceAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const ApiException(
        code: 'INVALID_FILE_SIZE',
        message: 'Фото должно быть не больше 10 МБ',
      );
    }
    final contentType = _contentType(bytes, file);
    final fileName = 'avatar.${_extension(contentType)}';

    try {
      final presignResponse = await _dio.post<Map<String, dynamic>>(
        '/uploads/presigned-url',
        data: {
          'purpose': 'AVATAR',
          'fileName': fileName,
          'contentType': contentType,
          'sizeBytes': bytes.length,
        },
      );
      final upload = _readData(
        presignResponse,
        (json) => PresignedAvatarUpload.fromJson(json! as Map<String, dynamic>),
      );

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

      final confirmResponse = await _dio.post<Map<String, dynamic>>(
        '/uploads/avatars/confirm',
        data: {'intentId': upload.intentId},
      );
      return _readData(
        confirmResponse,
        (json) => AvatarUploadResult.fromJson(json! as Map<String, dynamic>),
      ).avatarUrl;
    } on ApiException {
      rethrow;
    } on DioException {
      throw const ApiException(
        code: 'AVATAR_UPLOAD_FAILED',
        message: 'Не удалось загрузить фото',
      );
    }
  }

  Future<AccountClosureResult> closeAccount() async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('/users/me');
      return _readData(
        response,
        (json) => AccountClosureResult.fromJson(json! as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } on DioException {
      throw const ApiException(
        code: 'ACCOUNT_CLOSURE_FAILED',
        message: 'Не удалось отправить запрос',
      );
    }
  }

  Future<OtpRequestResult> requestDataExportOtp() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/step-up/data-export/otp/request',
      );
      return _readData(
        response,
        (json) => OtpRequestResult.fromJson(json! as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } on DioException {
      throw const ApiException(
        code: 'DATA_EXPORT_OTP_FAILED',
        message: 'Не удалось отправить код',
      );
    }
  }

  Future<UserStepUpResult> verifyDataExportOtp(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/step-up/data-export/otp/verify',
        data: {'code': code},
        options: Options(extra: const {'skipAuthRefresh': true}),
      );
      return _readData(
        response,
        (json) => UserStepUpResult.fromJson(json! as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } on DioException {
      throw const ApiException(
        code: 'DATA_EXPORT_OTP_INVALID',
        message: 'Не удалось подтвердить код',
      );
    }
  }

  Future<UserDataExport> createDataExport(String stepUpToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/users/me/data-export',
        data: {'stepUpToken': stepUpToken},
        options: Options(extra: const {'skipAuthRefresh': true}),
      );
      return _readData(
        response,
        (json) => UserDataExport.fromJson(json! as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } on DioException {
      throw const ApiException(
        code: 'DATA_EXPORT_FAILED',
        message: 'Не удалось подготовить экспорт',
      );
    }
  }

  Future<UserProfile> _profileRequest(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return _readData(
        await request(),
        (json) => UserProfile.fromJson(json! as Map<String, dynamic>),
      );
    } on ApiException {
      rethrow;
    } on DioException {
      throw const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Не удалось загрузить профиль',
      );
    }
  }

  T _readData<T>(
    Response<Map<String, dynamic>> response,
    T Function(Object?) fromJsonT,
  ) {
    final body = response.data;
    if (body == null) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать ответ сервера',
      );
    }

    try {
      final envelope = ApiEnvelope<T>.fromJson(body, fromJsonT);
      final data = envelope.data;
      if (envelope.success && data != null) {
        return data;
      }
      throw ApiException(
        code: envelope.error?.code ?? 'API_ERROR',
        message: envelope.error?.message ?? 'Ошибка сервера',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Не удалось прочитать ответ сервера',
      );
    }
  }

  String _contentType(Uint8List bytes, XFile file) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

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
