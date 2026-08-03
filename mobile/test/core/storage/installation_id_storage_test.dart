import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/installation_id_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates one stable UUID v4 for the app installation', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final firstStorage = InstallationIdStorage(preferences);

    final first = await firstStorage.getOrCreate();
    final repeated = await firstStorage.getOrCreate();
    final restored = await InstallationIdStorage(preferences).getOrCreate();

    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(repeated, first);
    expect(restored, first);
  });
}
