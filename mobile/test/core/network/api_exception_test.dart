import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';

void main() {
  test('shows safe API messages and hides unexpected error details', () {
    const apiError = ApiException(
      code: 'CATALOG_UNAVAILABLE',
      message: 'Каталог временно недоступен',
    );

    expect(
      userFacingError(apiError, fallback: 'Повторите позже'),
      'Каталог временно недоступен',
    );
    expect(apiError.toString(), 'Каталог временно недоступен');
    expect(
      userFacingError(
        Exception('database.internal:5432'),
        fallback: 'Повторите позже',
      ),
      'Повторите позже',
    );
  });
}
