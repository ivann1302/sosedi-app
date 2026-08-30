import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets(
    'shows only the authenticated profile and opens grouped destinations',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: '/profile/favorites',
            builder: (_, _) =>
                const Scaffold(body: Text('Избранное назначение')),
          ),
          GoRoute(
            path: '/support',
            builder: (_, _) =>
                const Scaffold(body: Text('Поддержка назначение')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileProvider.overrideWith((ref) async => profile)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Анна'), findsOneWidget);
      expect(find.text('Москва'), findsOneWidget);
      expect(find.text('Аккаунт активен'), findsOneWidget);
      expect(find.text('Личность подтверждена'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-navigation-group')),
        findsOneWidget,
      );
      expect(find.text('Избранное'), findsOneWidget);
      expect(find.text('Устройства и сессии'), findsOneWidget);
      expect(find.text('Правила и документы'), findsOneWidget);
      expect(find.text('Поддержка'), findsOneWidget);
      expect(find.text('Экспортировать мои данные'), findsOneWidget);
      expect(find.text('Заблокированные пользователи'), findsOneWidget);

      await tester.ensureVisible(find.text('Избранное'));
      await tester.tap(find.text('Избранное'));
      await tester.pumpAndSettle();
      expect(find.text('Избранное назначение'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Поддержка'));
      await tester.tap(find.text('Поддержка'));
      await tester.pumpAndSettle();
      expect(find.text('Поддержка назначение'), findsOneWidget);
    },
  );

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
