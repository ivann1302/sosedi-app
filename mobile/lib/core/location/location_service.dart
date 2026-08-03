import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../network/api_exception.dart';

typedef GeoPoint = ({double latitude, double longitude});

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

class LocationService {
  const LocationService();

  Future<GeoPoint> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const ApiException(
          code: 'LOCATION_DISABLED',
          message: 'Включите геолокацию, чтобы искать вещи рядом',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        code: 'LOCATION_TIMEOUT',
        message: 'Не удалось определить геопозицию. Попробуйте ещё раз',
      );
    } catch (_) {
      throw const ApiException(
        code: 'LOCATION_UNAVAILABLE',
        message: 'Не удалось определить геопозицию',
      );
    }
  }
}
