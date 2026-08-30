import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../core/network/api_exception.dart';
import '../../notifications/data/inbox_service.dart';
import '../../notifications/domain/inbox_controller.dart';
import '../../safety/domain/safety_action_controller.dart';
import '../../safety/presentation/report_dialog.dart';
import '../data/booking_models.dart';
import '../data/booking_service.dart';
import '../domain/booking_message_send_controller.dart';

class BookingChatScreen extends ConsumerStatefulWidget {
  const BookingChatScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends ConsumerState<BookingChatScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<BookingMessage> _olderMessages = [];
  Timer? _pollTimer;
  String? _olderCursor;
  bool _loadedOlder = false;
  bool _loadingOlder = false;
  bool _blocking = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_active && mounted) {
        ref.invalidate(bookingMessagesProvider(widget.bookingId));
        unawaited(_markRead());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active && mounted) {
      ref.invalidate(bookingMessagesProvider(widget.bookingId));
      unawaited(_markRead());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(bookingMessagesProvider(widget.bookingId));
    final booking = ref.watch(bookingDetailsProvider(widget.bookingId));
    final sending = ref.watch(bookingMessageSendProvider);
    final safetyAction = ref.watch(safetyActionProvider);
    final bookingValue = booking.value;
    final writable = bookingValue != null && _canWrite(bookingValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат по аренде'),
        actions: [
          IconButton(
            onPressed: _blocking ? null : _blockCounterparty,
            tooltip: 'Заблокировать собеседника',
            icon: const Icon(Icons.block_outlined),
          ),
          IconButton(
            onPressed: _refresh,
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: page.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить сообщения',
            ),
            onRetry: _refresh,
          ),
          data: (value) {
            final messages = _mergeMessages([
              ..._olderMessages,
              ...value.items,
            ]);
            final nextCursor = _loadedOlder ? _olderCursor : value.nextCursor;
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (nextCursor != null)
                          Center(
                            child: TextButton(
                              onPressed: _loadingOlder
                                  ? null
                                  : () => _loadOlder(nextCursor),
                              child: Text(
                                _loadingOlder
                                    ? 'Загрузка…'
                                    : 'Показать предыдущие',
                              ),
                            ),
                          ),
                        if (messages.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                Icon(Icons.forum_outlined, size: 40),
                                SizedBox(height: 12),
                                Text(
                                  'Согласуйте время и детали передачи здесь.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        for (final message in messages)
                          _MessageBubble(
                            message: message,
                            onReport:
                                message.author == 'COUNTERPARTY' &&
                                    !safetyAction.isLoading
                                ? () => _reportMessage(message)
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
                if (writable)
                  _Composer(
                    formKey: _formKey,
                    sending: sending.isLoading,
                    error: sending.error,
                    onSend: _send,
                  )
                else
                  const Material(
                    color: Color(0xFFF2F4F7),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Переписка доступна только для чтения',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final _ = await ref.refresh(
      bookingMessagesProvider(widget.bookingId).future,
    );
    await _markRead();
  }

  Future<void> _markRead() async {
    try {
      await ref.read(bookingServiceProvider).markMessagesRead(widget.bookingId);
      ref.invalidate(inboxEventsProvider);
      ref.invalidate(inboxControllerProvider);
    } catch (_) {
      // Chat reading remains available offline; inbox will retry on refresh.
    }
  }

  Future<void> _loadOlder(String cursor) async {
    setState(() => _loadingOlder = true);
    try {
      final page = await ref
          .read(bookingServiceProvider)
          .listMessages(widget.bookingId, cursor: cursor);
      if (!mounted) {
        return;
      }
      setState(() {
        _olderMessages.insertAll(0, page.items);
        _olderCursor = page.nextCursor;
        _loadedOlder = true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                error,
                fallback: 'Не удалось загрузить предыдущие сообщения',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingOlder = false);
      }
    }
  }

  Future<void> _send() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final sent = await ref
        .read(bookingMessageSendProvider.notifier)
        .send(bookingId: widget.bookingId, body: form.value['body']! as String);
    if (sent && mounted) {
      form.reset();
      await _refresh();
    }
  }

  Future<void> _reportMessage(BookingMessage message) async {
    final submission = await showSafetyReportDialog(
      context: context,
      targetType: 'MESSAGE',
    );
    if (submission == null || !mounted) {
      return;
    }
    final sent = await ref
        .read(safetyActionProvider.notifier)
        .report(
          targetType: 'MESSAGE',
          targetId: message.id,
          reason: submission.reason,
          description: submission.description,
        );
    if (!mounted) {
      return;
    }
    final action = ref.read(safetyActionProvider);
    final error = action.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Жалоба отправлена'
              : error == null
              ? 'Действие уже выполняется'
              : userFacingError(error, fallback: 'Не удалось отправить жалобу'),
        ),
      ),
    );
  }

  Future<void> _blockCounterparty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать собеседника?'),
        content: const Text(
          'Новые сообщения станут недоступны. Ожидающая заявка будет отменена, '
          'а активная аренда и акты останутся доступны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _blocking = true);
    try {
      await ref
          .read(bookingServiceProvider)
          .blockCounterparty(widget.bookingId);
      ref
        ..invalidate(bookingDetailsProvider(widget.bookingId))
        ..invalidate(myBookingsProvider)
        ..invalidate(bookingMessagesProvider(widget.bookingId))
        ..invalidate(inboxEventsProvider)
        ..invalidate(inboxControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Собеседник заблокирован')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                error,
                fallback: 'Не удалось заблокировать собеседника',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _blocking = false);
      }
    }
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.formKey,
    required this.sending,
    required this.error,
    required this.onSend,
  });

  final GlobalKey<FormBuilderState> formKey;
  final bool sending;
  final Object? error;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('booking-chat-composer'),
      color: Theme.of(context).colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormBuilder(
                key: formKey,
                child: FormBuilderTextField(
                  name: 'body',
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Сообщение',
                    hintText: 'Напишите о времени и передаче вещи',
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.maxLength(2000),
                  ]),
                ),
              ),
              if (error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    userFacingError(
                      error!,
                      fallback: 'Не удалось отправить сообщение',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(sending ? 'Отправляем…' : 'Отправить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onReport});

  final BookingMessage message;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    if (message.author == 'SYSTEM') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                message.body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      );
    }
    final mine = message.author == 'SELF';
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFF7F8F9) : colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mine ? 'Вы' : 'Собеседник',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(message.body),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _time(message.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            if (onReport != null)
              TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.report_outlined, size: 16),
                label: const Text('Пожаловаться'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

bool _canWrite(ParticipantBooking booking) {
  if (booking.status == 'PENDING') {
    return booking.expiresAt?.isAfter(DateTime.now()) ?? false;
  }
  return const {'CONFIRMED', 'ACTIVE', 'RETURNED'}.contains(booking.status);
}

List<BookingMessage> _mergeMessages(List<BookingMessage> values) {
  final byId = {for (final value in values) value.id: value};
  final result = byId.values.toList(growable: false);
  result.sort((left, right) {
    final byTime = left.createdAt.compareTo(right.createdAt);
    return byTime != 0 ? byTime : left.id.compareTo(right.id);
  });
  return result;
}

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
