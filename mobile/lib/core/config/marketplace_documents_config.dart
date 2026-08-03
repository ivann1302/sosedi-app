import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'production_url.dart';

final marketplaceDocumentsConfigProvider = Provider<MarketplaceDocumentsConfig>(
  (ref) {
    return MarketplaceDocumentsConfig.fromEnvironment();
  },
);

class MarketplaceDocumentsConfig {
  const MarketplaceDocumentsConfig({
    required this.offerVersion,
    required this.offerUrl,
    required this.cancellationPolicyVersion,
    required this.rentalRulesUrl,
    required this.privacyVersion,
    required this.privacyUrl,
  });

  factory MarketplaceDocumentsConfig.fromEnvironment() {
    return const MarketplaceDocumentsConfig(
      offerVersion: String.fromEnvironment('MARKETPLACE_OFFER_VERSION'),
      offerUrl: String.fromEnvironment('MARKETPLACE_OFFER_URL'),
      cancellationPolicyVersion: String.fromEnvironment(
        'MARKETPLACE_CANCELLATION_POLICY_VERSION',
      ),
      rentalRulesUrl: String.fromEnvironment('MARKETPLACE_RENTAL_RULES_URL'),
      privacyVersion: String.fromEnvironment('MARKETPLACE_PRIVACY_VERSION'),
      privacyUrl: String.fromEnvironment('MARKETPLACE_PRIVACY_URL'),
    );
  }

  final String offerVersion;
  final String offerUrl;
  final String cancellationPolicyVersion;
  final String rentalRulesUrl;
  final String privacyVersion;
  final String privacyUrl;

  Uri? get offerUri => _approvedDocumentUri(offerUrl, offerVersion);

  Uri? get rentalRulesUri =>
      _approvedDocumentUri(rentalRulesUrl, cancellationPolicyVersion);

  Uri? get privacyUri => _approvedDocumentUri(privacyUrl, privacyVersion);

  bool get isBookingReady => offerUri != null && rentalRulesUri != null;

  bool get isPublishedSetReady => isBookingReady && privacyUri != null;

  Uri? _approvedDocumentUri(String rawUrl, String version) {
    if (!_versionPattern.hasMatch(version) ||
        version.toLowerCase().contains('draft')) {
      return null;
    }
    final uri = Uri.tryParse(rawUrl);
    if (!isCleanPublicHttpsUri(uri) || !uri!.pathSegments.contains(version)) {
      return null;
    }
    return uri;
  }

  static final _versionPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$');
}
