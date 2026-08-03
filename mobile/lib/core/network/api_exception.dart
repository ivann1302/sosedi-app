class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => message;
}

String userFacingError(Object error, {required String fallback}) {
  return error is ApiException ? error.message : fallback;
}
