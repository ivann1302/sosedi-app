import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';

class AnalyticsSettingsScreen extends ConsumerWidget {
  const AnalyticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(analyticsConsentProvider);
    final controller = ref.read(analyticsConsentProvider.notifier);
    final available = controller.isAvailable;
    final granted = consent == AnalyticsConsent.granted;

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Помогать улучшать приложение',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Разрешены только технические события воронки без телефона, '
              'адреса, координат, документов, платежных данных, текста '
              'объявлений и идентификаторов бронирований.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Согласие добровольное. Его можно отозвать в любой момент; '
              'после отзыва новые события не отправляются.',
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Отправлять обезличенную аналитику'),
              subtitle: Text(
                available
                    ? 'Хранение событий — не более 12 месяцев'
                    : 'Недоступно до публикации privacy/consent и подключения '
                          'AppMetrica',
              ),
              value: granted,
              onChanged: available || granted
                  ? (value) async {
                      await controller.setGranted(value);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
