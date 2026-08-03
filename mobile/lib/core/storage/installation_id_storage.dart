import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../identifiers/uuid_v4.dart';
import 'onboarding_storage.dart';

final installationIdStorageProvider = Provider<InstallationIdStorage>((ref) {
  return InstallationIdStorage(ref.watch(sharedPreferencesProvider));
});

class InstallationIdStorage {
  InstallationIdStorage(this._preferences);

  static const _key = 'device.installationId';
  final SharedPreferences _preferences;
  Future<String>? _installationId;

  Future<String> getOrCreate() {
    return _installationId ??= _loadOrCreate();
  }

  Future<String> _loadOrCreate() async {
    final stored = _preferences.getString(_key)?.toLowerCase();
    if (stored != null && isUuidV4(stored)) {
      return stored;
    }

    final generated = generateUuidV4();
    await _preferences.setString(_key, generated);
    return generated;
  }
}
