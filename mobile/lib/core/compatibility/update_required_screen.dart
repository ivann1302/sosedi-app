import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'compatibility_gate.dart';

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>((ref) {
  return const ExternalUrlLauncher();
});

class ExternalUrlLauncher {
  const ExternalUrlLauncher();

  Future<bool> open(Uri url) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirement = ref.watch(compatibilityRequirementProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.system_update_alt,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Нужно обновить приложение',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    requirement?.message ??
                        'Текущая версия больше не совместима с сервисом.',
                    textAlign: TextAlign.center,
                  ),
                  if (requirement?.minimumVersion case final String version
                      when version.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Минимальная версия: $version',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (requirement?.updateUrl case final Uri updateUrl)
                    FilledButton.icon(
                      onPressed: () => _openUpdate(context, ref, updateUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Открыть магазин приложений'),
                    )
                  else
                    const Text(
                      'Откройте магазин приложений и установите последнюю версию.',
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUpdate(
    BuildContext context,
    WidgetRef ref,
    Uri updateUrl,
  ) async {
    final opened = await ref.read(externalUrlLauncherProvider).open(updateUrl);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть магазин приложений')),
      );
    }
  }
}
