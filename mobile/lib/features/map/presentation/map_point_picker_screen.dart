import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/location/location_service.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../data/yandex_tiles.dart';

const GeoPoint _moscow = (latitude: 55.7558, longitude: 37.6173);
final _yandexMapsUri = Uri.parse('https://yandex.ru/maps/');

Future<GeoPoint?> openMapPointPicker(
  BuildContext context,
  GeoPoint? initialPoint, {
  required String apiKey,
}) {
  return Navigator.of(context).push<GeoPoint>(
    MaterialPageRoute(
      builder: (_) =>
          MapPointPickerScreen(initialPoint: initialPoint, apiKey: apiKey),
    ),
  );
}

class MapPointPickerScreen extends ConsumerStatefulWidget {
  const MapPointPickerScreen({
    required this.initialPoint,
    required this.apiKey,
    super.key,
  });

  final GeoPoint? initialPoint;
  final String apiKey;

  @override
  ConsumerState<MapPointPickerScreen> createState() =>
      _MapPointPickerScreenState();
}

class _MapPointPickerScreenState extends ConsumerState<MapPointPickerScreen> {
  final _mapController = MapController();
  GeoPoint? _selectedPoint;
  var _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    final initialPoint = widget.initialPoint ?? _moscow;
    return Scaffold(
      appBar: AppBar(title: const Text('Точка передачи')),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _toLatLng(initialPoint),
                initialZoom: widget.initialPoint == null ? 10 : 16,
                minZoom: 2,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, point) => _selectPoint(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: buildYandexTileUrlTemplate(widget.apiKey),
                  userAgentPackageName: 'ru.sosedi.app',
                  maxZoom: 19,
                  tileProvider: NetworkTileProvider(
                    headers: {'Referer': yandexTilesReferer},
                    cachingProvider: const DisabledMapCachingProvider(),
                  ),
                ),
                if (_selectedPoint case final point?)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _toLatLng(point),
                        width: 48,
                        height: 48,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_pin,
                          size: 48,
                          color: Color(0xFFFF5C00),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Semantics(
              button: true,
              label: 'Открыть Яндекс Карты',
              child: InkWell(
                onTap: () => launchUrl(
                  _yandexMapsUri,
                  mode: LaunchMode.externalApplication,
                ),
                child: Image.asset(
                  'assets/images/yandex_maps_logo_ru.png',
                  height: 48,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Коснитесь карты, чтобы поставить точку передачи.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLocating ? null : _useCurrentLocation,
                        icon: _isLocating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Моё местоположение'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _selectedPoint == null
                            ? null
                            : () => Navigator.of(context).pop(_selectedPoint),
                        child: const Text('Выбрать это место'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPoint(LatLng point) {
    setState(() {
      _selectedPoint = (latitude: point.latitude, longitude: point.longitude);
    });
  }

  Future<void> _useCurrentLocation() async {
    final allowed = await requestPermissionFromUserAction(
      context: context,
      ref: ref,
      permission: AppPermission.location,
    );
    if (!allowed || !mounted) {
      return;
    }
    setState(() => _isLocating = true);
    try {
      final point = await ref.read(locationServiceProvider).currentPosition();
      if (!mounted) {
        return;
      }
      _selectPoint(_toLatLng(point));
      _mapController.move(_toLatLng(point), 16);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось определить местоположение')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  LatLng _toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);
}
