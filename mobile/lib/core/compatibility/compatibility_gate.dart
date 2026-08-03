import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final compatibilityRequirementProvider =
    NotifierProvider<CompatibilityController, UpdateRequirement?>(
      CompatibilityController.new,
    );

class CompatibilityController extends Notifier<UpdateRequirement?> {
  @override
  UpdateRequirement? build() => null;

  void requireUpdate(UpdateRequirement requirement) {
    state = requirement;
  }
}

class UpdateRequirement {
  const UpdateRequirement({
    required this.code,
    required this.message,
    required this.minimumVersion,
    this.updateUrl,
  });

  final String code;
  final String message;
  final String minimumVersion;
  final Uri? updateUrl;

  static UpdateRequirement? fromResponse(Response<dynamic>? response) {
    if (response?.statusCode != 426) {
      return null;
    }

    final body = response?.data;
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final error = body['error'];
    if (error is! Map<String, dynamic>) {
      return null;
    }
    final code = error['code'];
    final message = error['message'];
    if ((code != 'MOBILE_UPDATE_REQUIRED' &&
            code != 'API_VERSION_UNSUPPORTED') ||
        message is! String) {
      return null;
    }

    final minimumVersion =
        response?.headers.value('X-Min-Mobile-Version') ?? '';
    final rawUrl = response?.headers.value('X-Mobile-Update-Url');
    final parsedUrl = rawUrl == null ? null : Uri.tryParse(rawUrl);
    final updateUrl = parsedUrl != null && parsedUrl.scheme == 'https'
        ? parsedUrl
        : null;

    return UpdateRequirement(
      code: code as String,
      message: message,
      minimumVersion: minimumVersion,
      updateUrl: updateUrl,
    );
  }
}
