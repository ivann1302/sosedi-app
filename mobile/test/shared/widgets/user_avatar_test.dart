import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/widgets/user_avatar.dart';

void main() {
  testWidgets('loads an allowlisted pilot avatar from bundled assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserAvatar(
          avatarUrl: 'asset:///assets/images/mock_users/anna.png',
          name: 'Анна',
        ),
      ),
    );

    final avatar = tester.widget<Image>(find.byType(Image));
    expect(tester.getSize(find.byType(ClipOval)), const Size.square(72));
    expect(
      avatar.image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'assetName',
        'assets/images/mock_users/anna.png',
      ),
    );
  });

  testWidgets('uses a network provider for ordinary avatar URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserAvatar(
          avatarUrl: 'https://cdn.example/avatar.webp',
          name: 'Анна',
        ),
      ),
    );

    final avatar = tester.widget<Image>(find.byType(Image));
    expect(
      avatar.image,
      isA<NetworkImage>().having(
        (image) => image.url,
        'url',
        'https://cdn.example/avatar.webp',
      ),
    );
  });
}
