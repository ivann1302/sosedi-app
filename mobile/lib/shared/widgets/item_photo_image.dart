import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const _pilotAssetPrefix = 'asset:///assets/images/mock_items/';

class ItemPhotoImage extends StatelessWidget {
  const ItemPhotoImage({
    required this.source,
    required this.semanticLabel,
    required this.fit,
    super.key,
  });

  final String source;
  final String semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith(_pilotAssetPrefix)) {
      return Image.asset(
        source.substring('asset:///'.length),
        semanticLabel: semanticLabel,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }
    if (source.startsWith('asset:')) {
      return const ItemPhotoPlaceholder(broken: true);
    }
    return Image.network(
      source,
      semanticLabel: semanticLabel,
      fit: fit,
      errorBuilder: _errorBuilder,
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) => const ItemPhotoPlaceholder(broken: true);
}

class ItemPhotoPlaceholder extends StatelessWidget {
  const ItemPhotoPlaceholder({
    this.broken = false,
    this.semanticLabel = 'Фото отсутствует',
    super.key,
  });

  final bool broken;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ColoredBox(
        color: AppColors.warmSand,
        child: Center(
          child: Icon(
            broken ? Icons.broken_image_outlined : Icons.inventory_2_outlined,
            color: AppColors.slate800,
          ),
        ),
      ),
    );
  }
}
