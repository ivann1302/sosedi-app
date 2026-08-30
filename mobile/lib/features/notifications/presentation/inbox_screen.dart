import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../data/inbox_event.dart';
import '../data/inbox_service.dart';
import '../domain/inbox_controller.dart';
import '../domain/inbox_open_controller.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(inboxControllerProvider);
    final opening = ref.watch(inboxOpenProvider);
    final inbox = events.value;
    final hasUnread =
        inbox?.items.any((event) => event.readAt == null) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            onPressed: hasUnread && inbox?.isMarkingAllRead != true
                ? () async {
                    await ref
                        .read(inboxControllerProvider.notifier)
                        .markAllRead();
                    ref.invalidate(inboxEventsProvider);
                  }
                : null,
            tooltip: 'Прочитать всё',
            icon: inbox?.isMarkingAllRead == true
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all),
          ),
          IconButton(
            onPressed: () {
              ref.invalidate(inboxControllerProvider);
              ref.invalidate(inboxEventsProvider);
            },
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _InboxError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить уведомления',
            ),
            onRetry: () => ref.invalidate(inboxControllerProvider),
          ),
          data: (value) => Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: FilterChip(
                    label: const Text('Непрочитанные'),
                    selected: value.unreadOnly,
                    onSelected: (selected) => ref
                        .read(inboxControllerProvider.notifier)
                        .setUnreadOnly(selected),
                  ),
                ),
              ),
              Expanded(
                child: value.items.isEmpty
                    ? Center(
                        child: Text(
                          value.unreadOnly
                              ? 'Непрочитанных уведомлений нет'
                              : 'Уведомлений пока нет',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          final _ = await ref.refresh(
                            inboxControllerProvider.future,
                          );
                          ref.invalidate(inboxEventsProvider);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              value.items.length +
                              (value.nextCursor != null ||
                                      value.loadMoreError != null
                                  ? 1
                                  : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index == value.items.length) {
                              return Center(
                                child: value.isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : OutlinedButton(
                                        onPressed: () => ref
                                            .read(
                                              inboxControllerProvider.notifier,
                                            )
                                            .loadMore(),
                                        child: Text(
                                          value.loadMoreError ?? 'Показать ещё',
                                        ),
                                      ),
                              );
                            }
                            final event = value.items[index];
                            return Card(
                              child: ListTile(
                                enabled: !opening.isLoading,
                                onTap: () => _open(context, ref, event),
                                leading: Icon(_icon(event.eventType)),
                                title: Text(_title(event.eventType)),
                                subtitle: Text(_time(event.createdAt)),
                                trailing: event.readAt == null
                                    ? const Chip(label: Text('Новое'))
                                    : const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    InboxEvent event,
  ) async {
    final path = await ref.read(inboxOpenProvider.notifier).open(event);
    if (!context.mounted) {
      return;
    }
    final state = ref.read(inboxOpenProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(
              state.error!,
              fallback: 'Не удалось открыть уведомление',
            ),
          ),
        ),
      );
      return;
    }
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Для уведомления нет доступного экрана')),
      );
      return;
    }
    context.push(path);
  }

  String _title(String eventType) => switch (eventType) {
    'BOOKING_CONFIRMED' => 'Бронирование подтверждено',
    'HANDOVER_CONFIRMED' => 'Передача подтверждена',
    'RETURN_CONFIRMED' => 'Возврат подтверждён',
    'BOOKING_MESSAGE_CREATED' => 'Новое сообщение',
    'ITEM_APPROVED' => 'Объявление одобрено',
    'ITEM_REJECTED' => 'Объявление требует изменений',
    'REVIEW_HIDDEN_BY_REPORT_REVIEW' => 'Отзыв скрыт после проверки',
    'SUPPORT_REPLIED' || 'SUPPORT_MESSAGE_CREATED' => 'Ответ поддержки',
    'SUPPORT_TICKET_CLOSED' => 'Обращение закрыто',
    _ => 'Обновление в Соседях',
  };

  IconData _icon(String eventType) {
    if (eventType.startsWith('ITEM_')) {
      return Icons.inventory_2_outlined;
    }
    if (eventType.startsWith('SUPPORT_')) {
      return Icons.support_agent_outlined;
    }
    if (eventType == 'BOOKING_MESSAGE_CREATED') {
      return Icons.chat_bubble_outline;
    }
    if (eventType.startsWith('REVIEW_')) {
      return Icons.rate_review_outlined;
    }
    return Icons.event_available_outlined;
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _InboxError extends StatelessWidget {
  const _InboxError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
