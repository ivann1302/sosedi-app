import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../../auth/domain/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../reviews/data/review_models.dart';
import '../../reviews/data/review_service.dart';
import '../../safety/domain/safety_action_controller.dart';
import '../../safety/presentation/report_dialog.dart';
import '../data/booking_models.dart';
import '../data/booking_service.dart';
import '../domain/booking_action_controller.dart';
import '../domain/demo_payment_controller.dart';
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
    if (!allowed || !context.mounted) {
      return;
    }
    final photo = await ref.read(bookingEvidencePickerProvider).pick();
    if (photo == null || !context.mounted) {
      return;
    }
    await ref
        .read(bookingActionProvider.notifier)
        .createAct(
          bookingId: booking.id,
          stage: stage,
          photo: photo,
          readiness: readiness,
        );
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
        const SizedBox(height: 8),
        _NextActionCard(
          booking: booking,
          isLoading: action.isLoading,
          onConfirm: onConfirm,
          onOpenChat: onOpenChat,
          onOpenReview: onOpenReview,
          onReportIssue: onReportIssue,
        ),
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
          _Row(label: 'Ответ владельца до', value: _time(booking.expiresAt!)),
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
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Технические детали'),
            children: [
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
          ),
        ],
        if (AppConfig.demoStubsEnabled &&
            booking.actorRole == 'BORROWER' &&
            booking.status == 'CONFIRMED' &&
            terms != null) ...[
          const SizedBox(height: 16),
          _DemoPaymentCard(
            bookingId: booking.id,
            total: terms.total,
            currency: terms.currency,
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
        if (booking.status == 'COMPLETED') ...[
          const SizedBox(height: 16),
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
        if (actionError != null) ...[
          const SizedBox(height: 12),
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

class _DemoPaymentCard extends ConsumerWidget {
  const _DemoPaymentCard({
    required this.bookingId,
    required this.total,
    required this.currency,
  });

  final String bookingId;
  final double total;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payment = demoPaymentProvider(bookingId);
    final result = ref.watch(payment);
    final status = switch (result) {
      DemoPaymentResult.idle => null,
      DemoPaymentResult.processing => 'Обработка тестовой оплаты…',
      DemoPaymentResult.succeeded => 'Тестовая оплата успешна',
      DemoPaymentResult.declined => 'Тестовый отказ оплаты',
    };
    final isProcessing = result == DemoPaymentResult.processing;
    final statusIcon = result == DemoPaymentResult.succeeded
        ? Icons.check_circle_outline
        : Icons.error_outline;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Тестовая оплата',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Демо-заглушка. Деньги не списываются, серверное состояние '
              'брони не меняется.',
            ),
            const SizedBox(height: 8),
            Text(
              'Сумма: ${_money(total)} $currency',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (status != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (isProcessing)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(statusIcon),
                  const SizedBox(width: 8),
                  Expanded(child: Text(status)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isProcessing
                  ? null
                  : () => ref.read(payment.notifier).succeed(),
              child: Text(isProcessing ? 'Обработка…' : 'Успешная оплата'),
            ),
            OutlinedButton(
              onPressed: isProcessing
                  ? null
                  : () => ref.read(payment.notifier).decline(),
              child: const Text('Отказ оплаты'),
            ),
          ],
        ),
      ),
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

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
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
            const SizedBox(height: 12),
            LinearProgressIndicator(value: step / 5),
            const SizedBox(height: 6),
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
                  if (act.readiness case final readiness?) ...[
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
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

String _supportStatus(String status) => switch (status) {
  'OPEN' => 'Открыто',
  'IN_PROGRESS' => 'В работе',
  'CLOSED' => 'Закрыто',
  _ => status,
};
