import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../data/booking_models.dart';
import '../data/booking_service.dart';

class BookingListScreen extends ConsumerWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
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
          data: (values) => values.isEmpty
              ? const Center(child: Text('Бронирований пока нет'))
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(myBookingsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _BookingCard(booking: values[index]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final ParticipantBooking booking;

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
        trailing: const Icon(Icons.chevron_right),
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
