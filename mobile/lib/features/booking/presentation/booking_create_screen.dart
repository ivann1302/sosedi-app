import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/marketplace_documents_config.dart';
import '../../../core/network/api_exception.dart';
import '../../item/data/item_service.dart';
import '../domain/booking_availability_controller.dart';
import '../domain/booking_create_controller.dart';
import '../domain/booking_date_rules.dart';

class BookingCreateScreen extends ConsumerStatefulWidget {
  const BookingCreateScreen({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<BookingCreateScreen> createState() =>
      _BookingCreateScreenState();
}

class _BookingCreateScreenState extends ConsumerState<BookingCreateScreen> {
  DateTime? _start;
  DateTime? _end;
  bool _offerAccepted = false;
  bool _rentalRulesAccepted = false;

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemDetailsProvider(widget.itemId));
    final availability = ref.watch(bookingAvailabilityProvider);
    final creation = ref.watch(bookingCreateProvider);
    final marketplaceTerms = ref.watch(marketplaceDocumentsConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор дат')),
      body: SafeArea(
        child: item.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userFacingError(
                    error,
                    fallback: 'Не удалось загрузить объявление',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(itemDetailsProvider(widget.itemId)),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
          data: (value) {
            final days = _start != null && _end != null
                ? inclusiveBookingDays(_start!, _end!)
                : null;
            final total = days == null ? null : days * value.pricePerDay;
            final canSubmit =
                marketplaceTerms.isBookingReady &&
                days != null &&
                availability.value?.available == true &&
                _offerAccepted &&
                _rentalRulesAccepted &&
                !creation.isLoading;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  value.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('${_money(value.pricePerDay)} ₽ / день'),
                const SizedBox(height: 24),
                _DateTile(
                  label: 'Начало',
                  value: _start,
                  onTap: () => _pickStart(context),
                ),
                const SizedBox(height: 12),
                _DateTile(
                  label: 'Окончание включительно',
                  value: _end,
                  onTap: _start == null ? null : () => _pickEnd(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'От 1 до $bookingMaxDays дней, не более чем на '
                  '$bookingHorizonDays дней вперёд. Обе даты входят в аренду.',
                ),
                if (_start != null && _end != null) ...[
                  const SizedBox(height: 16),
                  availability.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud_off_outlined),
                        title: Text(
                          userFacingError(
                            error,
                            fallback: 'Не удалось проверить доступность',
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: _checkAvailability,
                          child: const Text('Повторить'),
                        ),
                      ),
                    ),
                    data: (result) => result == null
                        ? const SizedBox.shrink()
                        : Card(
                            child: ListTile(
                              leading: Icon(
                                result.available
                                    ? Icons.event_available_outlined
                                    : Icons.event_busy_outlined,
                              ),
                              title: Text(
                                result.available
                                    ? 'Выбранные даты свободны'
                                    : 'На выбранные даты вещь недоступна',
                              ),
                            ),
                          ),
                  ),
                ],
                if (days != null && total != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Предварительный расчёт',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _PriceLine(
                            label: '${_money(value.pricePerDay)} ₽ × $days дн.',
                            value: '${_money(total)} ₽',
                          ),
                          _PriceLine(
                            label: 'Залог',
                            value:
                                value.depositAmount == null ||
                                    value.depositAmount == 0
                                ? 'Нет'
                                : '${_money(value.depositAmount!)} ₽',
                          ),
                          const _PriceLine(
                            label: 'Комиссия Sosedi (офлайн-пилот)',
                            value: '0 ₽',
                          ),
                          _PriceLine(
                            label: 'Выплата владельцу',
                            value: '${_money(total)} ₽',
                          ),
                          const _PriceLine(
                            label: 'Оплата',
                            value: 'При передаче вещи',
                          ),
                          const _PriceLine(label: 'Валюта', value: 'RUB'),
                          const Divider(),
                          _PriceLine(
                            label: 'Итого',
                            value: '${_money(total)} ₽',
                            strong: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.schedule_outlined),
                    title: Text('Владелец ответит в течение 12 часов'),
                    subtitle: Text(
                      'До подтверждения даты не зарезервированы. Если владелец '
                      'примет другую пересекающуюся заявку, эта заявка отменится.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.payments_outlined),
                    title: Text('Оплата при передаче вещи'),
                    subtitle: Text(
                      'Офлайн-пилот: комиссия Sosedi 0 ₽. '
                      'Приложение не принимает оплату и не переводит деньги.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (marketplaceTerms.isBookingReady)
                  _MarketplaceTermsCard(
                    terms: marketplaceTerms,
                    offerAccepted: _offerAccepted,
                    rentalRulesAccepted: _rentalRulesAccepted,
                    onOfferAccepted: (value) =>
                        setState(() => _offerAccepted = value),
                    onRentalRulesAccepted: (value) =>
                        setState(() => _rentalRulesAccepted = value),
                    onOpenOffer: () =>
                        _openDocument(marketplaceTerms.offerUri!),
                    onOpenRentalRules: () =>
                        _openDocument(marketplaceTerms.rentalRulesUri!),
                  )
                else
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.gavel_outlined),
                      title: Text('Запуск бронирования готовится'),
                      subtitle: Text(
                        'Отправка заявки откроется после публикации оферты, '
                        'правил отмены и страниц поддержки.',
                      ),
                    ),
                  ),
                if (creation.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    userFacingError(
                      creation.error!,
                      fallback: 'Не удалось отправить заявку',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: canSubmit ? () => _submit(marketplaceTerms) : null,
                  child: creation.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          marketplaceTerms.isBookingReady
                              ? 'Отправить заявку'
                              : 'Отправка пока недоступна',
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickStart(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _start ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: bookingHorizonDays)),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _start = selected;
      if (_end == null || _end!.isBefore(selected)) {
        _end = selected;
      }
    });
    await _checkAvailability();
  }

  Future<void> _pickEnd(BuildContext context) async {
    final start = _start;
    if (start == null) {
      return;
    }
    final selected = await showDatePicker(
      context: context,
      initialDate: _end ?? start,
      firstDate: start,
      lastDate: start.add(const Duration(days: bookingMaxDays - 1)),
    );
    if (selected != null && mounted) {
      setState(() => _end = selected);
      await _checkAvailability();
    }
  }

  Future<void> _checkAvailability() async {
    final start = _start;
    final end = _end;
    if (start == null || end == null) {
      return;
    }
    await ref
        .read(bookingAvailabilityProvider.notifier)
        .check(itemId: widget.itemId, startDate: start, endDate: end);
  }

  Future<void> _submit(MarketplaceDocumentsConfig terms) async {
    final start = _start;
    final end = _end;
    if (start == null ||
        end == null ||
        !_offerAccepted ||
        !_rentalRulesAccepted ||
        ref.read(bookingAvailabilityProvider).value?.available != true) {
      return;
    }
    await ref
        .read(bookingCreateProvider.notifier)
        .submit(
          itemId: widget.itemId,
          startDate: start,
          endDate: end,
          terms: terms,
        );
    if (!mounted) {
      return;
    }
    final result = ref.read(bookingCreateProvider);
    if (result case AsyncData(value: final bookingId?)) {
      context.go('/bookings/$bookingId');
    }
  }

  Future<void> _openDocument(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // The user receives one safe message below.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть документ')),
      );
    }
  }
}

class _MarketplaceTermsCard extends StatelessWidget {
  const _MarketplaceTermsCard({
    required this.terms,
    required this.offerAccepted,
    required this.rentalRulesAccepted,
    required this.onOfferAccepted,
    required this.onRentalRulesAccepted,
    required this.onOpenOffer,
    required this.onOpenRentalRules,
  });

  final MarketplaceDocumentsConfig terms;
  final bool offerAccepted;
  final bool rentalRulesAccepted;
  final ValueChanged<bool> onOfferAccepted;
  final ValueChanged<bool> onRentalRulesAccepted;
  final VoidCallback onOpenOffer;
  final VoidCallback onOpenRentalRules;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.gavel_outlined),
              title: Text('Условия бронирования'),
              subtitle: Text(
                'Перед отправкой проверьте обе опубликованные версии.',
              ),
            ),
            TextButton(
              onPressed: onOpenOffer,
              child: Text('Открыть оферту · ${terms.offerVersion}'),
            ),
            CheckboxListTile(
              value: offerAccepted,
              onChanged: (value) => onOfferAccepted(value ?? false),
              title: const Text('Принимаю оферту'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextButton(
              onPressed: onOpenRentalRules,
              child: Text(
                'Открыть правила аренды и отмены · '
                '${terms.cancellationPolicyVersion}',
              ),
            ),
            CheckboxListTile(
              value: rentalRulesAccepted,
              onChanged: (value) => onRentalRulesAccepted(value ?? false),
              title: const Text('Принимаю правила аренды и отмены'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: ${value == null ? 'выберите' : _date(value!)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? Theme.of(context).textTheme.titleMedium : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

String _money(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
