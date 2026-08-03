import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/marketplace_documents_config.dart';
import 'package:mobile/features/profile/presentation/documents_screen.dart';

void main() {
  testWidgets('keeps unpublished document drafts hidden', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DocumentsScreen()),
      ),
    );

    expect(find.text('Документы готовятся к публикации'), findsOneWidget);
    expect(find.textContaining('Оферта ·'), findsNothing);
  });

  testWidgets('opens only the configured exact document URL', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketplaceDocumentsConfigProvider.overrideWithValue(documents),
          externalDocumentOpenerProvider.overrideWithValue((uri) async {
            opened = uri;
            return true;
          }),
        ],
        child: const MaterialApp(home: DocumentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Оферта · 2026-08-01.1'));
    await tester.pump();

    expect(opened, documents.offerUri);
  });
}

const documents = MarketplaceDocumentsConfig(
  offerVersion: '2026-08-01.1',
  offerUrl: 'https://docs.sosedi.ru/documents/offer/2026-08-01.1/',
  cancellationPolicyVersion: '2026-08-01.2',
  rentalRulesUrl:
      'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.2/',
  privacyVersion: '2026-08-01.3',
  privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
);
