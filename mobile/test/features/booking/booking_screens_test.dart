import 'package:mobile/features/booking/domain/booking_action_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/config/marketplace_documents_config.dart';
import 'package:mobile/core/permissions/app_permissions.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/booking/data/booking_models.dart';
import 'package:mobile/features/booking/data/booking_service.dart';
import 'package:mobile/features/booking/presentation/booking_create_screen.dart';
import 'package:mobile/features/booking/presentation/booking_details_screen.dart';
import 'package:mobile/features/booking/presentation/booking_list_screen.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/item/data/item_service.dart';
import 'package:mobile/features/payments/data/marketplace_policy_models.dart';
import 'package:mobile/features/payments/data/marketplace_policy_service.dart';
import 'package:mobile/features/reviews/data/review_models.dart';
import 'package:mobile/features/reviews/data/review_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../support/network_fakes.dart';

void main() {
  testWidgets('shows date rules and keeps public submit behind legal gate', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider('item-1').overrideWith((ref) async => item),
        ],
        child: const MaterialApp(home: BookingCreateScreen(itemId: 'item-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Выбор дат'), findsOneWidget);
    expect(find.textContaining('Обе даты входят'), findsOneWidget);
    expect(find.text('Оплата при передаче вещи'), findsOneWidget);
    expect(find.textContaining('Доплаты сервису нет'), findsOneWidget);
    expect(find.text('Запуск бронирования готовится'), findsOneWidget);
    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Отправка пока недоступна'),
    );
    expect(submit.onPressed, isNull);
  });

  testWidgets('shows a server-backed unavailable result for selected dates', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _AvailabilityBookingService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(item.id).overrideWith((ref) async => item),
          bookingServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(home: BookingCreateScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Начало: выберите'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(service.availabilityChecks, 1);
    expect(find.text('На выбранные даты вещь недоступна'), findsOneWidget);
  });

  testWidgets('creates a booking only after both exact terms are accepted', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _CreateBookingService();
    final router = GoRouter(
      initialLocation: '/items/${item.id}/booking',
      routes: [
        GoRoute(
          path: '/items/:id/booking',
          builder: (_, _) => BookingCreateScreen(itemId: item.id),
        ),
        GoRoute(
          path: '/bookings/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Создано ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(item.id).overrideWith((ref) async => item),
          bookingServiceProvider.overrideWithValue(service),
          marketplaceDocumentsConfigProvider.overrideWithValue(approvedTerms),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Начало: выберите'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Выбранные даты свободны'), findsOneWidget);
    expect(find.text('Предварительный расчёт'), findsOneWidget);
    expect(find.text('Залог'), findsOneWidget);
    expect(find.text('Нет'), findsOneWidget);
    expect(find.text('Комиссия «Всё рядом» (офлайн-пилот)'), findsNothing);
    expect(find.text('Выплата владельцу'), findsNothing);
    expect(find.text('Валюта'), findsNothing);
    expect(find.text('RUB'), findsNothing);
    await tester.ensureVisible(
      find.text('Владелец ответит в течение 12 часов'),
    );
    expect(find.text('Владелец ответит в течение 12 часов'), findsOneWidget);

    await tester.ensureVisible(find.text('Принимаю оферту'));
    await tester.tap(find.text('Принимаю оферту'));
    await tester.pump();
    await tester.ensureVisible(find.text('Принимаю правила аренды и отмены'));
    await tester.tap(find.text('Принимаю правила аренды и отмены'));
    await tester.pump();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Отправить заявку'),
    );
    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Отправить заявку'),
    );
    expect(submit.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Отправить заявку'));
    await tester.pumpAndSettle();

    expect(service.createCalls, 1);
    expect(find.text('Создано booking-created'), findsOneWidget);
  });

  testWidgets('shows an unsupported deposit before allowing submission', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _CreateBookingService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(
            item.id,
          ).overrideWith((ref) async => item.copyWith(depositAmount: 500)),
          bookingServiceProvider.overrideWithValue(service),
          marketplaceDocumentsConfigProvider.overrideWithValue(approvedTerms),
        ],
        child: MaterialApp(home: BookingCreateScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Начало: выберите'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('500 ₽'), findsOneWidget);
    expect(find.text('Бронирование с залогом пока недоступно'), findsOneWidget);
    await tester.tap(find.text('Принимаю оферту'));
    await tester.pump();
    await tester.tap(find.text('Принимаю правила аренды и отмены'));
    await tester.pump();
    final submit = find.widgetWithText(FilledButton, 'Отправить заявку');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(service.createCalls, 0);
  });

  testWidgets('shows separate provisional fake checkout price rows', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _CreateBookingService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(
            item.id,
          ).overrideWith((ref) async => item.copyWith(depositAmount: 500)),
          bookingServiceProvider.overrideWithValue(service),
          marketplacePolicyProvider.overrideWith((ref) async => fakePolicy),
        ],
        child: MaterialApp(home: BookingCreateScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Начало: выберите'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Тестовый сценарий безопасной сделки'), findsOneWidget);
    expect(find.text('Залог'), findsOneWidget);
    expect(find.text('500 ₽'), findsOneWidget);
    expect(find.text('Предварительная комиссия «Всё рядом»'), findsNothing);
    expect(find.text('4,50 ₽'), findsNothing);
    expect(find.text('Выплата владельцу'), findsNothing);
    expect(find.text('445,50 ₽'), findsNothing);
    expect(find.text('Итого'), findsOneWidget);
    expect(find.text('950 ₽'), findsOneWidget);
  });

  testWidgets('shows my booking snapshot and redacts pending handover', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBookingsProvider.overrideWith((ref) async => [booking]),
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => booking),
        ],
        child: MaterialApp(
          routes: {
            '/details': (_) => BookingDetailsScreen(bookingId: booking.id),
          },
          home: const BookingListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Перфоратор'), findsOneWidget);
    expect(find.text('Беру'), findsAtLeastNWidgets(2));
  });

  testWidgets('filters bookings by lifecycle and participant role', (
    tester,
  ) async {
    final currentBorrowing = booking.copyWith(
      id: 'current-borrowing',
      terms: booking.terms!.copyWith(itemTitle: 'Беру сейчас'),
    );
    final currentLending = booking.copyWith(
      id: 'current-lending',
      actorRole: 'LENDER',
      terms: booking.terms!.copyWith(itemTitle: 'Сдаю сейчас'),
    );
    final completedBorrowing = booking.copyWith(
      id: 'completed-borrowing',
      status: 'COMPLETED',
      terms: booking.terms!.copyWith(itemTitle: 'Брал раньше'),
    );
    final cancelledLending = booking.copyWith(
      id: 'cancelled-lending',
      actorRole: 'LENDER',
      status: 'CANCELLED',
      terms: booking.terms!.copyWith(itemTitle: 'Сдавал раньше'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBookingsProvider.overrideWith(
            (ref) async => [
              currentBorrowing,
              currentLending,
              completedBorrowing,
              cancelledLending,
            ],
          ),
        ],
        child: const MaterialApp(home: BookingListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Беру сейчас'), findsOneWidget);
    expect(find.text('Сдаю сейчас'), findsOneWidget);
    expect(find.text('Брал раньше'), findsNothing);

    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();
    expect(find.text('Брал раньше'), findsOneWidget);
    expect(find.text('Сдавал раньше'), findsOneWidget);
    expect(find.text('Беру сейчас'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Сдаю'));
    await tester.pumpAndSettle();
    expect(find.text('Сдавал раньше'), findsOneWidget);
    expect(find.text('Брал раньше'), findsNothing);
  });

  testWidgets('details show full price and no contact before confirmation', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => booking),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Цена и условия'), findsOneWidget);
    expect(find.text('Следующее действие'), findsOneWidget);
    expect(find.text('Ожидайте ответ владельца'), findsOneWidget);
    expect(find.text('Владелец'), findsOneWidget);
    expect(find.text('Иван'), findsOneWidget);
    expect(find.text('900 ₽'), findsAtLeastNWidgets(2));
    expect(find.text('Выплата владельцу'), findsNothing);
    expect(find.text('Комиссия «Всё рядом» (офлайн-пилот)'), findsNothing);
    expect(find.text('Оплата'), findsOneWidget);
    expect(find.text('При передаче вещи'), findsOneWidget);
    expect(find.text('Валюта'), findsNothing);
    expect(find.text('RUB'), findsNothing);
    expect(find.text('Технические детали'), findsNothing);
    expect(find.text('Версия объявления'), findsNothing);
    expect(find.text('2026-07-28:1'), findsNothing);
    expect(find.text('Ответ владельца до'), findsOneWidget);
    expect(find.text('Адрес'), findsNothing);
    expect(find.text('Контакт'), findsNothing);
    expect(find.text('Отменить заявку'), findsOneWidget);
    expect(find.text('Оставить отзыв'), findsNothing);
  });

  testWidgets('shows a human-readable cancellation reason', (tester) async {
    _useTallSurface(tester);
    final cancelled = booking.copyWith(
      status: 'CANCELLED',
      expiresAt: null,
      cancellationReason: 'BORROWER_CANCELLED',
      nextAction: const BookingNextAction(
        code: 'NONE',
        title: 'Заявка завершена',
        description: 'Новых действий по этой заявке нет.',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => cancelled),
          bookingActsProvider(
            booking.id,
          ).overrideWith((ref) async => <BookingAct>[]),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Отменено арендатором'), findsOneWidget);
    expect(find.text('BORROWER_CANCELLED'), findsNothing);
  });

  testWidgets('uses authoritative fake checkout and keeps retry ID stable', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _FlowBookingService(fakeBooking());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookingServiceProvider.overrideWithValue(service)],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Тестовый сценарий оплаты'), findsOneWidget);
    expect(find.text('Ожидает тестовой оплаты'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Таймаут'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Таймаут'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Таймаут'));
    await tester.pumpAndSettle();
    expect(service.requestIds, hasLength(2));
    expect(service.requestIds.toSet(), hasLength(1));
    expect(service.detailLoads, greaterThan(1));

    await tester.tap(find.widgetWithText(FilledButton, 'Успех'));
    await tester.pumpAndSettle();
    expect(find.text('Удерживается'), findsOneWidget);
    expect(find.text('Тестовый сценарий оплаты'), findsNothing);
  });

  testWidgets('offline booking never shows fake checkout controls', (
    tester,
  ) async {
    _useTallSurface(tester);
    final offline = booking.copyWith(status: 'CONFIRMED', expiresAt: null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => offline),
          bookingActsProvider(
            booking.id,
          ).overrideWith((ref) async => <BookingAct>[]),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Тестовый сценарий оплаты'), findsNothing);
  });

  testWidgets('opens a dedicated financial dispute inside the server window', (
    tester,
  ) async {
    _useTallSurface(tester);
    final returned = fakeBooking().copyWith(
      status: 'RETURNED',
      payment: const ParticipantPayment(
        amountMinor: 95000,
        status: 'SUCCEEDED',
      ),
      deposit: ParticipantDeposit(
        amountMinor: 5000,
        status: 'HELD',
        refundedMinor: 0,
        releasedToLenderMinor: 0,
        policyVersion: 'fake-v1',
        disputeWindowEndsAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    final service = _FlowBookingService(returned);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookingServiceProvider.overrideWithValue(service)],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Открыть финансовый спор'));
    expect(find.text('Есть проблема'), findsOneWidget);
    await tester.tap(find.text('Открыть финансовый спор'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Факты'),
      'После возврата обнаружено повреждение корпуса.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Открыть спор'));
    await tester.pumpAndSettle();

    expect(service.disputeCreates, 1);
    expect(find.text('Открыт спор'), findsAtLeastNWidgets(1));
    expect(find.text('Есть проблема'), findsOneWidget);
  });

  for (final role in ['BORROWER', 'LENDER']) {
    testWidgets('$role can attach private dispute evidence', (tester) async {
      _useTallSurface(tester);
      final disputed = fakeBooking().copyWith(
        actorRole: role,
        status: 'RETURNED',
        payment: const ParticipantPayment(
          amountMinor: 95000,
          status: 'SUCCEEDED',
        ),
        deposit: ParticipantDeposit(
          amountMinor: 5000,
          status: 'DISPUTED',
          refundedMinor: 0,
          releasedToLenderMinor: 0,
          policyVersion: 'fake-v1',
          disputeWindowEndsAt: DateTime.now().add(const Duration(hours: 1)),
        ),
        financialDispute: FinancialDispute(
          id: 'dispute-1',
          bookingId: booking.id,
          openedById: 'borrower-1',
          reason: 'ITEM_DAMAGED',
          description: 'После возврата обнаружено повреждение корпуса.',
          status: 'OPEN',
          openedAt: DateTime.now(),
          resolvedAt: null,
          evidence: const [],
        ),
      );
      final service = _FlowBookingService(disputed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingServiceProvider.overrideWithValue(service),
            bookingEvidencePickerProvider.overrideWithValue(
              _FakeEvidencePicker(),
            ),
            appPermissionGatewayProvider.overrideWithValue(
              _GrantedPermissionGateway(),
            ),
          ],
          child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Добавить фото к спору'));
      await tester.tap(find.text('Добавить фото к спору'));
      await tester.pumpAndSettle();
      expect(service.evidenceAdds, 1);
    });
  }

  testWidgets('expired or resolved deposit hides dispute command', (
    tester,
  ) async {
    _useTallSurface(tester);
    final expired = fakeBooking().copyWith(
      status: 'RETURNED',
      deposit: ParticipantDeposit(
        amountMinor: 5000,
        status: 'HELD',
        refundedMinor: 0,
        releasedToLenderMinor: 0,
        policyVersion: 'fake-v1',
        disputeWindowEndsAt: DateTime.now().subtract(
          const Duration(seconds: 1),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => expired),
          bookingActsProvider(
            booking.id,
          ).overrideWith((ref) async => <BookingAct>[]),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Открыть финансовый спор'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    final resolved = expired.copyWith(
      deposit: expired.deposit!.copyWith(
        status: 'RESOLVED',
        disputeWindowEndsAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => resolved),
          bookingActsProvider(
            booking.id,
          ).overrideWith((ref) async => <BookingAct>[]),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Возвращён/распределён'), findsOneWidget);
    expect(find.text('Открыть финансовый спор'), findsNothing);
  });

  testWidgets('keeps the next action usable on a small safe screen at 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final activeBooking = booking.copyWith(
      status: 'ACTIVE',
      expiresAt: null,
      nextAction: const BookingNextAction(
        code: 'USE_ITEM',
        title: 'Пользуйтесь вещью',
        description: 'Верните её в согласованный срок.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => activeBooking),
          bookingActsProvider(
            booking.id,
          ).overrideWith((ref) async => <BookingAct>[]),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: BookingDetailsScreen(bookingId: booking.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nextAction = find.byKey(const ValueKey('booking-next-action'));
    expect(nextAction, findsOneWidget);
    expect(find.text('Следующее действие'), findsOneWidget);
    final title = find.text('Пользуйтесь вещью');
    await tester.ensureVisible(title);
    expect(title.hitTestable(), findsOneWidget);
    final chat = find.widgetWithText(FilledButton, 'Открыть чат');
    await tester.ensureVisible(chat);
    await tester.pump();
    expect(chat.hitTestable(), findsOneWidget);
    expect(tester.widget<FilledButton>(chat).onPressed, isNotNull);
    expect(find.text('Есть проблема'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers a review CTA only after the booking is completed', (
    tester,
  ) async {
    _useTallSurface(tester);
    final completed = booking.copyWith(status: 'COMPLETED', expiresAt: null);
    final router = GoRouter(
      initialLocation: '/bookings/${booking.id}',
      routes: [
        GoRoute(
          path: '/bookings/:id',
          builder: (_, _) => BookingDetailsScreen(bookingId: booking.id),
          routes: [
            GoRoute(
              path: 'review',
              builder: (_, _) => const Scaffold(body: Text('Форма отзыва')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => completed),
          bookingActsProvider(
            booking.id,
          ).overrideWith((ref) async => <BookingAct>[]),
          bookingReviewsProvider(
            booking.id,
          ).overrideWith((ref) async => <ParticipantReview>[]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Оставить отзыв'));
    await tester.tap(find.text('Оставить отзыв'));
    await tester.pumpAndSettle();

    expect(find.text('Форма отзыва'), findsOneWidget);
  });

  testWidgets('requires confirmation before cancelling a pending booking', (
    tester,
  ) async {
    _useTallSurface(tester);
    var cancelCalls = 0;
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/bookings/${booking.id}/cancel');
      cancelCalls += 1;
      return jsonResponse({'success': true, 'data': {}, 'error': null});
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingServiceProvider.overrideWithValue(service),
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => booking),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Отменить заявку'));
    await tester.pumpAndSettle();
    expect(find.text('Отменить заявку?'), findsOneWidget);
    expect(cancelCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Отменить заявку'));
    await tester.pumpAndSettle();
    expect(cancelCalls, 1);
  });

  testWidgets('submits a structured issue from an active booking', (
    tester,
  ) async {
    _useTallSurface(tester);
    var issueCalls = 0;
    final activeBooking = booking.copyWith(status: 'ACTIVE', expiresAt: null);
    final adapter = CallbackAdapter((options) {
      expect(options.method, 'POST');
      expect(options.path, '/support/tickets');
      final data = options.data! as Map<String, dynamic>;
      expect(data['bookingId'], booking.id);
      expect(data['bookingIssueReason'], 'EARLY_RETURN');
      expect(data.containsKey('amount'), isFalse);
      issueCalls += 1;
      return jsonResponse({
        'success': true,
        'data': {
          'id': 'ticket-1',
          'status': 'OPEN',
          'createdAt': '2026-08-01T10:00:00.000Z',
        },
        'error': null,
      });
    });
    final service = BookingService(Dio()..httpClientAdapter = adapter);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingServiceProvider.overrideWithValue(service),
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => activeBooking),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Есть проблема'));
    await tester.pumpAndSettle();
    expect(find.text('Досрочный возврат'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'Хотим вернуть вещь раньше согласованной даты.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
    await tester.pumpAndSettle();

    expect(issueCalls, 1);
    expect(find.text('Обращение принято'), findsOneWidget);
    expect(find.textContaining('ticket-1'), findsOneWidget);
  });

  testWidgets('confirms a counterparty handover act after explicit approval', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _ActBookingService();
    final confirmedBooking = booking.copyWith(
      status: 'CONFIRMED',
      expiresAt: null,
      handover: const BookingHandover(
        area: 'Хамовники',
        address: 'Москва, улица Примерная, 1',
        latitude: 55.75,
        longitude: 37.62,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingServiceProvider.overrideWithValue(service),
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => confirmedBooking),
          authControllerProvider.overrideWith(_AuthenticatedController.new),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Акт передачи'), findsOneWidget);
    expect(find.text('Чек-лист готовности'), findsOneWidget);
    expect(find.text('Видимые дефекты: Нет'), findsOneWidget);
    expect(
      find.text('Заявление владельца, не проверка «Всё рядом».'),
      findsOneWidget,
    );
    await tester.tap(find.text('Подтвердить передачу'));
    await tester.pumpAndSettle();
    expect(find.text('Подтвердить передачу вещи?'), findsOneWidget);
    expect(service.confirmCalls, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Подтвердить передачу'),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.confirmCalls, 1);
  });

  testWidgets('creates a handover act only after consent and photo selection', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _ActBookingService()..acts.clear();
    final picker = _FakeEvidencePicker();
    final confirmedBooking = booking.copyWith(
      status: 'CONFIRMED',
      actorRole: 'LENDER',
      expiresAt: null,
      handover: const BookingHandover(
        area: 'Хамовники',
        address: 'Москва, улица Примерная, 1',
        latitude: 55.75,
        longitude: 37.62,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingServiceProvider.overrideWithValue(service),
          bookingDetailsProvider(
            booking.id,
          ).overrideWith((ref) async => confirmedBooking),
          authControllerProvider.overrideWith(
            _AuthenticatedLenderController.new,
          ),
          bookingEvidencePickerProvider.overrideWithValue(picker),
          appPermissionGatewayProvider.overrideWithValue(
            _GrantedPermissionGateway(),
          ),
        ],
        child: MaterialApp(home: BookingDetailsScreen(bookingId: booking.id)),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BookingDetailsScreen)),
    );
    picker.onPick = () => container.invalidate(bookingActionProvider);
    await tester.tap(find.text('Создать акт передачи'));
    await tester.pumpAndSettle();
    expect(find.text('Готовность к передаче'), findsOneWidget);
    expect(service.createCalls, 0);

    await tester.tap(find.text('Вещь исправна'));
    await tester.tap(find.text('Комплектация полная'));
    await tester.enterText(find.byType(TextField), 'Нет');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Выбрать снимок'));
    await tester.pumpAndSettle();

    expect(service.createCalls, 1);
    expect(service.lastReadiness?.visibleDefects, 'Нет');
    expect(find.text('Создан вами'), findsOneWidget);
  });
}

class _FlowBookingService extends BookingService {
  _FlowBookingService(this.current) : super(Dio());

  ParticipantBooking current;
  int detailLoads = 0;
  int disputeCreates = 0;
  int evidenceAdds = 0;
  final requestIds = <String>[];

  @override
  Future<ParticipantBooking> getDetails(String bookingId) async {
    detailLoads += 1;
    return current;
  }

  @override
  Future<List<ParticipantBooking>> listMine() async => [current];

  @override
  Future<List<BookingAct>> listActs(String bookingId) async => const [];

  @override
  Future<FakeCheckoutResult> fakeCheckout({
    required String bookingId,
    required String outcome,
    required String requestId,
  }) async {
    requestIds.add(requestId);
    if (outcome == 'SUCCESS') {
      current = current.copyWith(
        payment: const ParticipantPayment(
          amountMinor: 95000,
          status: 'SUCCEEDED',
        ),
        deposit: current.deposit?.copyWith(status: 'HELD'),
      );
      return const FakeCheckoutResult(outcome: 'SUCCEEDED');
    }
    return FakeCheckoutResult(
      outcome: outcome == 'DECLINE' ? 'DECLINED' : 'TIMEOUT',
      errorCode: outcome == 'DECLINE' ? 'CARD_DECLINED' : null,
    );
  }

  @override
  Future<FinancialDispute> openFinancialDispute({
    required String bookingId,
    required String reason,
    required String description,
  }) async {
    disputeCreates += 1;
    final dispute = FinancialDispute(
      id: 'dispute-1',
      bookingId: bookingId,
      openedById: 'borrower-1',
      reason: reason,
      description: description,
      status: 'OPEN',
      openedAt: DateTime.now(),
      resolvedAt: null,
      evidence: const [],
    );
    current = current.copyWith(
      deposit: current.deposit?.copyWith(status: 'DISPUTED'),
      financialDispute: dispute,
    );
    return dispute;
  }

  @override
  Future<FinancialDisputeEvidence> addDisputeEvidence({
    required String bookingId,
    required String disputeId,
    required XFile photo,
  }) async {
    evidenceAdds += 1;
    final evidence = FinancialDisputeEvidence(
      id: 'evidence-new',
      sha256: 'abc123',
      createdAt: DateTime.now(),
    );
    final dispute = current.financialDispute!;
    current = current.copyWith(
      financialDispute: dispute.copyWith(
        evidence: [...dispute.evidence, evidence],
      ),
    );
    return evidence;
  }
}

class _AvailabilityBookingService extends BookingService {
  _AvailabilityBookingService() : super(Dio());

  int availabilityChecks = 0;

  @override
  Future<ItemAvailability> checkAvailability({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    availabilityChecks += 1;
    return const ItemAvailability(available: false);
  }
}

class _CreateBookingService extends BookingService {
  _CreateBookingService() : super(Dio());

  int createCalls = 0;

  @override
  Future<ItemAvailability> checkAvailability({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return const ItemAvailability(available: true);
  }

  @override
  Future<String> create({
    required String itemId,
    required DateTime startDate,
    required DateTime endDate,
    required String offerVersion,
    required String cancellationPolicyVersion,
    required String requestId,
  }) async {
    createCalls += 1;
    expect(offerVersion, approvedTerms.offerVersion);
    expect(cancellationPolicyVersion, approvedTerms.cancellationPolicyVersion);
    expect(requestId, isNotEmpty);
    return 'booking-created';
  }
}

class _ActBookingService extends BookingService {
  _ActBookingService() : super(Dio());

  var confirmCalls = 0;
  var createCalls = 0;
  HandoverReadinessInput? lastReadiness;
  final acts = <BookingAct>[handoverAct];

  @override
  Future<List<BookingAct>> listActs(String bookingId) async => [...acts];

  @override
  Future<BookingAct> createAct({
    required String bookingId,
    required String stage,
    required XFile photo,
    HandoverReadinessInput? readiness,
  }) async {
    createCalls += 1;
    lastReadiness = readiness;
    final result = handoverAct.copyWith(
      id: 'act-created',
      authorId: 'lender-1',
    );
    acts.add(result);
    return result;
  }

  @override
  Future<BookingAct> confirmAct({
    required String bookingId,
    required String actId,
    required String requestId,
  }) async {
    confirmCalls += 1;
    return handoverAct.copyWith(
      confirmedById: 'borrower-1',
      confirmedAt: DateTime.utc(2026, 8, 1, 10, 5),
    );
  }
}

class _FakeEvidencePicker extends BookingEvidencePicker {
  _FakeEvidencePicker() : super(ImagePicker());

  VoidCallback? onPick;

  @override
  Future<XFile?> pick() async {
    onPick?.call();
    return XFile('/private/tmp/handover.jpg', mimeType: 'image/jpeg');
  }
}

class _GrantedPermissionGateway implements AppPermissionGateway {
  @override
  Future<PermissionStatus> request(AppPermission permission) async =>
      PermissionStatus.granted;

  @override
  Future<bool> openSettings() async => true;
}

class _AuthenticatedController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'borrower-1',
      phone: '+79990000000',
      role: 'USER',
      isBlocked: false,
    ),
  );
}

class _AuthenticatedLenderController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'lender-1',
      phone: '+79990000001',
      role: 'USER',
      isBlocked: false,
    ),
  );
}

void _useTallSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1000, 2200);
  addTearDown(tester.view.reset);
}

final item = CatalogItem(
  id: 'item-1',
  title: 'Перфоратор',
  description: 'Рабочий перфоратор',
  condition: 'GOOD',
  completeness: 'Кейс и два бура',
  handoverTerms: 'Проверить при передаче',
  pricePerDay: 450,
  category: const CatalogCategory(
    id: 'category-1',
    name: 'Инструменты',
    slug: 'tools',
    safetyNotice: 'Используйте защитные очки',
  ),
  owner: const CatalogOwner(id: 'owner-1', name: 'Иван', city: 'Москва'),
  area: 'Хамовники',
  approximateLocation: const ApproximateLocation(
    latitude: 55.75,
    longitude: 37.62,
    precision: 'SPARSE',
  ),
  photos: const [],
  createdAt: DateTime.utc(2026, 7, 29),
  updatedAt: DateTime.utc(2026, 7, 29),
);

const approvedTerms = MarketplaceDocumentsConfig(
  offerVersion: '2026-08-01.1',
  offerUrl: 'https://docs.sosedi.ru/documents/offer/2026-08-01.1/',
  cancellationPolicyVersion: '2026-08-01.2',
  rentalRulesUrl: 'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.2/',
  privacyVersion: '2026-08-01.3',
  privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
);

const fakePolicy = MarketplacePolicy(
  paymentScenario: PaymentScenario.fakeSafeDeal,
  deposit: MarketplaceDepositPolicy(
    enabled: true,
    currency: 'RUB',
    maximumMinor: 10000000,
    policyVersion: 'fake-v1',
    disputeWindowSeconds: 86400,
  ),
);

final booking = ParticipantBooking(
  id: 'booking-1',
  itemId: 'item-1',
  actorRole: 'BORROWER',
  startDate: DateTime.utc(2026, 8, 1),
  endDate: DateTime.utc(2026, 8, 2),
  status: 'PENDING',
  nextAction: const BookingNextAction(
    code: 'WAIT_LENDER',
    title: 'Ожидайте ответ владельца',
    description: 'Владелец должен подтвердить или отклонить заявку.',
  ),
  expiresAt: DateTime.utc(2026, 7, 30),
  cancellationReason: null,
  terms: const BookingTerms(
    itemTitle: 'Перфоратор',
    lenderDisplayName: 'Иван',
    pricePerDay: 450,
    days: 2,
    rentalSubtotal: 900,
    depositAmount: null,
    platformFee: 0,
    ownerPayout: 900,
    total: 900,
    currency: 'RUB',
    paymentScenario: 'PAY_ON_HANDOVER',
    listingVersion: '2026-07-28:1',
    offerVersion: null,
    cancellationPolicyVersion: null,
  ),
  handover: null,
  counterpartyContact: null,
  createdAt: DateTime.utc(2026, 7, 29, 12),
);

ParticipantBooking fakeBooking() => booking.copyWith(
  status: 'CONFIRMED',
  expiresAt: null,
  nextAction: const BookingNextAction(
    code: 'PREPARE_HANDOVER',
    title: 'Подготовьтесь к передаче',
    description: 'Согласуйте время в чате.',
  ),
  terms: const BookingTerms(
    itemTitle: 'Перфоратор',
    lenderDisplayName: 'Иван',
    pricePerDay: 450,
    days: 2,
    rentalSubtotal: 900,
    depositAmount: 50,
    platformFee: 9,
    ownerPayout: 891,
    total: 950,
    currency: 'RUB',
    paymentScenario: 'FAKE_SAFE_DEAL',
    listingVersion: '2026-07-28:1',
    offerVersion: '2026-08-01.1',
    cancellationPolicyVersion: '2026-08-01.2',
    moneyMinor: BookingMoneyMinor(
      pricePerDay: 45000,
      rentalSubtotal: 90000,
      deposit: 5000,
      platformFee: 900,
      ownerPayout: 89100,
      total: 95000,
    ),
    depositTerms: BookingDepositTerms(
      policyVersion: 'fake-v1',
      disputeWindowSeconds: 86400,
    ),
  ),
  payment: const ParticipantPayment(amountMinor: 95000, status: 'PENDING'),
  deposit: const ParticipantDeposit(
    amountMinor: 5000,
    status: 'PENDING',
    refundedMinor: 0,
    releasedToLenderMinor: 0,
    policyVersion: 'fake-v1',
    disputeWindowEndsAt: null,
  ),
);

final handoverAct = BookingAct(
  id: 'act-1',
  bookingId: booking.id,
  authorId: 'lender-1',
  stage: 'HANDOVER',
  createdAt: DateTime.utc(2026, 8, 1, 10),
  confirmedById: null,
  confirmedAt: null,
  readiness: BookingReadiness(
    isWorking: true,
    isComplete: true,
    visibleDefects: 'Нет',
    declaredAt: DateTime.utc(2026, 8, 1, 9, 59),
    declaration: 'LENDER_SELF_DECLARATION',
  ),
  evidence: [
    BookingEvidence(
      id: 'evidence-1',
      sha256: 'abc123',
      createdAt: DateTime.utc(2026, 8, 1, 10),
    ),
  ],
);
