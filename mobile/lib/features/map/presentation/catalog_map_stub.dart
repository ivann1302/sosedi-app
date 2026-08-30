import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../catalog/data/catalog_models.dart';

class CatalogMapStub extends StatelessWidget {
  const CatalogMapStub({
    required this.items,
    required this.selectedItemId,
    required this.onItemSelected,
    super.key,
  });

  final List<CatalogItem> items;
  final String? selectedItemId;
  final ValueChanged<String> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => item.id == selectedItemId);
    final selectedItem = selected.firstOrNull ?? items.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: ColoredBox(
          color: AppColors.warmSand,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  const Positioned.fill(child: _DemoMapBackground()),
                  for (final entry in items.indexed)
                    _marker(
                      constraints: constraints,
                      item: entry.$2,
                      index: entry.$1,
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: _Notice(itemCount: items.length),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _SelectedItemCard(
                      key: ValueKey('demo-map-selected-${selectedItem.id}'),
                      item: selectedItem,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _marker({
    required BoxConstraints constraints,
    required CatalogItem item,
    required int index,
  }) {
    const horizontalPadding = 32.0;
    const topReserved = 112.0;
    const bottomReserved = 156.0;
    final latitudes = items
        .map((value) => value.approximateLocation.latitude)
        .toList();
    final longitudes = items
        .map((value) => value.approximateLocation.longitude)
        .toList();
    final minLat = latitudes.reduce(math.min);
    final maxLat = latitudes.reduce(math.max);
    final minLon = longitudes.reduce(math.min);
    final maxLon = longitudes.reduce(math.max);
    final latitudeSpan = maxLat - minLat;
    final longitudeSpan = maxLon - minLon;
    final usableWidth = math.max(
      1.0,
      constraints.maxWidth - horizontalPadding * 2,
    );
    final usableHeight = math.max(
      1.0,
      constraints.maxHeight - topReserved - bottomReserved,
    );
    final overlapOffset = Offset((index % 3 - 1) * 18, (index % 2) * 14);
    final normalizedX = longitudeSpan == 0
        ? 0.5
        : (item.approximateLocation.longitude - minLon) / longitudeSpan;
    final normalizedY = latitudeSpan == 0
        ? 0.5
        : (maxLat - item.approximateLocation.latitude) / latitudeSpan;
    final left = horizontalPadding + normalizedX * usableWidth;
    final top = topReserved + normalizedY * usableHeight;

    return Positioned(
      left: left - 24 + overlapOffset.dx,
      top: top - 24 + overlapOffset.dy,
      child: Semantics(
        button: true,
        label: 'Выбрать ${item.title} на демо-карте',
        child: IconButton.filled(
          key: ValueKey('demo-map-marker-${item.id}'),
          onPressed: () => onItemSelected(item.id),
          tooltip: item.title,
          icon: const Icon(Icons.location_on),
        ),
      ),
    );
  }
}

class _DemoMapBackground extends StatelessWidget {
  const _DemoMapBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DemoMapPainter());
  }
}

class _DemoMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final minorRoad = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.75)
      ..strokeWidth = 8;
    final majorRoad = Paint()
      ..color = AppColors.surface
      ..strokeWidth = 16;
    canvas.drawLine(
      Offset(0, size.height * 0.34),
      Offset(size.width, size.height * 0.58),
      majorRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, 0),
      Offset(size.width * 0.72, size.height),
      majorRoad,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.24),
      minorRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, 0),
      Offset(size.width * 0.36, size.height),
      minorRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Notice extends StatelessWidget {
  const _Notice({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Приблизительное расположение',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Демо без MapKit · $itemCount вещей · '
              'Точные адреса не показываются',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedItemCard extends StatelessWidget {
  const _SelectedItemCard({required this.item, super.key});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.title, style: Theme.of(context).textTheme.titleSmall),
        Text(
          '${_price(item.pricePerDay)} ₽ / день · ${item.area}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
    final openButton = TextButton(
      onPressed: () => context.push('/items/${item.id}'),
      child: const Text('Открыть'),
    );

    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: 10),
                      Expanded(child: summary),
                    ],
                  ),
                  Align(alignment: Alignment.centerRight, child: openButton),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.inventory_2_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: summary),
                  openButton,
                ],
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
