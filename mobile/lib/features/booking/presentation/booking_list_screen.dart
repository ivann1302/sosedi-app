import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../notifications/data/inbox_event.dart';
import '../../notifications/data/inbox_service.dart';
import '../data/booking_models.dart';
import '../data/booking_service.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<BookingListScreen> createState() =>
      _BookingListScreenState();
}

enum _BookingLifecycleFilter { current, history }

enum _BookingRoleFilter { all, borrower, lender }

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  _BookingLifecycleFilter _lifecycle = _BookingLifecycleFilter.current;
  _BookingRoleFilter _role = _BookingRoleFilter.all;

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    final unreadByBooking = <String, int>{};
    for (final event
        in ref.watch(inboxEventsProvider).value ?? const <InboxEvent>[]) {
      final bookingId = event.bookingId;
      if (bookingId != null &&
          event.eventType == 'BOOKING_MESSAGE_CREATED' &&
          event.readAt == null) {
        unreadByBooking.update(bookingId, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Мои бронирования')),
      body: SafeArea(
        child: bookings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userFacingError(
                    error,
                    fallback: 'Не удалось загрузить бронирования',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(myBookingsProvider),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
          data: (values) {
            final filtered = values.where(_matchesFilters).toList();
            return Column(
              children: [
                _BookingFilters(
                  lifecycle: _lifecycle,
                  role: _role,
                  onLifecycleChanged: (value) =>
                      setState(() => _lifecycle = value),
                  onRoleChanged: (value) => setState(() => _role = value),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            values.isEmpty
                                ? 'Бронирований пока нет'
                                : 'Нет бронирований по выбранным фильтрам',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              ref.refresh(myBookingsProvider.future),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) => _BookingCard(
                              booking: filtered[index],
                              unreadCount:
                                  unreadByBooking[filtered[index].id] ?? 0,
                            ),
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

  bool _matchesFilters(ParticipantBooking booking) {
    final isHistory = booking.status == 'COMPLETED' ||
        booking.status == 'CANCELLED';
    if ((_lifecycle == _BookingLifecycleFilter.history) != isHistory) {
      return false;
    }
    return switch (_role) {
      _BookingRoleFilter.all => true,
      _BookingRoleFilter.borrower => booking.actorRole == 'BORROWER',
      _BookingRoleFilter.lender => booking.actorRole == 'LENDER',
    };
  }
}

class _BookingFilters extends StatelessWidget {
  const _BookingFilters({
    required this.lifecycle,
    required this.role,
    required this.onLifecycleChanged,
    required this.onRoleChanged,
  });

  final _BookingLifecycleFilter lifecycle;
  final _BookingRoleFilter role;
  final ValueChanged<_BookingLifecycleFilter> onLifecycleChanged;
  final ValueChanged<_BookingRoleFilter> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        children: [
          ChoiceChip(
            label: const Text('Текущие'),
            selected: lifecycle == _BookingLifecycleFilter.current,
            onSelected: (_) =>
                onLifecycleChanged(_BookingLifecycleFilter.current),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('История'),
            selected: lifecycle == _BookingLifecycleFilter.history,
            onSelected: (_) =>
                onLifecycleChanged(_BookingLifecycleFilter.history),
          ),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('Все роли'),
            selected: role == _BookingRoleFilter.all,
            onSelected: (_) => onRoleChanged(_BookingRoleFilter.all),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Беру'),
            selected: role == _BookingRoleFilter.borrower,
            onSelected: (_) => onRoleChanged(_BookingRoleFilter.borrower),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Сдаю'),
            selected: role == _BookingRoleFilter.lender,
            onSelected: (_) => onRoleChanged(_BookingRoleFilter.lender),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.unreadCount});

  final ParticipantBooking booking;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/bookings/${booking.id}'),
        leading: Icon(
          booking.actorRole == 'LENDER'
              ? Icons.inventory_2_outlined
              : Icons.shopping_bag_outlined,
        ),
        title: Text(booking.terms?.itemTitle ?? 'Бронирование'),
        subtitle: Text(
          '${_status(booking.status)} · '
          '${_date(booking.startDate)}–${_date(booking.endDate)}\n'
          '${booking.actorRole == 'LENDER' ? 'Вы сдаёте' : 'Вы арендуете'}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unreadCount > 0)
              Badge.count(
                count: unreadCount,
                child: const Icon(Icons.chat_bubble_outline),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

String bookingStatusLabel(String status) => switch (status) {
  'PENDING' => 'Ожидает подтверждения',
  'CONFIRMED' => 'Подтверждено',
  'ACTIVE' => 'В аренде',
  'RETURNED' => 'Возвращено',
  'COMPLETED' => 'Завершено',
  'CANCELLED' => 'Отменено',
  _ => status,
};

String _status(String status) => bookingStatusLabel(status);

String bookingDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

String _date(DateTime value) => bookingDate(value);
