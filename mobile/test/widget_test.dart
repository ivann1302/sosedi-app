import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_provider.dart';
import 'package:mobile/core/storage/onboarding_storage.dart';
import 'package:mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows onboarding on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          apiCompatibilityCheckProvider.overrideWith((ref) async {}),
        ],
        child: const SosediApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Всё рядом'), findsWidgets);
    expect(find.text('Соседи'), findsNothing);
    expect(find.text('Войти по SMS'), findsNothing);
  });
}
