import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_service.dart';

typedef ListingPointPicker =
    Future<GeoPoint?> Function(BuildContext context, GeoPoint? initialPoint);

final listingPointPickerProvider = Provider<ListingPointPicker>((ref) {
  return _showUnavailableMap;
});

Future<GeoPoint?> _showUnavailableMap(
  BuildContext context,
  GeoPoint? initialPoint,
) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Карта временно недоступна. Попробуйте позже.'),
    ),
  );
  return null;
}
