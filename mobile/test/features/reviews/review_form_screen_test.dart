import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/booking/data/booking_models.dart';
import 'package:mobile/features/booking/data/booking_service.dart';
import 'package:mobile/features/reviews/data/review_models.dart';
import 'package:mobile/features/reviews/data/review_service.dart';
import 'package:mobile/features/reviews/presentation/review_form_screen.dart';

void main() {
  testWidgets('does not offer a form for an unfinished booking', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => booking),
          bookingReviewsProvider(
            booking.id,
          ).overrideWith((ref) async => <ParticipantReview>[]),
        ],
        child: MaterialApp(home: ReviewFormScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Оценить можно только полностью завершённую аренду.'),
      findsOneWidget,
    );
    expect(find.text('Отправить отзыв'), findsNothing);
  });

  testWidgets('shows an immutable submitted review instead of an edit form', (
    tester,
  ) async {
    final completed = booking.copyWith(status: 'COMPLETED', expiresAt: null);
    final ownReview = ParticipantReview(
      id: 'review-1',
      author: 'SELF',
      rating: 5,
      text: 'Всё прошло отлично.',
      published: false,
      hidden: false,
      publishAt: DateTime.utc(2026, 8, 23),
      createdAt: DateTime.utc(2026, 8, 9),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => completed),
          bookingReviewsProvider(
            booking.id,
          ).overrideWith((ref) async => [ownReview]),
        ],
        child: MaterialApp(home: ReviewFormScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Отзыв сохранён'), findsOneWidget);
    expect(find.text('Всё прошло отлично.'), findsOneWidget);
    expect(find.text('Отправить отзыв'), findsNothing);
  });

  testWidgets('explains a moderated review without offering an edit', (
    tester,
  ) async {
    final completed = booking.copyWith(status: 'COMPLETED', expiresAt: null);
    final hiddenReview = ParticipantReview(
      id: 'review-hidden',
      author: 'SELF',
      rating: 1,
      text: 'Текст отзыва был скрыт после проверки.',
      published: true,
      hidden: true,
      publishAt: DateTime.utc(2026, 8, 9),
      createdAt: DateTime.utc(2026, 8, 9),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => completed),
          bookingReviewsProvider(
            booking.id,
          ).overrideWith((ref) async => [hiddenReview]),
        ],
        child: MaterialApp(home: ReviewFormScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Отзыв скрыт после проверки'), findsOneWidget);
    expect(
      find.textContaining('можно обжаловать через поддержку'),
      findsOneWidget,
    );
    expect(find.text('Отправить отзыв'), findsNothing);
  });
}

final booking = ParticipantBooking(
  id: 'booking-1',
  itemId: 'item-1',
  actorRole: 'BORROWER',
  startDate: DateTime.utc(2026, 8, 1),
  endDate: DateTime.utc(2026, 8, 2),
  status: 'ACTIVE',
  nextAction: const BookingNextAction(
    code: 'USE_ITEM',
    title: 'Верните вещь в согласованный срок',
    description: 'Сохраните комплектность и согласуйте возврат в чате.',
  ),
  expiresAt: null,
  cancellationReason: null,
  terms: null,
  handover: null,
  counterpartyContact: null,
  createdAt: DateTime.utc(2026, 7, 29),
);
