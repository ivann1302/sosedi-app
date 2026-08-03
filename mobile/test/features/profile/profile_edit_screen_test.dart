import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/profile/presentation/profile_edit_screen.dart';

void main() {
  testWidgets('edits name and city then returns to the profile', (tester) async {
    final service = _FakeProfileService();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/profile/edit'),
              child: const Text('Редактировать'),
            ),
          ),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const ProfileEditScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async => profile),
          profileServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Редактировать'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('profile-name-field')),
      'Мария',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-city-field')),
      'Казань',
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(service.savedName, 'Мария');
    expect(service.savedCity, 'Казань');
    expect(find.text('Редактировать'), findsOneWidget);
  });
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService() : super(Dio());

  String? savedName;
  String? savedCity;

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String city,
  }) async {
    savedName = name;
    savedCity = city;
    return profile.copyWith(name: name, city: city);
  }

  @override
  Future<String> replaceAvatar(XFile file) async {
    return 'https://cdn.test/avatar.webp';
  }
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
