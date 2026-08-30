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
          padding: const EdgeInsets.all(16),
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
              const Divider(height: 1, indent: 56),
              _DocumentButton(
                label:
                    'Правила аренды и отмены · '
                    '${documents.cancellationPolicyVersion}',
                onPressed: () => _open(context, ref, documents.rentalRulesUri!),
              ),
              const Divider(height: 1, indent: 56),
              _DocumentButton(
                label:
                    'Политика конфиденциальности · '
                    '${documents.privacyVersion}',
                onPressed: () => _open(context, ref, documents.privacyUri!),
              ),
            ] else
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.policy_outlined),
                title: Text('Документы готовятся к публикации'),
                subtitle: Text(
                  'Черновики не показываются как действующие условия.',
                ),
              ),
            const SizedBox(height: 24),
            Text('Ещё', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => context.push('/support'),
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Поддержка'),
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => context.push('/profile/data-export'),
              leading: const Icon(Icons.download_outlined),
              title: const Text('Экспортировать мои данные'),
              trailing: const Icon(Icons.chevron_right),
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
    return ListTile(
      minTileHeight: 56,
      contentPadding: EdgeInsets.zero,
      onTap: onPressed,
      leading: const Icon(Icons.description_outlined),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new),
    );
  }
}
