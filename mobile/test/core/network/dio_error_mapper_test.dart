import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/dio_error_mapper.dart';

void main() {
  final request = RequestOptions(path: '/items');

  test('distinguishes offline and timeout failures', () {
    final offline = apiExceptionFromDio(
      DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      ),
      fallback: 'Ошибка',
    );
    final timeout = apiExceptionFromDio(
      DioException(
        requestOptions: request,
        type: DioExceptionType.receiveTimeout,
      ),
      fallback: 'Ошибка',
    );

    expect(offline.code, 'OFFLINE');
    expect(offline.message, 'Нет подключения к интернету');
    expect(timeout.code, 'TIMEOUT');
    expect(timeout.message, contains('слишком долго'));
  });

  test('keeps a safe server envelope error', () {
    final exception = apiExceptionFromDio(
      DioException.badResponse(
        statusCode: 409,
        requestOptions: request,
        response: Response<Map<String, dynamic>>(
          requestOptions: request,
          statusCode: 409,
          data: {
            'success': false,
            'data': null,
            'error': {
              'code': 'CALENDAR_CONFLICT',
              'message': 'Даты уже заняты',
            },
          },
        ),
      ),
      fallback: 'Ошибка',
    );

    expect(exception.code, 'CALENDAR_CONFLICT');
    expect(exception.message, 'Даты уже заняты');
  });
}
