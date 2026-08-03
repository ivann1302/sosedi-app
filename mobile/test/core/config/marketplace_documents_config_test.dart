import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/marketplace_documents_config.dart';

void main() {
  test('accepts only matching versioned HTTPS marketplace documents', () {
    const config = MarketplaceDocumentsConfig(
      offerVersion: '2026-08-01.1',
      offerUrl: 'https://docs.sosedi.ru/documents/offer/2026-08-01.1/',
      cancellationPolicyVersion: '2026-08-01.2',
      rentalRulesUrl:
          'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.2/',
      privacyVersion: '2026-08-01.3',
      privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
    );

    expect(config.isBookingReady, isTrue);
    expect(config.isPublishedSetReady, isTrue);
    expect(config.offerUri?.host, 'docs.sosedi.ru');
    expect(config.rentalRulesUri?.host, 'docs.sosedi.ru');
  });

  test('rejects draft, insecure and version-mismatched documents', () {
    const draft = MarketplaceDocumentsConfig(
      offerVersion: 'draft-2026-08-01',
      offerUrl: 'https://docs.sosedi.ru/documents/offer/draft-2026-08-01/',
      cancellationPolicyVersion: '2026-08-01.1',
      rentalRulesUrl:
          'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.1/',
      privacyVersion: '2026-08-01.3',
      privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
    );
    const insecure = MarketplaceDocumentsConfig(
      offerVersion: '2026-08-01.1',
      offerUrl: 'http://docs.sosedi.ru/documents/offer/2026-08-01.1/',
      cancellationPolicyVersion: '2026-08-01.1',
      rentalRulesUrl:
          'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.1/',
      privacyVersion: '2026-08-01.3',
      privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
    );
    const mismatch = MarketplaceDocumentsConfig(
      offerVersion: '2026-08-01.1',
      offerUrl: 'https://docs.sosedi.ru/documents/offer/2026-07-01.1/',
      cancellationPolicyVersion: '2026-08-01.1',
      rentalRulesUrl:
          'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.1/',
      privacyVersion: '2026-08-01.3',
      privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
    );

    expect(draft.isBookingReady, isFalse);
    expect(insecure.isBookingReady, isFalse);
    expect(mismatch.isBookingReady, isFalse);
  });

  test('rejects loopback, IP and reserved document hosts', () {
    for (final host in ['localhost', '127.0.0.1', 'docs.sosedi.test']) {
      final config = MarketplaceDocumentsConfig(
        offerVersion: '2026-08-01.1',
        offerUrl: 'https://$host/documents/offer/2026-08-01.1/',
        cancellationPolicyVersion: '2026-08-01.2',
        rentalRulesUrl: 'https://$host/documents/rental-rules/2026-08-01.2/',
        privacyVersion: '2026-08-01.3',
        privacyUrl: 'https://$host/documents/privacy/2026-08-01.3/',
      );

      expect(config.isPublishedSetReady, isFalse);
    }
  });
}
