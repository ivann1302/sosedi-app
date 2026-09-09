import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/item_photo_image.dart';
import '../../catalog/data/catalog_models.dart';
import '../data/yandex_tiles.dart';

final _yandexMapsUri = Uri.parse('https://yandex.ru/maps/');

class CatalogMap extends StatefulWidget {
  const CatalogMap({
    required this.items,
    required this.selectedItemId,
    required this.onItemSelected,
    required this.apiKey,
    this.tileProvider,
    super.key,
  });

  final List<CatalogItem> items;
  final String? selectedItemId;
  final ValueChanged<String?> onItemSelected;
  final String apiKey;
  final TileProvider? tileProvider;

  @override
  State<CatalogMap> createState() => _CatalogMapState();
}

class _CatalogMapState extends State<CatalogMap> {
  static const _maxZoom = 19.0;

  final MapController _mapController = MapController();
  Set<String> _expandedItemIds = const {};
  late final TileProvider _tileProvider =
      widget.tileProvider ??
      NetworkTileProvider(
        headers: {'Referer': yandexTilesReferer},
        cachingProvider: const DisabledMapCachingProvider(),
      );

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items
        .where((item) => item.id == widget.selectedItemId)
        .firstOrNull;
    final points = widget.items.map(_pointOf).toList(growable: false);

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.fromLTRB(48, 104, 48, 48),
                  maxZoom: 15,
                ),
                minZoom: 2,
                maxZoom: _maxZoom,
                onTap: (_, _) => widget.onItemSelected(null),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: buildYandexTileUrlTemplate(widget.apiKey),
                  userAgentPackageName: 'ru.sosedi.app',
                  maxZoom: _maxZoom,
                  tileProvider: _tileProvider,
                ),
                _CatalogMarkerLayer(
                  items: widget.items,
                  expandedItemIds: _expandedItemIds,
                  onItemSelected: widget.onItemSelected,
                  onClusterSelected: _expandCluster,
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
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
                  height: 40,
                ),
              ),
            ),
          ),
          const Positioned(left: 112, right: 12, top: 12, child: _Notice()),
          if (selectedItem != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _SelectedItemCard(
                key: ValueKey('catalog-map-selected-${selectedItem.id}'),
                item: selectedItem,
                onClose: () => widget.onItemSelected(null),
              ),
            ),
        ],
      ),
    );
  }

  void _expandCluster(List<CatalogItem> items) {
    final center = _centerOf(items);
    final nextZoom = math.min(_mapController.camera.zoom + 2, _maxZoom);
    _mapController.move(center, nextZoom);
    setState(() {
      _expandedItemIds = items.map((item) => item.id).toSet();
    });
  }
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.small),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Адреса указаны приблизительно',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedItemCard extends StatelessWidget {
  const _SelectedItemCard({
    required this.item,
    required this.onClose,
    super.key,
  });

  final CatalogItem item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cover =
        item.photos.where((photo) => photo.isCover).firstOrNull ??
        item.photos.firstOrNull;
    final coverUrl = cover?.thumbnailUrl ?? cover?.previewUrl;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: 'Открыть объявление ${item.title}',
        child: InkWell(
          onTap: () => context.push('/items/${item.id}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.small),
                    child: coverUrl == null
                        ? const ItemPhotoPlaceholder()
                        : ItemPhotoImage(
                            source: coverUrl,
                            semanticLabel: 'Фото ${item.title}',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_price(item.pricePerDay)} ₽ / день',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        item.area,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Закрыть карточку',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

class _CatalogMarkerLayer extends StatelessWidget {
  const _CatalogMarkerLayer({
    required this.items,
    required this.expandedItemIds,
    required this.onItemSelected,
    required this.onClusterSelected,
  });

  static const _clusterRadius = 56.0;

  final List<CatalogItem> items;
  final Set<String> expandedItemIds;
  final ValueChanged<String?> onItemSelected;
  final ValueChanged<List<CatalogItem>> onClusterSelected;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final expanded = items
        .where((item) => expandedItemIds.contains(item.id))
        .toList(growable: false);
    final remaining = items
        .where((item) => !expandedItemIds.contains(item.id))
        .toList(growable: false);
    final markers = <Marker>[
      for (final cluster in _clusters(remaining, camera))
        if (cluster.items.length == 1)
          _itemMarker(cluster.items.single, _pointOf(cluster.items.single))
        else
          _clusterMarker(cluster),
      ..._expandedMarkers(expanded, camera),
    ];

    return MarkerLayer(markers: markers);
  }

  Marker _itemMarker(CatalogItem item, LatLng point) {
    return Marker(
      point: point,
      width: 48,
      height: 48,
      child: Semantics(
        button: true,
        label: 'Выбрать ${item.title} на карте',
        child: IconButton.filled(
          key: ValueKey('catalog-map-marker-${item.id}'),
          onPressed: () => onItemSelected(item.id),
          tooltip: item.title,
          icon: const Icon(Icons.location_on),
        ),
      ),
    );
  }

  Marker _clusterMarker(_MapCluster cluster) {
    final count = cluster.items.length;
    return Marker(
      point: cluster.center,
      width: 56,
      height: 56,
      child: Semantics(
        button: true,
        label: 'Показать $count вещей',
        child: Material(
          key: ValueKey('catalog-map-cluster-$count'),
          color: AppColors.brand500,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onClusterSelected(cluster.items),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.ink900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _expandedMarkers(List<CatalogItem> expanded, MapCamera camera) {
    if (expanded.isEmpty) return const [];
    final center = _centerOf(expanded);
    final projectedCenter = camera.projectAtZoom(center);
    final radius = expanded.length < 5 ? 52.0 : 70.0;
    return [
      for (var index = 0; index < expanded.length; index += 1)
        _itemMarker(
          expanded[index],
          camera.unprojectAtZoom(
            projectedCenter +
                Offset.fromDirection(
                  -math.pi / 2 + 2 * math.pi * index / expanded.length,
                  radius,
                ),
          ),
        ),
    ];
  }

  List<_MapCluster> _clusters(List<CatalogItem> values, MapCamera camera) {
    final result = <_MapCluster>[];
    for (final item in values) {
      final screenPoint = camera.getOffsetFromOrigin(_pointOf(item));
      final match = result
          .where(
            (cluster) =>
                (cluster.screenCenter - screenPoint).distance <= _clusterRadius,
          )
          .firstOrNull;
      if (match == null) {
        result.add(_MapCluster(item, screenPoint));
      } else {
        match.add(item, screenPoint);
      }
    }
    return result;
  }
}

class _MapCluster {
  _MapCluster(CatalogItem item, Offset screenPoint)
    : items = [item],
      _screenTotal = screenPoint,
      _latitudeTotal = item.approximateLocation.latitude,
      _longitudeTotal = item.approximateLocation.longitude;

  final List<CatalogItem> items;
  Offset _screenTotal;
  double _latitudeTotal;
  double _longitudeTotal;

  Offset get screenCenter => _screenTotal / items.length.toDouble();

  LatLng get center =>
      LatLng(_latitudeTotal / items.length, _longitudeTotal / items.length);

  void add(CatalogItem item, Offset screenPoint) {
    items.add(item);
    _screenTotal += screenPoint;
    _latitudeTotal += item.approximateLocation.latitude;
    _longitudeTotal += item.approximateLocation.longitude;
  }
}

LatLng _pointOf(CatalogItem item) => LatLng(
  item.approximateLocation.latitude,
  item.approximateLocation.longitude,
);

LatLng _centerOf(List<CatalogItem> items) {
  final latitude = items.fold<double>(
    0,
    (total, item) => total + item.approximateLocation.latitude,
  );
  final longitude = items.fold<double>(
    0,
    (total, item) => total + item.approximateLocation.longitude,
  );
  return LatLng(latitude / items.length, longitude / items.length);
}
