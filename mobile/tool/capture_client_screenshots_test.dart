import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/analytics/analytics.dart';
import 'package:mobile/core/compatibility/compatibility_gate.dart';
import 'package:mobile/core/compatibility/update_required_screen.dart';
import 'package:mobile/core/permissions/app_permissions.dart';
import 'package:mobile/core/router/app_shell.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/presentation/onboarding_screen.dart';
import 'package:mobile/features/auth/presentation/otp_screen.dart';
import 'package:mobile/features/auth/presentation/phone_screen.dart';
import 'package:mobile/features/booking/data/booking_models.dart';
import 'package:mobile/features/booking/data/booking_service.dart';
import 'package:mobile/features/booking/presentation/booking_chat_screen.dart';
import 'package:mobile/features/booking/presentation/booking_create_screen.dart';
import 'package:mobile/features/booking/presentation/booking_details_screen.dart';
import 'package:mobile/features/booking/presentation/booking_list_screen.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/catalog/data/catalog_service.dart';
import 'package:mobile/features/catalog/presentation/catalog_screen.dart';
import 'package:mobile/features/favorites/data/favorite_service.dart';
import 'package:mobile/features/favorites/presentation/favorites_screen.dart';
import 'package:mobile/features/item/data/create_item_draft_storage.dart';
import 'package:mobile/features/item/data/create_item_models.dart';
import 'package:mobile/features/item/data/item_service.dart';
import 'package:mobile/features/item/data/owned_item_models.dart';
import 'package:mobile/features/item/data/owned_items_service.dart';
import 'package:mobile/features/item/presentation/create_item_screen.dart';
import 'package:mobile/features/item/presentation/edit_item_screen.dart';
import 'package:mobile/features/item/presentation/item_details_screen.dart';
import 'package:mobile/features/item/presentation/owned_items_screen.dart';
import 'package:mobile/features/notifications/data/inbox_event.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';
import 'package:mobile/features/notifications/presentation/inbox_screen.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/profile/domain/session_controller.dart';
import 'package:mobile/features/profile/presentation/account_closure_screen.dart';
import 'package:mobile/features/profile/presentation/analytics_settings_screen.dart';
import 'package:mobile/features/profile/presentation/data_export_screen.dart';
import 'package:mobile/features/profile/presentation/documents_screen.dart';
import 'package:mobile/features/profile/presentation/profile_edit_screen.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';
import 'package:mobile/features/profile/presentation/sessions_screen.dart';
import 'package:mobile/features/reviews/data/review_models.dart';
import 'package:mobile/features/reviews/data/review_service.dart';
import 'package:mobile/features/reviews/presentation/owner_profile_screen.dart';
import 'package:mobile/features/reviews/presentation/review_form_screen.dart';
import 'package:mobile/features/safety/data/safety_models.dart';
import 'package:mobile/features/safety/data/safety_service.dart';
import 'package:mobile/features/safety/presentation/blocked_users_screen.dart';
import 'package:mobile/features/support/data/support_models.dart';
import 'package:mobile/features/support/data/support_service.dart';
import 'package:mobile/features/support/presentation/support_screen.dart';
import 'package:mobile/features/support/presentation/support_ticket_screen.dart';
import 'package:permission_handler/permission_handler.dart';

const _captureKey = ValueKey('client-screenshot-boundary');
late final Uint8List _projectorDemoBytes;

void main() {
  setUpAll(() async {
    final manrope = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([manrope.load(), materialIcons.load()]);
    _projectorDemoBytes = File(
      'tool/fixtures/projector-demo.png',
    ).readAsBytesSync();
  });

  _screenshot('01-onboarding.png', () => _scope(const OnboardingScreen()));
  _screenshot(
    '01b-onboarding-trust.png',
    () => _scope(const OnboardingScreen()),
    prepare: (tester) async {
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
    },
  );
  _screenshot(
    '01c-onboarding-search.png',
    () => _scope(const OnboardingScreen()),
    prepare: (tester) async {
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
    },
  );
  _screenshot(
    '02-phone-login.png',
    () => _scope(
      const PhoneScreen(),
      authOverride: authControllerProvider.overrideWith(
        _UnauthenticatedAuthController.new,
      ),
    ),
  );
  _screenshot(
    '03-otp.png',
    () => _scope(
      const OtpScreen(),
      authOverride: authControllerProvider.overrideWith(
        _CodeSentAuthController.new,
      ),
    ),
  );

  final catalogService = _ScreenshotCatalogService();
  _screenshot(
    '04-catalog.png',
    () => _scope(
      _mainPath(0, const CatalogScreen()),
      overrides: [catalogServiceProvider.overrideWithValue(catalogService)],
    ),
  );
  _screenshot(
    '05-map-demo.png',
    () => _scope(
      _mainPath(0, const CatalogScreen()),
      overrides: [catalogServiceProvider.overrideWithValue(catalogService)],
    ),
    prepare: (tester) async {
      await tester.tap(find.text('Карта (демо)'));
      await tester.pump(const Duration(milliseconds: 300));
    },
  );
  _screenshot(
    '06-item-details.png',
    () => _scope(
      const ItemDetailsScreen(itemId: 'item-1'),
      overrides: [
        itemDetailsProvider(
          'item-1',
        ).overrideWith((ref) async => _catalogItems.first),
        publicReviewsProvider(_catalogItems.first.owner.id).overrideWith(
          (ref) async => const PublicReviewPage(
            summary: ReviewSummary(average: 4.9, count: 12),
            items: [],
            nextCursor: null,
          ),
        ),
      ],
    ),
  );
  _screenshot(
    '07-booking-create.png',
    () => _scope(
      const BookingCreateScreen(itemId: 'item-1'),
      overrides: [
        itemDetailsProvider(
          'item-1',
        ).overrideWith((ref) async => _catalogItems.first),
      ],
    ),
  );
  _screenshot(
    '08-bookings.png',
    () => _scope(
      _mainPath(1, const BookingListScreen()),
      overrides: [
        myBookingsProvider.overrideWith(
          (ref) async => [_pendingBooking, _confirmedBooking],
        ),
        inboxEventsProvider.overrideWith((ref) async => [_inboxEvents.first]),
      ],
    ),
  );
  _bookingStateScreenshot('08a-booking-pending-borrower.png', _pendingBooking);
  _bookingStateScreenshot(
    '08b-booking-pending-lender.png',
    _pendingLenderBooking,
    authOverride: authControllerProvider.overrideWith(
      _AuthenticatedLenderAuthController.new,
    ),
  );
  _bookingStateScreenshot('09a-booking-confirmed.png', _confirmedBooking);
  _bookingStateScreenshot('09b-booking-active.png', _activeBooking);
  _bookingStateScreenshot('09c-booking-returned.png', _returnedBooking);
  _bookingStateScreenshot('09d-booking-completed.png', _completedBooking);
  _bookingStateScreenshot('09e-booking-cancelled.png', _cancelledBooking);
  _screenshot(
    '09-payment-demo.png',
    () => _scope(
      const BookingDetailsScreen(bookingId: 'booking-confirmed'),
      authOverride: authControllerProvider.overrideWith(
        _AuthenticatedAuthController.new,
      ),
      overrides: [
        bookingDetailsProvider(
          'booking-confirmed',
        ).overrideWith((ref) async => _confirmedBooking),
        bookingActsProvider(
          'booking-confirmed',
        ).overrideWith((ref) async => <BookingAct>[]),
      ],
    ),
    prepare: (tester) async {
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.widgetWithText(FilledButton, 'Успешная оплата'));
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
  _screenshot(
    '10-booking-chat.png',
    () => _scope(
      const BookingChatScreen(bookingId: 'booking-confirmed'),
      overrides: [
        bookingServiceProvider.overrideWithValue(_ScreenshotBookingService()),
        bookingDetailsProvider(
          'booking-confirmed',
        ).overrideWith((ref) async => _confirmedBooking),
      ],
    ),
  );
  _screenshot(
    '11-create-item.png',
    () => _scope(
      const CreateItemScreen(),
      overrides: [
        catalogServiceProvider.overrideWithValue(catalogService),
        createItemDraftStorageProvider.overrideWithValue(
          _ScreenshotDraftStorage(),
        ),
        appPermissionGatewayProvider.overrideWithValue(
          _ScreenshotPermissionGateway(),
        ),
        itemPhotoPickerProvider.overrideWithValue(_ScreenshotPhotoPicker()),
      ],
    ),
    prepare: (tester) async {
      await tester.runAsync(
        () => precacheImage(
          MemoryImage(_projectorDemoBytes),
          tester.element(find.byType(CreateItemScreen)),
        ),
      );
      await tester.tap(find.text('Добавить фото'));
      await tester.pumpAndSettle();
    },
  );
  _screenshot(
    '12-owned-items.png',
    () => _scope(
      _mainPath(2, const OwnedItemsScreen()),
      overrides: [ownedItemsProvider.overrideWith((ref) async => _ownedItems)],
    ),
  );
  _screenshot(
    '13-inbox.png',
    () => _scope(
      _mainPath(3, const InboxScreen()),
      overrides: [
        inboxServiceProvider.overrideWithValue(_ScreenshotInboxService()),
        inboxEventsProvider.overrideWith((ref) async => _inboxEvents),
      ],
    ),
  );
  _screenshot(
    '14-profile.png',
    () => _scope(
      _mainPath(4, const ProfileScreen()),
      overrides: [profileProvider.overrideWith((ref) async => _profile)],
    ),
  );
  _screenshot(
    '15-support.png',
    () => _scope(
      const SupportScreen(),
      overrides: [
        supportTicketsProvider.overrideWith((ref) async => [_supportTicket]),
      ],
    ),
  );
  _screenshot(
    '16-review.png',
    () => _scope(
      const ReviewFormScreen(bookingId: 'booking-completed'),
      overrides: [
        bookingDetailsProvider(
          'booking-completed',
        ).overrideWith((ref) async => _completedBooking),
        bookingReviewsProvider(
          'booking-completed',
        ).overrideWith((ref) async => <ParticipantReview>[]),
      ],
    ),
  );
  _screenshot(
    '17-item-edit.png',
    () => _scope(
      const EditItemScreen(itemId: 'item-1'),
      overrides: [
        catalogServiceProvider.overrideWithValue(catalogService),
        ownedItemsProvider.overrideWith((ref) async => _ownedItems),
        unavailablePeriodsProvider(
          'item-1',
        ).overrideWith((ref) async => const []),
      ],
    ),
  );
  _screenshot(
    '18-owner-profile.png',
    () => _scope(
      const OwnerProfileScreen(itemId: 'item-1'),
      overrides: [
        itemDetailsProvider(
          'item-1',
        ).overrideWith((ref) async => _catalogItems.first),
        publicReviewsProvider(
          'owner-1',
        ).overrideWith((ref) async => _publicReviewPage),
      ],
    ),
  );
  _screenshot(
    '19-profile-edit.png',
    () => _scope(
      const ProfileEditScreen(),
      overrides: [profileProvider.overrideWith((ref) async => _profile)],
    ),
  );
  _screenshot(
    '20-sessions.png',
    () => _scope(
      const SessionsScreen(),
      authOverride: authControllerProvider.overrideWith(
        _AuthenticatedAuthController.new,
      ),
      overrides: [sessionsProvider.overrideWith((ref) async => _sessions)],
    ),
  );
  _screenshot(
    '21-analytics.png',
    () => _scope(
      const AnalyticsSettingsScreen(),
      overrides: [
        analyticsConsentProvider.overrideWith(
          _ScreenshotAnalyticsConsentController.new,
        ),
      ],
    ),
  );
  _screenshot('22-documents.png', () => _scope(const DocumentsScreen()));
  _screenshot('23-data-export.png', () => _scope(const DataExportScreen()));
  _screenshot(
    '24-close-account.png',
    () => _scope(const AccountClosureScreen()),
  );
  _screenshot(
    '25-blocked-users.png',
    () => _scope(
      const BlockedUsersScreen(),
      overrides: [
        blockedUsersProvider.overrideWith((ref) async => [_blockedUser]),
      ],
    ),
  );
  _screenshot(
    '26-support-export.png',
    () => _scope(
      const SupportScreen(
        initialSubject: 'Запрос экспорта данных',
        initialMessage: 'Прошу подготовить экспорт данных моего аккаунта.',
      ),
      overrides: [
        supportTicketsProvider.overrideWith((ref) async => [_supportTicket]),
      ],
    ),
  );
  _screenshot(
    '27-support-ticket.png',
    () => _scope(
      const SupportTicketScreen(ticketId: 'ticket-1'),
      overrides: [
        supportTicketProvider(
          'ticket-1',
        ).overrideWith((ref) async => _supportTicket),
        supportMessagesProvider(
          'ticket-1',
        ).overrideWith((ref) async => _supportMessages),
      ],
    ),
  );
  _screenshot(
    '28-update-required.png',
    () => _scope(
      const UpdateRequiredScreen(),
      overrides: [
        compatibilityRequirementProvider.overrideWith(
          _ScreenshotCompatibilityController.new,
        ),
      ],
    ),
  );
  _screenshot(
    '29-favorites.png',
    () => _scope(
      const FavoritesScreen(),
      authOverride: authControllerProvider.overrideWith(
        _AuthenticatedAuthController.new,
      ),
      overrides: [
        favoriteServiceProvider.overrideWithValue(_ScreenshotFavoriteService()),
      ],
    ),
  );
}

void _bookingStateScreenshot(
  String fileName,
  ParticipantBooking booking, {
  Object? authOverride,
}) {
  _screenshot(
    fileName,
    () => _scope(
      BookingDetailsScreen(bookingId: booking.id),
      authOverride:
          authOverride ??
          authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
      overrides: [
        bookingDetailsProvider(booking.id).overrideWith((ref) async => booking),
        bookingActsProvider(
          booking.id,
        ).overrideWith((ref) async => <BookingAct>[]),
        bookingReviewsProvider(
          booking.id,
        ).overrideWith((ref) async => <ParticipantReview>[]),
      ],
    ),
  );
}

void _screenshot(
  String fileName,
  Widget Function() build, {
  Future<void> Function(WidgetTester tester)? prepare,
}) {
  testWidgets(fileName, (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.reset);

    await _capture(tester, fileName, build(), prepare: prepare);
  });
}

Widget _scope(
  Widget screen, {
  Object? authOverride,
  List<Object> overrides = const [],
}) {
  return ProviderScope(
    overrides: [?authOverride, ...overrides].cast(),
    child: RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: screen,
      ),
    ),
  );
}

Widget _mainPath(int index, Widget screen) {
  return AppShell(
    currentIndex: index,
    onDestinationSelected: (_) {},
    child: screen,
  );
}

Future<void> _capture(
  WidgetTester tester,
  String fileName,
  Widget app, {
  Future<void> Function(WidgetTester tester)? prepare,
}) async {
  await tester.pumpWidget(app);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await prepare?.call(tester);
  await tester.pump(const Duration(milliseconds: 200));

  await expectLater(
    find.byKey(_captureKey),
    matchesGoldenFile('../../docs/screenshots/$fileName'),
  );
}

class _ScreenshotCatalogService extends CatalogService {
  _ScreenshotCatalogService() : super(Dio());

  @override
  Future<CatalogState> fetchItems({
    int limit = 20,
    int offset = 0,
    String search = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? availableFrom,
    String? availableTo,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String sort = 'newest',
    String? area,
  }) async {
    return CatalogState(
      items: _catalogItems,
      hasMore: false,
      nextOffset: _catalogItems.length,
    );
  }

  @override
  Future<List<CatalogCategory>> fetchCategories() async => [_category];

  @override
  Future<List<String>> fetchAreas() async => ['Арбат', 'Хамовники'];
}

class _ScreenshotBookingService extends BookingService {
  _ScreenshotBookingService() : super(Dio());

  @override
  Future<BookingMessagePage> listMessages(
    String bookingId, {
    String? cursor,
    int limit = 50,
  }) async {
    return BookingMessagePage(
      items: [
        BookingMessage(
          id: 'message-system',
          bookingId: bookingId,
          author: 'SYSTEM',
          clientMessageId: null,
          body: 'Владелец подтвердил бронирование.',
          createdAt: DateTime.utc(2026, 8, 21, 9),
        ),
        BookingMessage(
          id: 'message-owner',
          bookingId: bookingId,
          author: 'COUNTERPARTY',
          clientMessageId: null,
          body: 'Здравствуйте! Вещь можно забрать сегодня после 18:00.',
          createdAt: DateTime.utc(2026, 8, 21, 9, 5),
        ),
      ],
      nextCursor: null,
    );
  }

  @override
  Future<void> markMessagesRead(String bookingId) async {}
}

class _ScreenshotInboxService extends InboxService {
  _ScreenshotInboxService() : super(Dio());

  @override
  Future<InboxPage> listPage({
    int limit = 50,
    String? cursor,
    bool unreadOnly = false,
  }) async {
    return InboxPage(
      items: unreadOnly
          ? _inboxEvents.where((event) => event.readAt == null).toList()
          : _inboxEvents,
      nextCursor: null,
    );
  }

  @override
  Future<int> markAllRead() async => _inboxEvents.length;
}

class _ScreenshotFavoriteService extends FavoriteService {
  _ScreenshotFavoriteService() : super(Dio());

  @override
  Future<List<CatalogItem>> list() async => _catalogItems;

  @override
  Future<void> remove(String itemId) async {}
}

class _ScreenshotDraftStorage extends CreateItemDraftStorage {
  @override
  Future<LocalCreateItemDraft?> load() async => null;

  @override
  Future<void> save(LocalCreateItemDraft draft) async {}

  @override
  Future<void> clear() async {}
}

class _ScreenshotPhotoPicker extends ItemPhotoPicker {
  _ScreenshotPhotoPicker() : super(ImagePicker());

  @override
  Future<List<XFile>> pick() async {
    return [
      XFile.fromData(
        _projectorDemoBytes,
        path: 'projector-demo.png',
        name: 'projector-demo.png',
        mimeType: 'image/png',
      ),
    ];
  }
}

class _ScreenshotPermissionGateway implements AppPermissionGateway {
  @override
  Future<PermissionStatus> request(AppPermission permission) async {
    return PermissionStatus.granted;
  }

  @override
  Future<bool> openSettings() async => true;
}

class _UnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _CodeSentAuthController extends AuthController {
  @override
  AuthState build() =>
      const AuthState.codeSent(phone: '+79991234567', expiresInSeconds: 300);
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'borrower-1',
      phone: '+79991234567',
      role: 'USER',
      isBlocked: false,
    ),
  );
}

class _AuthenticatedLenderAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'owner-1',
      phone: '+79991234568',
      role: 'USER',
      isBlocked: false,
    ),
  );
}

class _ScreenshotAnalyticsConsentController extends AnalyticsConsentController {
  @override
  AnalyticsConsent build() => AnalyticsConsent.denied;

  @override
  bool get isAvailable => false;
}

class _ScreenshotCompatibilityController extends CompatibilityController {
  @override
  UpdateRequirement build() => UpdateRequirement(
    code: 'MOBILE_UPDATE_REQUIRED',
    message: 'Для продолжения установите актуальную версию приложения.',
    minimumVersion: '1.0.0',
    updateUrl: Uri.parse('https://example.test/update'),
  );
}

const _category = CatalogCategory(
  id: 'category-1',
  name: 'Для дома',
  slug: 'home',
  safetyNotice: 'Проверьте состояние вещи при передаче.',
);

final _catalogItems = [
  _catalogItem(
    id: 'item-1',
    title: 'Проектор для домашнего кино',
    area: 'Хамовники',
    price: 650,
    latitude: 55.733,
    longitude: 37.574,
  ),
  _catalogItem(
    id: 'item-2',
    title: 'Моющий пылесос',
    area: 'Арбат',
    price: 500,
    latitude: 55.752,
    longitude: 37.593,
  ),
  _catalogItem(
    id: 'item-3',
    title: 'Набор инструментов',
    area: 'Пресненский',
    price: 390,
    latitude: 55.761,
    longitude: 37.565,
  ),
];

final _publicReviewPage = PublicReviewPage(
  summary: const ReviewSummary(average: 4.9, count: 12),
  items: [
    PublicReview(
      id: 'review-1',
      authorRole: 'BORROWER',
      rating: 5,
      text: 'Проектор в отличном состоянии, передача прошла вовремя.',
      verifiedRental: true,
      publishedAt: DateTime.utc(2026, 8, 18),
      createdAt: DateTime.utc(2026, 8, 18),
    ),
  ],
  nextCursor: null,
);

CatalogItem _catalogItem({
  required String id,
  required String title,
  required String area,
  required double price,
  required double latitude,
  required double longitude,
}) {
  return CatalogItem(
    id: id,
    title: title,
    description: 'Чистая и исправная вещь для аккуратного использования.',
    condition: 'GOOD',
    completeness: 'Полный комплект и инструкция',
    handoverTerms: 'Личная передача по договорённости в чате',
    pricePerDay: price,
    depositAmount: null,
    category: _category,
    owner: const CatalogOwner(id: 'owner-1', name: 'Иван', city: 'Москва'),
    area: area,
    approximateLocation: ApproximateLocation(
      latitude: latitude,
      longitude: longitude,
      precision: 'COARSE',
    ),
    photos: const [],
    createdAt: DateTime.utc(2026, 8, 10),
    updatedAt: DateTime.utc(2026, 8, 20),
    distanceBucket: 'до 3 км',
  );
}

final _pendingBooking = _booking(
  id: 'booking-pending',
  status: 'PENDING',
  nextAction: const BookingNextAction(
    code: 'WAIT_LENDER',
    title: 'Ожидайте ответ владельца',
    description: 'Владелец должен подтвердить или отклонить заявку.',
  ),
  expiresAt: DateTime.utc(2026, 8, 21, 21),
);

final _pendingLenderBooking = _booking(
  id: 'booking-pending-lender',
  status: 'PENDING',
  actorRole: 'LENDER',
  nextAction: const BookingNextAction(
    code: 'REVIEW_REQUEST',
    title: 'Ответьте на заявку',
    description:
        'Проверьте даты и условия, затем подтвердите или отклоните заявку.',
  ),
  expiresAt: DateTime.utc(2026, 8, 21, 21),
);

const _confirmedHandover = BookingHandover(
  area: 'Хамовники',
  address: 'Москва, улица Примерная, 1',
  latitude: 55.733,
  longitude: 37.574,
);

final _confirmedBooking = _booking(
  id: 'booking-confirmed',
  status: 'CONFIRMED',
  nextAction: const BookingNextAction(
    code: 'PREPARE_HANDOVER',
    title: 'Подготовьтесь к передаче',
    description: 'Согласуйте время в чате и проверьте акт передачи.',
  ),
  handover: _confirmedHandover,
);

final _activeBooking = _booking(
  id: 'booking-active',
  status: 'ACTIVE',
  nextAction: const BookingNextAction(
    code: 'USE_ITEM',
    title: 'Верните вещь в согласованный срок',
    description: 'Сохраните комплектность и согласуйте возврат в чате.',
  ),
  handover: _confirmedHandover,
);

final _returnedBooking = _booking(
  id: 'booking-returned',
  status: 'RETURNED',
  nextAction: const BookingNextAction(
    code: 'REVIEW_RETURN',
    title: 'Завершите возврат',
    description:
        'Проверьте акт возврата и зафиксируйте проблему, если она есть.',
  ),
);

final _completedBooking = _booking(
  id: 'booking-completed',
  status: 'COMPLETED',
  nextAction: const BookingNextAction(
    code: 'LEAVE_REVIEW',
    title: 'Оставьте отзыв',
    description: 'Поделитесь опытом завершённой аренды.',
  ),
);

final _cancelledBooking = _booking(
  id: 'booking-cancelled',
  status: 'CANCELLED',
  nextAction: const BookingNextAction(
    code: 'NONE',
    title: 'Заявка завершена',
    description: 'Новых действий по этой заявке нет.',
  ),
  cancellationReason: 'BORROWER_CANCELLED',
);

ParticipantBooking _booking({
  required String id,
  required String status,
  required BookingNextAction nextAction,
  String actorRole = 'BORROWER',
  DateTime? expiresAt,
  String? cancellationReason,
  BookingHandover? handover,
}) {
  return ParticipantBooking(
    id: id,
    itemId: 'item-1',
    actorRole: actorRole,
    startDate: DateTime.utc(2026, 8, 23),
    endDate: DateTime.utc(2026, 8, 24),
    status: status,
    nextAction: nextAction,
    expiresAt: expiresAt,
    cancellationReason: cancellationReason,
    terms: const BookingTerms(
      itemTitle: 'Проектор для домашнего кино',
      lenderDisplayName: 'Иван',
      pricePerDay: 650,
      days: 2,
      rentalSubtotal: 1300,
      depositAmount: null,
      platformFee: 0,
      ownerPayout: 1300,
      total: 1300,
      currency: 'RUB',
      paymentScenario: 'PAY_ON_HANDOVER',
      listingVersion: '2026-08-10:1',
      offerVersion: 'demo-2026-08-21',
      cancellationPolicyVersion: 'demo-2026-08-21',
    ),
    handover: handover,
    counterpartyContact: handover == null ? null : '+7 ••• •••-12-34',
    createdAt: DateTime.utc(2026, 8, 21, 9),
  );
}

final _ownedItems = [
  OwnedItem(
    id: 'item-1',
    title: 'Проектор для домашнего кино',
    description: 'Исправный проектор с HDMI-кабелем.',
    condition: 'GOOD',
    completeness: 'Проектор, пульт, HDMI и кабель питания',
    handoverTerms: 'Проверка при передаче',
    status: 'APPROVED',
    publicArea: 'Хамовники',
    address: 'Москва, улица Примерная, 1',
    latitude: 55.733,
    longitude: 37.574,
    pricePerDay: 650,
    depositAmount: null,
    category: _category,
    updatedAt: DateTime.utc(2026, 8, 20),
    photos: const [],
  ),
  OwnedItem(
    id: 'item-4',
    title: 'Паровая швабра',
    description: 'Для уборки квартиры.',
    condition: 'LIKE_NEW',
    completeness: 'Швабра и две насадки',
    handoverTerms: 'Личная передача',
    status: 'PENDING',
    publicArea: 'Хамовники',
    address: 'Москва, улица Примерная, 1',
    latitude: 55.733,
    longitude: 37.574,
    pricePerDay: 350,
    depositAmount: null,
    category: _category,
    updatedAt: DateTime.utc(2026, 8, 21),
    photos: const [],
  ),
];

final _inboxEvents = [
  InboxEvent(
    eventId: 'event-1',
    bookingId: 'booking-confirmed',
    supportTicketId: null,
    itemId: null,
    eventType: 'BOOKING_CONFIRMED',
    readAt: null,
    createdAt: DateTime.utc(2026, 8, 21, 9),
  ),
  InboxEvent(
    eventId: 'event-2',
    bookingId: null,
    supportTicketId: 'ticket-1',
    itemId: null,
    eventType: 'SUPPORT_REPLIED',
    readAt: DateTime.utc(2026, 8, 21, 8),
    createdAt: DateTime.utc(2026, 8, 21, 8),
  ),
];

final _profile = UserProfile(
  id: 'borrower-1',
  phone: '+79991234567',
  name: 'Анна',
  city: 'Москва',
  avatarUrl: null,
  role: 'USER',
  kycStatus: null,
  isBlocked: false,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 8, 20),
);

final _sessions = [
  UserSession(
    sessionId: 'session-current',
    installationId: 'installation-current',
    createdAt: DateTime.utc(2026, 8, 1),
    lastSeenAt: DateTime.utc(2026, 8, 21, 9),
    isCurrent: true,
  ),
  UserSession(
    sessionId: 'session-tablet',
    installationId: 'installation-tablet',
    createdAt: DateTime.utc(2026, 8, 10),
    lastSeenAt: DateTime.utc(2026, 8, 20, 18),
    isCurrent: false,
  ),
];

final _blockedUser = BlockedUser(
  id: 'block-1',
  blocked: const BlockedUserSummary(id: 'blocked-1', name: 'Пользователь'),
  createdAt: DateTime.utc(2026, 8, 15),
);

final _supportTicket = SupportTicket(
  id: 'ticket-1',
  type: 'GENERAL',
  bookingId: null,
  bookingIssueReason: null,
  subject: 'Вопрос по объявлению',
  message: 'Как изменить время передачи вещи?',
  status: 'OPEN',
  adminResponse: 'Откройте бронирование и напишите владельцу в чате.',
  respondedAt: DateTime.utc(2026, 8, 21, 8),
  createdAt: DateTime.utc(2026, 8, 20, 18),
  updatedAt: DateTime.utc(2026, 8, 21, 8),
);

final _supportMessages = [
  SupportMessage(
    id: 'support-message-2',
    authorRole: 'SUPPORT',
    body: 'Откройте бронирование и напишите владельцу в чате.',
    attachments: const [],
    createdAt: DateTime.utc(2026, 8, 21, 8),
  ),
];
