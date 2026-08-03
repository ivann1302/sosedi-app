import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/marketplace_documents_config.dart';

final externalDocumentOpenerProvider = Provider<Future<bool> Function(Uri)>((
  ref,
) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(marketplaceDocumentsConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Правила и документы')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (documents.isPublishedSetReady) ...[
              const Text(
                'Перед действием проверяйте номер опубликованной версии.',
              ),
              const SizedBox(height: 16),
              _DocumentButton(
                label: 'Оферта · ${documents.offerVersion}',
                onPressed: () => _open(context, ref, documents.offerUri!),
              ),
              const SizedBox(height: 12),
              _DocumentButton(
                label:
                    'Правила аренды и отмены · '
                    '${documents.cancellationPolicyVersion}',
                onPressed: () => _open(context, ref, documents.rentalRulesUri!),
              ),
              const SizedBox(height: 12),
              _DocumentButton(
                label:
                    'Политика конфиденциальности · '
                    '${documents.privacyVersion}',
                onPressed: () => _open(context, ref, documents.privacyUri!),
              ),
            ] else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.policy_outlined),
                  title: Text('Документы готовятся к публикации'),
                  subtitle: Text(
                    'Черновики не показываются как действующие условия.',
                  ),
                ),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.push('/support'),
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Поддержка'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/profile/data-export'),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Экспортировать мои данные'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Uri uri) async {
    try {
      if (await ref.read(externalDocumentOpenerProvider)(uri)) {
        return;
      }
    } catch (_) {
      // The user receives one safe message below.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть документ')),
      );
    }
  }
}

class _DocumentButton extends StatelessWidget {
  const _DocumentButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.open_in_new),
      label: Text(label),
    );
  }
}
