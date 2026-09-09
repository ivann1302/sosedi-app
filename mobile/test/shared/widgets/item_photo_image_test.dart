import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/widgets/item_photo_image.dart';

void main() {
  testWidgets('loads an allowlisted pilot photo from bundled assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ItemPhotoImage(
          source: 'asset:///assets/images/mock_items/projector.jpg',
          semanticLabel: 'Фото проектора',
          fit: BoxFit.cover,
        ),
      ),
    );

    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'assetName',
        'assets/images/mock_items/projector.jpg',
      ),
    );
  });

  testWidgets('keeps ordinary item photos on the network provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ItemPhotoImage(
          source: 'https://cdn.example/item.jpg',
          semanticLabel: 'Фото вещи',
          fit: BoxFit.cover,
        ),
      ),
    );

    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<NetworkImage>().having(
        (image) => image.url,
        'url',
        'https://cdn.example/item.jpg',
      ),
    );
  });
}
