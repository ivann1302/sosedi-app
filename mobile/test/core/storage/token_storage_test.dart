import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves, reads and clears auth tokens', () async {
    FlutterSecureStorage.setMockInitialValues({});

    final storage = TokenStorage();

    await storage.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    expect(await storage.readAccessToken(), 'access-token');
    expect(await storage.readRefreshToken(), 'refresh-token');

    await storage.clear();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });
}
