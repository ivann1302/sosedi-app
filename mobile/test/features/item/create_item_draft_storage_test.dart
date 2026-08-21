import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/item/data/create_item_draft_storage.dart';
import 'package:mobile/features/item/data/create_item_models.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('round-trips only the allowlisted listing draft', () async {
    const secureStorage = FlutterSecureStorage();
    final storage = CreateItemDraftStorage(secureStorage);
    const draft = LocalCreateItemDraft(
      step: 1,
      title: 'Дрель',
      description: 'Рабочая дрель',
      pricePerDay: '450',
      publicArea: 'Хамовники',
    );

    await storage.save(draft);

    expect(await storage.load(), draft);
    final values = await secureStorage.readAll();
    expect(values.values.single, isNot(contains('latitude')));
    expect(values.values.single, isNot(contains('address')));

    await storage.clear();
    expect(await storage.load(), isNull);
  });
}
