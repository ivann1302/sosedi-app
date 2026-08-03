import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../safety/domain/safety_action_controller.dart';
import '../../safety/presentation/report_dialog.dart';
import '../data/booking_models.dart';
import '../data/booking_service.dart';
import '../domain/booking_action_controller.dart';
import 'booking_list_screen.dart';

final bookingEvidencePickerProvider = Provider<BookingEvidencePicker>((ref) {
  return BookingEvidencePicker(ImagePicker());
});

class BookingEvidencePicker {
  const BookingEvidencePicker(this._picker);

  final ImagePicker _picker;

  Future<XFile?> pick() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }
}

class BookingDetailsScreen extends ConsumerWidget {
  const BookingDetailsScreen({required this.bookingId, super.key});

  final String bookingId;

  Future<void> _reportIssue(
    BuildContext context,
    WidgetRef ref,
    ParticipantBooking booking,
  ) async {
    final issues = _issuesFor(booking);
    if (issues.isEmpty) {
      return;
    }
    final formKey = GlobalKey<FormState>();
    var details = '';
    var selectedReason = issues.first.code;
    final submission = await showDialog<({String reason, String details})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Сообщить о проблеме'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: const InputDecoration(labelText: 'Ситуация'),
                  items: [
                    for (final issue in issues)
                      DropdownMenuItem(
                        value: issue.code,
                        child: Text(issue.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedReason = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Что произошло',
                    hintText: 'Опишите факты без платёжных и паспортных данных',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 10
                      ? 'Добавьте описание не короче 10 символов'
                      : null,
                  onChanged: (value) => details = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) {
                  return;
                }
                Navigator.pop(context, (
                  reason: selectedReason,
                  details: details.trim(),
                ));
              },
              child: const Text('Отправить'),
            ),
          ],
        ),
      ),
    );
    if (submission == null || !context.mounted) {
      return;
    }
    await ref
        .read(bookingActionProvider.notifier)
        .reportIssue(
          bookingId: booking.id,
          reason: submission.reason,
          details: submission.details,
        );
    if (context.mounted && !ref.read(bookingActionProvider).hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Обращение отправлено')));
    }
  }

  Future<void> _createAct(
    BuildContext context,
    WidgetRef ref,
    ParticipantBooking booking,
  ) async {
    final stage = booking.status == 'CONFIRMED' ? 'HANDOVER' : 'RETURN';
    final label = stage == 'HANDOVER' ? 'передачи' : 'возврата';
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создать акт $label?'),
        content: const Text(
          'Выберите один снимок состояния и комплектации вещи. '
          'Вторая сторона должна отдельно подтвердить акт.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выбрать снимок'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) {
      return;
    }
    final allowed = await requestPermissionFromUserAction(
      context: context,
      ref: ref,
      permission: AppPermission.photos,
    );
    if (!allowed || !context.mounted) {
      return;
    }
    final photo = await ref.read(bookingEvidencePickerProvider).pick();
    if (photo == null || !context.mounted) {
      return;
    }
    await ref
        .read(bookingActionProvider.notifier)
        .createAct(bookingId: booking.id, stage: stage, photo: photo);
    if (context.mounted && !ref.read(bookingActionProvider).hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Акт $label создан')));
    }
  }

  Future<void> _reportSafety(
    BuildContext context,
    WidgetRef ref,
    ParticipantBooking booking,
  ) async {
    final submission = await showSafetyReportDialog(
      context: context,
      targetType: 'BOOKING',
    );
    if (submission == null || !context.mounted) {
      return;
    }
    final success = await ref
        .read(safetyActionProvider.notifier)
        .report(
          targetType: 'BOOKING',
          targetId: booking.id,
          reason: submission.reason,
          description: submission.description,
        );
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Жалоба отправлена')));
    }
  }

  Future<void> _confirmAct(
    BuildContext context,
    WidgetRef ref,
    BookingAct act,
  ) async {
    final label = act.stage == 'HANDOVER' ? 'передачу вещи' : 'возврат вещи';
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подтвердить $label?'),
        content: const Text(
          'Проверьте состояние, комплектацию и снимок. '
          'Подтверждение изменит статус бронирования.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              act.stage == 'HANDOVER'
                  ? 'Подтвердить передачу'
                  : 'Подтвердить возврат',
            ),
          ),
        ],
      ),
    );
    if (approved != true) {
      return;
    }
    await ref
        .read(bookingActionProvider.notifier)
        .confirmAct(bookingId: act.bookingId, actId: act.id);
  }

  Future<void> _openEvidence(
    BuildContext context,
    WidgetRef ref,
    String evidenceId,
  ) async {
    NetworkImage? image;
    try {
      final uri = await ref
          .read(bookingServiceProvider)
          .getEvidenceDownloadUri(bookingId, evidenceId);
      image = NetworkImage(uri.toString());
      if (!context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image(
              image: image!,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Не удалось загрузить снимок'),
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(error, fallback: 'Не удалось открыть снимок'),
            ),
          ),
        );
      }
    } finally {
      await image?.evict();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingDetailsProvider(bookingId));
    final acts = ref.watch(bookingActsProvider(bookingId));
    final action = ref.watch(bookingActionProvider);
    final safetyAction = ref.watch(safetyActionProvider);
    final auth = ref.watch(authControllerProvider);
    final currentUserId = auth is AuthAuthenticated ? auth.user.id : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Бронирование')),
      body: SafeArea(
        child: booking.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userFacingError(
                    error,
                    fallback: 'Не удалось загрузить бронирование',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(bookingDetailsProvider(bookingId)),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
          data: (value) => _Content(
            booking: value,
            acts: acts,
            action: action,
            safetyAction: safetyAction,
            currentUserId: currentUserId,
            onConfirm: () =>
                ref.read(bookingActionProvider.notifier).confirm(bookingId),
            onCancel: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Отменить заявку?'),
                  content: const Text(
                    'Ожидающая заявка будет отменена, а даты снова станут свободны.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Оставить'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Отменить заявку'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(bookingActionProvider.notifier)
                    .cancel(bookingId);
              }
            },
            onReportIssue: _issuesFor(value).isEmpty
                ? null
                : () => _reportIssue(context, ref, value),
            onCreateAct: () => _createAct(context, ref, value),
            onConfirmAct: (act) => _confirmAct(context, ref, act),
            onOpenEvidence: (evidenceId) =>
                _openEvidence(context, ref, evidenceId),
            onRetryActs: () => ref.invalidate(bookingActsProvider(bookingId)),
            onReportSafety: () => _reportSafety(context, ref, value),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.booking,
    required this.acts,
    required this.action,
    required this.safetyAction,
    required this.currentUserId,
    required this.onConfirm,
    required this.onCancel,
    required this.onReportIssue,
    required this.onCreateAct,
    required this.onConfirmAct,
    required this.onOpenEvidence,
    required this.onRetryActs,
    required this.onReportSafety,
  });

  final ParticipantBooking booking;
  final AsyncValue<List<BookingAct>> acts;
  final AsyncValue<String?> action;
  final AsyncValue<String?> safetyAction;
  final String? currentUserId;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback? onReportIssue;
  final VoidCallback onCreateAct;
  final ValueChanged<BookingAct> onConfirmAct;
  final ValueChanged<String> onOpenEvidence;
  final VoidCallback onRetryActs;
  final VoidCallback onReportSafety;

  @override
  Widget build(BuildContext context) {
    final terms = booking.terms;
    final actionError = action.error;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          terms?.itemTitle ?? 'Бронирование',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Chip(label: Text(bookingStatusLabel(booking.status))),
        const SizedBox(height: 16),
        _Row(
          label: 'Период',
          value:
              '${bookingDate(booking.startDate)}–'
              '${bookingDate(booking.endDate)}',
        ),
        _Row(
          label: 'Ваша роль',
          value: booking.actorRole == 'LENDER' ? 'Сдаёте' : 'Арендуете',
        ),
        if (booking.status == 'PENDING' && booking.expiresAt != null)
          _Row(label: 'Заявка действует до', value: _time(booking.expiresAt!)),
        if (booking.cancellationReason != null)
          _Row(label: 'Причина', value: booking.cancellationReason!),
        if (terms != null) ...[
          const SizedBox(height: 16),
          Text('Цена и условия', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _Row(
            label: 'Владелец',
            value: terms.lenderDisplayName ?? 'Имя не указано',
          ),
          _Row(
            label: '${_money(terms.pricePerDay)} ₽ × ${terms.days} дн.',
            value: '${_money(terms.rentalSubtotal)} ₽',
          ),
          _Row(
            label: 'Залог',
            value: terms.depositAmount == null
                ? 'Нет'
                : '${_money(terms.depositAmount!)} ₽',
          ),
          _Row(
            label: terms.paymentScenario == 'PAY_ON_HANDOVER'
                ? 'Комиссия Sosedi (офлайн-пилот)'
                : 'Комиссия Sosedi',
            value: '${_money(terms.platformFee)} ₽',
          ),
          _Row(
            label: 'Выплата владельцу',
            value: '${_money(terms.ownerPayout)} ₽',
          ),
          _Row(label: 'Итого', value: '${_money(terms.total)} ₽'),
          _Row(label: 'Валюта', value: terms.currency),
          _Row(
            label: 'Оплата',
            value: terms.paymentScenario == 'PAY_ON_HANDOVER'
                ? 'При передаче вещи'
                : terms.paymentScenario,
          ),
          _Row(label: 'Версия объявления', value: terms.listingVersion),
          _Row(
            label: 'Оферта',
            value: terms.offerVersion ?? 'Ожидает публикации',
          ),
          _Row(
            label: 'Правила отмены',
            value: terms.cancellationPolicyVersion ?? 'Ожидают публикации',
          ),
        ],
        if (booking.handover != null) ...[
          const SizedBox(height: 16),
          Text('Передача', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _Row(label: 'Адрес', value: booking.handover!.address),
          if (booking.counterpartyContact != null)
            _Row(label: 'Контакт', value: booking.counterpartyContact!),
        ],
        const SizedBox(height: 16),
        Text(
          'Акты передачи и возврата',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        acts.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Row(
            children: [
              Expanded(
                child: Text(
                  userFacingError(error, fallback: 'Не удалось загрузить акты'),
                ),
              ),
              TextButton(
                onPressed: onRetryActs,
                child: const Text('Повторить'),
              ),
            ],
          ),
          data: (values) => _Acts(
            booking: booking,
            values: values,
            currentUserId: currentUserId,
            isLoading: action.isLoading,
            onCreate: onCreateAct,
            onConfirm: onConfirmAct,
            onOpenEvidence: onOpenEvidence,
          ),
        ),
        if (actionError != null) ...[
          const SizedBox(height: 12),
          Text(
            userFacingError(
              actionError,
              fallback: 'Не удалось выполнить действие',
            ),
          ),
        ],
        if (booking.actorRole == 'LENDER' && booking.status == 'PENDING') ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: action.isLoading ? null : onConfirm,
            child: action.isLoading
                ? const CircularProgressIndicator()
                : const Text('Подтвердить бронирование'),
          ),
        ],
        if (booking.status == 'PENDING') ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: action.isLoading ? null : onCancel,
            child: const Text('Отменить заявку'),
          ),
        ],
        if (onReportIssue != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: action.isLoading ? null : onReportIssue,
            icon: const Icon(Icons.support_agent),
            label: const Text('Сообщить о проблеме'),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: safetyAction.isLoading ? null : onReportSafety,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Пожаловаться на бронирование'),
        ),
        if (safetyAction.hasError)
          Text(
            userFacingError(
              safetyAction.error!,
              fallback: 'Не удалось отправить жалобу',
            ),
          ),
      ],
    );
  }
}

class _Acts extends StatelessWidget {
  const _Acts({
    required this.booking,
    required this.values,
    required this.currentUserId,
    required this.isLoading,
    required this.onCreate,
    required this.onConfirm,
    required this.onOpenEvidence,
  });

  final ParticipantBooking booking;
  final List<BookingAct> values;
  final String? currentUserId;
  final bool isLoading;
  final VoidCallback onCreate;
  final ValueChanged<BookingAct> onConfirm;
  final ValueChanged<String> onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    final currentStage = switch (booking.status) {
      'CONFIRMED' => 'HANDOVER',
      'ACTIVE' => 'RETURN',
      _ => null,
    };
    final hasOwnCurrentAct =
        currentUserId != null &&
        currentStage != null &&
        values.any(
          (act) => act.stage == currentStage && act.authorId == currentUserId,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (values.isEmpty) const Text('Актов пока нет'),
        for (final act in values)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act.stage == 'HANDOVER' ? 'Акт передачи' : 'Акт возврата',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    act.authorId == currentUserId
                        ? 'Создан вами'
                        : 'Создан второй стороной',
                  ),
                  Text(
                    act.confirmedAt == null
                        ? 'Ожидает подтверждения'
                        : 'Подтверждён',
                  ),
                  for (var index = 0; index < act.evidence.length; index += 1)
                    TextButton.icon(
                      onPressed: () => onOpenEvidence(act.evidence[index].id),
                      icon: const Icon(Icons.image_outlined),
                      label: Text('Открыть снимок ${index + 1}'),
                    ),
                  if (act.confirmedAt == null &&
                      currentUserId != null &&
                      act.authorId != currentUserId &&
                      act.stage == currentStage)
                    FilledButton(
                      onPressed: isLoading ? null : () => onConfirm(act),
                      child: Text(
                        act.stage == 'HANDOVER'
                            ? 'Подтвердить передачу'
                            : 'Подтвердить возврат',
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (currentStage != null && currentUserId != null && !hasOwnCurrentAct)
          OutlinedButton.icon(
            onPressed: isLoading ? null : onCreate,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              currentStage == 'HANDOVER'
                  ? 'Создать акт передачи'
                  : 'Создать акт возврата',
            ),
          ),
      ],
    );
  }
}

List<({String code, String label})> _issuesFor(ParticipantBooking booking) {
  if (booking.status == 'CONFIRMED') {
    return booking.actorRole == 'BORROWER'
        ? const [
            (code: 'OWNER_NO_SHOW', label: 'Владелец не пришёл'),
            (code: 'ITEM_FAULTY', label: 'Вещь неисправна при передаче'),
          ]
        : const [(code: 'BORROWER_NO_SHOW', label: 'Арендатор не пришёл')];
  }
  if (booking.status == 'ACTIVE') {
    return const [
      (code: 'EARLY_RETURN', label: 'Досрочный возврат'),
      (code: 'LATE_RETURN', label: 'Просроченный возврат'),
      (code: 'ITEM_DAMAGED', label: 'Вещь повреждена'),
      (code: 'ITEM_LOST', label: 'Вещь потеряна'),
    ];
  }
  if (booking.status == 'RETURNED') {
    return const [
      (code: 'ITEM_DAMAGED', label: 'Вещь повреждена'),
      (code: 'ITEM_LOST', label: 'Вещь потеряна'),
    ];
  }
  return const [];
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

String _money(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _time(DateTime value) =>
    '${bookingDate(value.toLocal())} '
    '${value.toLocal().hour.toString().padLeft(2, '0')}:'
    '${value.toLocal().minute.toString().padLeft(2, '0')}';
