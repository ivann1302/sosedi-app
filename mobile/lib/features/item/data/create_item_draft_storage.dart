import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'create_item_models.dart';

final createItemDraftStorageProvider = Provider<CreateItemDraftStorage>((ref) {
  return CreateItemDraftStorage();
});

class CreateItemDraftStorage {
  CreateItemDraftStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'listing.safeDraft.v1';

  final FlutterSecureStorage _storage;

  Future<LocalCreateItemDraft?> load() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null) {
      return null;
    }
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic>) {
        return null;
      }
      return LocalCreateItemDraft.fromJson(value);
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  Future<void> save(LocalCreateItemDraft draft) {
    return _storage.write(key: _key, value: jsonEncode(draft.toJson()));
  }

  Future<void> clear() => _storage.delete(key: _key);
}
