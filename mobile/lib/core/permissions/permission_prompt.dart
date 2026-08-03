import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_permissions.dart';

Future<bool> requestPermissionFromUserAction({
  required BuildContext context,
  required WidgetRef ref,
  required AppPermission permission,
}) async {
  final gateway = ref.read(appPermissionGatewayProvider);
  final status = await gateway.request(permission);
  if (status.isGranted || status.isLimited) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }

  final permanentlyDenied = status.isPermanentlyDenied;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(_title(permission)),
      content: Text(
        permanentlyDenied
            ? '${_explanation(permission)} Доступ можно изменить в настройках.'
            : '${_explanation(permission)} Повторный запрос появится только '
                  'после вашего следующего действия.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Не сейчас'),
        ),
        if (permanentlyDenied)
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await gateway.openSettings();
            },
            child: const Text('Открыть настройки'),
          ),
      ],
    ),
  );
  return false;
}

String _title(AppPermission permission) => switch (permission) {
  AppPermission.location => 'Доступ к геопозиции',
  AppPermission.camera => 'Доступ к камере',
  AppPermission.photos => 'Доступ к фотографиям',
  AppPermission.notifications => 'Разрешение уведомлений',
};

String _explanation(AppPermission permission) => switch (permission) {
  AppPermission.location => 'Он нужен, чтобы искать вещи рядом.',
  AppPermission.camera => 'Она нужна только для снимка по вашему действию.',
  AppPermission.photos => 'Они нужны, чтобы добавить выбранные вами снимки.',
  AppPermission.notifications =>
    'Они нужны для выбранных вами сигналов о бронировании.',
};
