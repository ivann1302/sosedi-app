import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../../../shared/widgets/inline_select_field.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../reviews/data/review_models.dart';
import '../../reviews/data/review_service.dart';
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
                InlineSelectField<String>(
                  value: selectedReason,
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
    final receipt = await ref
        .read(bookingActionProvider.notifier)
        .reportIssue(
          bookingId: booking.id,
          reason: submission.reason,
          details: submission.details,
        );
    if (receipt == null || !context.mounted) {
      return;
    }
    final openTicket = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обращение принято'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Номер: ${receipt.id}'),
            Text('Время сервера: ${_time(receipt.createdAt)}'),
            Text('Статус: ${_supportStatus(receipt.status)}'),
            const SizedBox(height: 12),
            const Text(
              'Ориентир первой реакции — до 12 часов. Бронь и сумма не '
              'изменились автоматически. Фото можно добавить в обращении.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Закрыть'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Открыть обращение'),
          ),
        ],
      ),
    );
    if (openTicket == true && context.mounted) {
      context.push('/support/${receipt.id}');
    }
  }

  Future<void> _createAct(
    BuildContext context,
    WidgetRef ref,
    ParticipantBooking booking,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final initialAuth = container.read(authControllerProvider);
    if (initialAuth is! AuthAuthenticated) return;
    final stage = booking.status == 'CONFIRMED' ? 'HANDOVER' : 'RETURN';
    final label = stage == 'HANDOVER' ? 'передачи' : 'возврата';
    HandoverReadinessInput? readiness;
    if (stage == 'HANDOVER') {
      readiness = await showDialog<HandoverReadinessInput>(
        context: context,
        builder: (_) => const _ReadinessDialog(),
      );
      if (readiness == null || !context.mounted) {
        return;
      }
    } else {
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
    }
    final allowed = await requestPermissionFromUserAction(
      context: context,
      ref: ref,
      permission: AppPermission.photos,
    );
    if (!allowed) {
      return;
    }
    final photo = await container.read(bookingEvidencePickerProvider).pick();
    if (photo == null) {
      return;
    }
    await container
        .read(authControllerProvider.notifier)
        .waitForSessionValidation();
    if (container.read(bookingActionProvider).isLoading) {
      await container
          .read(bookingActionProvider.future)
          .catchError((Object _) => null);
    }
    final currentAuth = container.read(authControllerProvider);
    if (currentAuth is! AuthAuthenticated ||
        currentAuth.user.id != initialAuth.user.id) {
      return;
    }
    await container
        .read(bookingActionProvider.notifier)
        .createAct(
          bookingId: booking.id,
          stage: stage,
          photo: photo,
          readiness: readiness,
        );
    if (context.mounted &&
        container.read(bookingActionProvider).asData?.value == booking.id) {
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

  Future<void> _runFakeCheckout(
    BuildContext context,
    WidgetRef ref,
    ParticipantBooking booking,
    String outcome,
  ) async {
    final result = await ref
        .read(bookingActionProvider.notifier)
        .fakeCheckout(bookingId: booking.id, outcome: outcome);
    if (result == null || !context.mounted) return;
    final message = switch (result.outcome) {
      'SUCCEEDED' => 'Тестовая оплата подтверждена сервером',
      'DECLINED' => 'Тестовая оплата отклонена',
      _ => 'Тестовая оплата не завершена. Можно повторить.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<XFile?> _pickDisputePhoto(BuildContext context, WidgetRef ref) async {
    final allowed = await requestPermissionFromUserAction(
      context: context,
      ref: ref,
      permission: AppPermission.photos,
    );
    if (!allowed || !context.mounted) return null;
    return ref.read(bookingEvidencePickerProvider).pick();
  }

  Future<void> _openFinancialDispute(
    BuildContext context,
    WidgetRef ref,
    ParticipantBooking booking,
  ) async {
    final submission = await showDialog<_DisputeInput>(
      context: context,
      builder: (_) => const _FinancialDisputeDialog(),
    );
    if (submission == null || !context.mounted) return;
    final dispute = await ref
        .read(bookingActionProvider.notifier)
        .openFinancialDispute(
          bookingId: booking.id,
          reason: submission.reason,
          description: submission.description,
        );
    if (dispute == null || !submission.addPhoto || !context.mounted) return;
    final photo = await _pickDisputePhoto(context, ref);
    if (photo == null || !context.mounted) return;
    await ref
        .read(bookingActionProvider.notifier)
        .addDisputeEvidence(
          bookingId: booking.id,
          disputeId: dispute.id,
          photo: photo,
        );
  }

  Future<void> _addDisputeEvidence(
    BuildContext context,
    WidgetRef ref,
    ParticipantBooking booking,
  ) async {
    final dispute = booking.financialDispute;
    if (dispute == null) return;
    final photo = await _pickDisputePhoto(context, ref);
    if (photo == null || !context.mounted) return;
    await ref
        .read(bookingActionProvider.notifier)
        .addDisputeEvidence(
          bookingId: booking.id,
          disputeId: dispute.id,
          photo: photo,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingDetailsProvider(bookingId));
    final acts = ref.watch(bookingActsProvider(bookingId));
    final reviews = booking.value?.status == 'COMPLETED'
        ? ref.watch(bookingReviewsProvider(bookingId))
        : const AsyncData<List<ParticipantReview>>([]);
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
            reviews: reviews,
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
                    'Заявка будет отменена. Владелец больше не сможет её подтвердить.',
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
            onOpenChat: () => context.push('/bookings/$bookingId/chat'),
            onOpenReview: () => context.push('/bookings/$bookingId/review'),
            onRetryReviews: () =>
                ref.invalidate(bookingReviewsProvider(bookingId)),
            onFakeCheckout: (outcome) =>
                _runFakeCheckout(context, ref, value, outcome),
            onOpenFinancialDispute: () =>
                _openFinancialDispute(context, ref, value),
            onAddDisputeEvidence: () =>
                _addDisputeEvidence(context, ref, value),
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
    required this.reviews,
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
    required this.onOpenChat,
    required this.onOpenReview,
    required this.onRetryReviews,
    required this.onFakeCheckout,
    required this.onOpenFinancialDispute,
    required this.onAddDisputeEvidence,
  });

  final ParticipantBooking booking;
  final AsyncValue<List<BookingAct>> acts;
  final AsyncValue<List<ParticipantReview>> reviews;
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
  final VoidCallback onOpenChat;
  final VoidCallback onOpenReview;
  final VoidCallback onRetryReviews;
  final ValueChanged<String> onFakeCheckout;
  final VoidCallback onOpenFinancialDispute;
  final VoidCallback onAddDisputeEvidence;

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
        Text(
          bookingStatusLabel(booking.status),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Divider(height: 32),
        _NextActionCard(
          booking: booking,
          isLoading: action.isLoading,
          onConfirm: onConfirm,
          onOpenChat: onOpenChat,
          onOpenReview: onOpenReview,
          onReportIssue: onReportIssue,
        ),
        const Divider(height: 32),
        Text('Даты', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
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
          _Row(label: 'Ответ владельца до', value: _time(booking.expiresAt!)),
        if (booking.cancellationReason != null)
          _Row(
            label: 'Причина',
            value: _cancellationReason(booking.cancellationReason!),
          ),
        if (terms != null) ...[
          const Divider(height: 32),
          Text('Цена и условия', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _Row(
            label: 'Владелец',
            value: terms.lenderDisplayName ?? 'Имя не указано',
          ),
          _Row(
            label:
                '${_bookingMoney(terms.moneyMinor?.pricePerDay, terms.pricePerDay)} ₽ × ${terms.days} дн.',
            value:
                '${_bookingMoney(terms.moneyMinor?.rentalSubtotal, terms.rentalSubtotal)} ₽',
          ),
          _Row(
            label: 'Залог',
            value: terms.moneyMinor != null
                ? (terms.moneyMinor!.deposit == 0
                      ? 'Нет'
                      : '${_minorMoney(terms.moneyMinor!.deposit)} ₽')
                : terms.depositAmount == null
                ? 'Нет'
                : '${_money(terms.depositAmount!)} ₽',
          ),
          if (terms.paymentScenario != 'PAY_ON_HANDOVER')
            _Row(
              label: 'Комиссия сервиса',
              value:
                  '${_bookingMoney(terms.moneyMinor?.platformFee, terms.platformFee)} ₽',
            ),
          if (booking.actorRole == 'LENDER' && booking.status != 'CANCELLED')
            _Row(
              label: 'Вы получите',
              value:
                  '${_bookingMoney(terms.moneyMinor?.ownerPayout, terms.ownerPayout)} ₽',
            ),
          _Row(
            label: 'Итого',
            value: '${_bookingMoney(terms.moneyMinor?.total, terms.total)} ₽',
          ),
          _Row(
            label: 'Оплата',
            value: terms.paymentScenario == 'PAY_ON_HANDOVER'
                ? 'При передаче вещи'
                : 'В приложении',
          ),
        ],
        if (terms?.paymentScenario == 'FAKE_SAFE_DEAL' &&
            booking.actorRole == 'BORROWER' &&
            booking.status == 'CONFIRMED' &&
            booking.payment?.status != 'SUCCEEDED') ...[
          const SizedBox(height: 16),
          _FakeCheckoutCard(
            isLoading: action.isLoading,
            onOutcome: onFakeCheckout,
          ),
        ],
        if (booking.deposit != null) ...[
          const Divider(height: 32),
          _DepositCard(
            booking: booking,
            isLoading: action.isLoading,
            onOpenDispute: onOpenFinancialDispute,
            onAddEvidence: onAddDisputeEvidence,
          ),
        ],
        if (booking.handover != null) ...[
          const Divider(height: 32),
          Text('Передача', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _Row(label: 'Адрес', value: booking.handover!.address),
          if (booking.counterpartyContact != null)
            _Row(label: 'Контакт', value: booking.counterpartyContact!),
        ],
        const Divider(height: 32),
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
        if (booking.status == 'COMPLETED') ...[
          const Divider(height: 32),
          Text('Отзыв', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          reviews.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    userFacingError(
                      error,
                      fallback: 'Не удалось проверить отзыв',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetryReviews,
                  child: const Text('Повторить'),
                ),
              ],
            ),
            data: (values) {
              final hasOwnReview = values.any(
                (review) => review.author == 'SELF',
              );
              return FilledButton.icon(
                onPressed: onOpenReview,
                icon: Icon(
                  hasOwnReview
                      ? Icons.check_circle_outline
                      : Icons.star_outline,
                ),
                label: Text(
                  hasOwnReview ? 'Посмотреть свой отзыв' : 'Оставить отзыв',
                ),
              );
            },
          ),
        ],
        const Divider(height: 32),
        Text('Поддержка', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (actionError != null) ...[
          Text(
            userFacingError(
              actionError,
              fallback: 'Не удалось выполнить действие',
            ),
          ),
        ],
        if (booking.status == 'PENDING') ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: action.isLoading ? null : onCancel,
            child: const Text('Отменить заявку'),
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

class _FakeCheckoutCard extends StatelessWidget {
  const _FakeCheckoutCard({required this.isLoading, required this.onOutcome});

  final bool isLoading;
  final ValueChanged<String> onOutcome;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Тестовый сценарий оплаты',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Только для проверки: деньги не списываются. Результат '
              'сохраняется сервером в этой брони.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: isLoading ? null : () => onOutcome('SUCCESS'),
                  child: const Text('Успех'),
                ),
                OutlinedButton(
                  onPressed: isLoading ? null : () => onOutcome('DECLINE'),
                  child: const Text('Отказ'),
                ),
                OutlinedButton(
                  onPressed: isLoading ? null : () => onOutcome('TIMEOUT'),
                  child: const Text('Таймаут'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DepositCard extends StatelessWidget {
  const _DepositCard({
    required this.booking,
    required this.isLoading,
    required this.onOpenDispute,
    required this.onAddEvidence,
  });

  final ParticipantBooking booking;
  final bool isLoading;
  final VoidCallback onOpenDispute;
  final VoidCallback onAddEvidence;

  @override
  Widget build(BuildContext context) {
    final deposit = booking.deposit!;
    final dispute = booking.financialDispute;
    final deadline = deposit.disputeWindowEndsAt;
    final canOpen =
        booking.status == 'RETURNED' &&
        deposit.status == 'HELD' &&
        dispute == null &&
        deadline != null &&
        DateTime.now().isBefore(deadline);
    final canAddEvidence =
        dispute != null &&
        (dispute.status == 'OPEN' || dispute.status == 'UNDER_REVIEW');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Залог', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        _Row(label: 'Сумма', value: '${_minorMoney(deposit.amountMinor)} ₽'),
        _Row(label: 'Статус', value: _depositStatus(deposit.status)),
        if (deadline != null)
          _Row(label: 'Открыть спор до', value: _time(deadline)),
        if (dispute != null) ...[
          const SizedBox(height: 8),
          Text(
            'Финансовый спор',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          _Row(label: 'Причина', value: _disputeReason(dispute.reason)),
          _Row(label: 'Статус спора', value: _disputeStatus(dispute.status)),
          if (dispute.description != null) Text(dispute.description!),
          if (dispute.evidence.isNotEmpty)
            Text('Фото: ${dispute.evidence.length}'),
        ],
        if (canOpen)
          FilledButton(
            onPressed: isLoading ? null : onOpenDispute,
            child: const Text('Открыть финансовый спор'),
          ),
        if (canAddEvidence)
          OutlinedButton.icon(
            onPressed: isLoading ? null : onAddEvidence,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Добавить фото к спору'),
          ),
      ],
    );
  }
}

class _DisputeInput {
  const _DisputeInput({
    required this.reason,
    required this.description,
    required this.addPhoto,
  });

  final String reason;
  final String description;
  final bool addPhoto;
}

class _FinancialDisputeDialog extends StatefulWidget {
  const _FinancialDisputeDialog();

  @override
  State<_FinancialDisputeDialog> createState() =>
      _FinancialDisputeDialogState();
}

class _FinancialDisputeDialogState extends State<_FinancialDisputeDialog> {
  final _formKey = GlobalKey<FormState>();
  var _reason = 'ITEM_DAMAGED';
  var _description = '';
  var _addPhoto = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Открыть финансовый спор'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InlineSelectField<String>(
              value: _reason,
              decoration: const InputDecoration(labelText: 'Причина'),
              items: const [
                DropdownMenuItem(
                  value: 'ITEM_DAMAGED',
                  child: Text('Вещь повреждена'),
                ),
                DropdownMenuItem(
                  value: 'ITEM_LOST',
                  child: Text('Вещь потеряна'),
                ),
                DropdownMenuItem(value: 'OTHER', child: Text('Другое')),
              ],
              onChanged: (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: 12),
            TextFormField(
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Факты',
                hintText: 'Опишите факты без платёжных и паспортных данных',
              ),
              onChanged: (value) => _description = value,
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 10 || length > 2000) {
                  return 'Введите от 10 до 2000 символов';
                }
                return null;
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _addPhoto,
              onChanged: (value) => setState(() => _addPhoto = value ?? false),
              title: const Text('Добавить фото после открытия'),
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
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _DisputeInput(
                reason: _reason,
                description: _description.trim(),
                addPhoto: _addPhoto,
              ),
            );
          },
          child: const Text('Открыть спор'),
        ),
      ],
    );
  }
}

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({
    required this.booking,
    required this.isLoading,
    required this.onConfirm,
    required this.onOpenChat,
    required this.onOpenReview,
    required this.onReportIssue,
  });

  final ParticipantBooking booking;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenReview;
  final VoidCallback? onReportIssue;

  @override
  Widget build(BuildContext context) {
    final nextAction = booking.nextAction;
    final step = switch (booking.status) {
      'PENDING' => 1,
      'CONFIRMED' => 2,
      'ACTIVE' => 3,
      'RETURNED' => 4,
      'COMPLETED' => 5,
      _ => 1,
    };
    final primaryAction = switch (nextAction.code) {
      'REVIEW_REQUEST' => onConfirm,
      'LEAVE_REVIEW' => onOpenReview,
      'NONE' => null,
      _ => onOpenChat,
    };
    final primaryLabel = switch (nextAction.code) {
      'REVIEW_REQUEST' => 'Подтвердить бронирование',
      'LEAVE_REVIEW' => 'Оставить отзыв',
      _ => 'Открыть чат',
    };

    return Container(
      key: const ValueKey('booking-next-action'),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Следующее действие',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              nextAction.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(nextAction.description),
            Text(
              booking.status == 'CANCELLED'
                  ? 'Заявка отменена'
                  : 'Этап $step из 5',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (primaryAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : primaryAction,
                child: Text(primaryLabel),
              ),
            ],
            if (nextAction.code == 'REVIEW_REQUEST' ||
                nextAction.code == 'LEAVE_REVIEW')
              TextButton.icon(
                onPressed: onOpenChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Открыть чат'),
              ),
            if (onReportIssue != null)
              TextButton.icon(
                onPressed: isLoading ? null : onReportIssue,
                icon: const Icon(Icons.support_agent),
                label: const Text('Есть проблема'),
              ),
          ],
        ),
      ),
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
    final canCreateCurrentAct = switch (currentStage) {
      'HANDOVER' => booking.actorRole == 'LENDER',
      'RETURN' => booking.actorRole == 'BORROWER',
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (values.isEmpty) const Text('Актов пока нет'),
        for (final act in values)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE4E8EB))),
            ),
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
                  if (act.readiness case final readiness?) ...[
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Чек-лист готовности',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Text('✓ Вещь исправна'),
                            const Text('✓ Комплектация полная'),
                            Text(
                              'Видимые дефекты: ${readiness.visibleDefects}',
                            ),
                            Text('Отмечено: ${_time(readiness.declaredAt)}'),
                            const SizedBox(height: 4),
                            const Text(
                              'Заявление владельца, не проверка Sosedi.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
        if (currentStage != null &&
            currentUserId != null &&
            canCreateCurrentAct &&
            !hasOwnCurrentAct)
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

class _ReadinessDialog extends StatefulWidget {
  const _ReadinessDialog();

  @override
  State<_ReadinessDialog> createState() => _ReadinessDialogState();
}

class _ReadinessDialogState extends State<_ReadinessDialog> {
  final _defectsController = TextEditingController();
  var _isWorking = false;
  var _isComplete = false;

  bool get _canContinue =>
      _isWorking && _isComplete && _defectsController.text.trim().length >= 2;

  @override
  void dispose() {
    _defectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Готовность к передаче'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Перед снимком подтвердите состояние вещи. '
              'Ответы сохранятся вместе с актом.',
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isWorking,
              onChanged: (value) => setState(() => _isWorking = value ?? false),
              title: const Text('Вещь исправна'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isComplete,
              onChanged: (value) =>
                  setState(() => _isComplete = value ?? false),
              title: const Text('Комплектация полная'),
            ),
            TextField(
              controller: _defectsController,
              maxLength: 500,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Видимые дефекты',
                hintText: 'Например: нет или потёртость на ручке',
              ),
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
          onPressed: _canContinue
              ? () => Navigator.pop(
                  context,
                  HandoverReadinessInput(
                    isWorking: _isWorking,
                    isComplete: _isComplete,
                    visibleDefects: _defectsController.text.trim(),
                  ),
                )
              : null,
          child: const Text('Выбрать снимок'),
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

String _cancellationReason(String reason) => switch (reason) {
  'BORROWER_CANCELLED' => 'Отменено арендатором',
  'LENDER_DECLINED' => 'Отклонено владельцем',
  'COMPETING_REQUEST_CONFIRMED' => 'Выбрана другая заявка на эти даты',
  _ => 'Заявка отменена',
};

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

String _minorMoney(int value) {
  final whole = value ~/ 100;
  final fraction = (value % 100).abs();
  return fraction == 0
      ? whole.toString()
      : '$whole,${fraction.toString().padLeft(2, '0')}';
}

String _bookingMoney(int? minor, double legacy) =>
    minor == null ? _money(legacy) : _minorMoney(minor);

String _depositStatus(String status) => switch (status) {
  'PENDING' => 'Ожидает тестовой оплаты',
  'HELD' => 'Удерживается',
  'DISPUTED' => 'Открыт спор',
  'RESOLVING' => 'Возврат/выплата обрабатывается',
  'RESOLVED' => 'Возвращён/распределён',
  'CANCELLED' => 'Отменён',
  _ => status,
};

String _disputeReason(String reason) => switch (reason) {
  'ITEM_DAMAGED' => 'Вещь повреждена',
  'ITEM_LOST' => 'Вещь потеряна',
  'OTHER' => 'Другое',
  _ => reason,
};

String _disputeStatus(String status) => switch (status) {
  'OPEN' => 'Открыт',
  'UNDER_REVIEW' => 'На рассмотрении',
  'RESOLVED' => 'Решён',
  _ => status,
};

String _time(DateTime value) =>
    '${bookingDate(value.toLocal())} '
    '${value.toLocal().hour.toString().padLeft(2, '0')}:'
    '${value.toLocal().minute.toString().padLeft(2, '0')}';

String _supportStatus(String status) => switch (status) {
  'OPEN' => 'Открыто',
  'IN_PROGRESS' => 'В работе',
  'CLOSED' => 'Закрыто',
  _ => status,
};
