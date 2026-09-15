import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const _pilotAvatarPrefix = 'asset:///assets/images/mock_users/';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.avatarUrl,
    required this.name,
    this.radius = 36,
    super.key,
  });

  final String? avatarUrl;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = _imageProvider(avatarUrl);
    final fallback = ColoredBox(
      color: AppColors.cloud,
      child: Center(
        child: Text(
          _initial(name),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: AppColors.ink900),
        ),
      ),
    );
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: radius * 2,
        child: ClipOval(
          child: image == null
              ? fallback
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }

  ImageProvider<Object>? _imageProvider(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }
    if (source.startsWith(_pilotAvatarPrefix)) {
      return AssetImage(source.substring('asset:///'.length));
    }
    if (source.startsWith('asset:')) {
      return null;
    }
    return NetworkImage(source);
  }

  String _initial(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'С';
    }
    return trimmed.characters.first.toUpperCase();
  }
}
