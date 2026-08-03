import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('shows only the authenticated user profile and statuses', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((ref) async => profile)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Анна'), findsOneWidget);
    expect(find.text('Москва'), findsOneWidget);
    expect(find.text('Аккаунт активен'), findsOneWidget);
    expect(find.text('Личность подтверждена'), findsOneWidget);
    expect(find.text('Поддержка'), findsOneWidget);
  });

  testWidgets('retries profile loading after an error', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) {
              throw Exception('offline');
            }
            return profile;
          }),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить профиль'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Анна'), findsOneWidget);
  });
}

final profile = UserProfile(
  id: 'user-1',
  phone: '+79991234567',
  name: 'Анна',
  city: 'Москва',
  avatarUrl: null,
  role: 'USER',
  kycStatus: 'VERIFIED',
  isBlocked: false,
  createdAt: DateTime.utc(2026, 7),
  updatedAt: DateTime.utc(2026, 7, 28),
);
