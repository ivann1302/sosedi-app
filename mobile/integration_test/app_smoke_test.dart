import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/core/network/dio_provider.dart';
import 'package:mobile/core/storage/onboarding_storage.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/booking/data/booking_models.dart';
import 'package:mobile/features/booking/data/booking_service.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/catalog/data/catalog_service.dart';
import 'package:mobile/features/favorites/data/favorite_service.dart';
import 'package:mobile/features/item/data/create_item_draft_storage.dart';
import 'package:mobile/features/item/data/create_item_models.dart';
import 'package:mobile/features/item/data/item_service.dart';
import 'package:mobile/features/item/data/owned_item_models.dart';
import 'package:mobile/features/item/data/owned_items_service.dart';
import 'package:mobile/features/notifications/data/inbox_event.dart';
import 'package:mobile/features/notifications/data/inbox_service.dart';
import 'package:mobile/features/profile/data/profile_models.dart';
import 'package:mobile/features/profile/data/profile_service.dart';
import 'package:mobile/features/reviews/data/review_models.dart';
import 'package:mobile/features/reviews/data/review_service.dart';
import 'package:mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('browses as a guest and resumes a private tab after OTP', (
    tester,
  ) async {
    final auth = _SmokeAuthController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          onboardingCompletedProvider.overrideWith(
            _SmokeOnboardingController.new,
          ),
          apiCompatibilityCheckProvider.overrideWith((ref) async {}),
          catalogServiceProvider.overrideWithValue(_SmokeCatalogService()),
          profileServiceProvider.overrideWithValue(_SmokeProfileService()),
        ],
        child: const SosediApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Всё нужное уже рядом'), findsOneWidget);
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Смотреть вещи'));
    await tester.pumpAndSettle();

    final navigation = find.byType(NavigationBar);
    Finder destination(String label) =>
        find.descendant(of: navigation, matching: find.text(label));

    expect(destination('Найти'), findsOneWidget);
    expect(destination('Брони'), findsOneWidget);
    expect(destination('Сдать'), findsOneWidget);
    expect(destination('Входящие'), findsOneWidget);
    expect(destination('Профиль'), findsOneWidget);

    await tester.tap(destination('Профиль'));
    await tester.pumpAndSettle();

    expect(find.text('Рады видеть вас'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '+7 999 123 45 67');
    await tester.tap(find.text('Получить код'));
    await tester.pumpAndSettle();

    expect(find.text('Введите код'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    expect(destination('Найти'), findsOneWidget);
    expect(destination('Брони'), findsOneWidget);
    expect(destination('Сдать'), findsOneWidget);
    expect(destination('Входящие'), findsOneWidget);
    expect(destination('Профиль'), findsOneWidget);
    expect(tester.widget<NavigationBar>(navigation).selectedIndex, 4);
    expect(find.text('Анна'), findsOneWidget);
    expect(auth.requestOtpCalls, 1);
    expect(auth.verifyOtpCalls, 1);
  });

  testWidgets('completes the borrower catalog, booking and chat path', (
    tester,
  ) async {
    final bookingService = _SmokeBookingService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            _AuthenticatedSmokeAuthController.new,
          ),
          onboardingCompletedProvider.overrideWith(
            _CompletedOnboardingController.new,
          ),
          apiCompatibilityCheckProvider.overrideWith((ref) async {}),
          catalogServiceProvider.overrideWithValue(_SmokeCatalogService()),
          favoriteServiceProvider.overrideWithValue(_SmokeFavoriteService()),
          bookingServiceProvider.overrideWithValue(bookingService),
          itemDetailsProvider(
            _smokeItem.id,
          ).overrideWith((ref) async => _smokeItem),
          publicReviewsProvider(_smokeItem.owner.id).overrideWith(
            (ref) async => const PublicReviewPage(
              summary: ReviewSummary(average: null, count: 0),
              items: [],
              nextCursor: null,
            ),
          ),
          myBookingsProvider.overrideWith((ref) async => [_smokeBooking]),
          bookingDetailsProvider(
            _smokeBooking.id,
          ).overrideWith((ref) async => _smokeBooking),
          bookingActsProvider(
            _smokeBooking.id,
          ).overrideWith((ref) async => <BookingAct>[]),
          inboxEventsProvider.overrideWith((ref) async => <InboxEvent>[]),
        ],
        child: const SosediApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_smokeItem.title), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('catalog-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_smokeCategory.name).last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, _smokeCategory.name), findsOneWidget);

    await tester.tap(find.byTooltip('Добавить в избранное'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Убрать из избранного'), findsOneWidget);

    await tester.tap(find.text(_smokeItem.title));
    await tester.pumpAndSettle();
    expect(find.text('Объявление'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Выбрать даты'));
    await tester.pumpAndSettle();
    expect(find.text('Выбор дат'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(_destination('Брони'));
    await tester.pumpAndSettle();
    expect(find.text('Мои бронирования'), findsOneWidget);

    await tester.tap(find.text(_smokeBooking.terms!.itemTitle));
    await tester.pumpAndSettle();
    final openChat = find.widgetWithText(FilledButton, 'Открыть чат');
    await tester.ensureVisible(openChat);
    await tester.tap(openChat);
    await tester.pumpAndSettle();
    expect(find.text('Вещь можно забрать после 18:00.'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Буду в 18:30');
    await tester.pump();
    final send = find.widgetWithText(FilledButton, 'Отправить');
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('Буду в 18:30'), findsOneWidget);
  });

  testWidgets('checks listing validation and edits the owner profile', (
    tester,
  ) async {
    final profileService = _SmokeProfileService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            _AuthenticatedSmokeAuthController.new,
          ),
          onboardingCompletedProvider.overrideWith(
            _CompletedOnboardingController.new,
          ),
          apiCompatibilityCheckProvider.overrideWith((ref) async {}),
          catalogServiceProvider.overrideWithValue(_SmokeCatalogService()),
          ownedItemsProvider.overrideWith((ref) async => [_smokeOwnedItem]),
          createItemDraftStorageProvider.overrideWithValue(
            _SmokeDraftStorage(),
          ),
          profileServiceProvider.overrideWithValue(profileService),
          inboxEventsProvider.overrideWith((ref) async => <InboxEvent>[]),
        ],
        child: const SosediApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_destination('Сдать'));
    await tester.pumpAndSettle();
    expect(find.text('Мои объявления'), findsOneWidget);
    expect(find.text(_smokeOwnedItem.title), findsOneWidget);

    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(find.text('Новое объявление'), findsOneWidget);
    expect(find.text('Шаг 1 из 3'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Далее'));
    await tester.pump();
    expect(find.text('Добавьте хотя бы одно фото'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(_destination('Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('Анна'), findsOneWidget);
    expect(find.text('Москва'), findsOneWidget);

    await tester.tap(find.byTooltip('Редактировать'));
    await tester.pumpAndSettle();
    expect(find.text('Редактировать профиль'), findsOneWidget);
    final nameField = find.descendant(
      of: find.byKey(const ValueKey('profile-name-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(nameField, 'Анна Смирнова');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Анна Смирнова'), findsOneWidget);
  });
}

Finder _destination(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

class _SmokeOnboardingController extends OnboardingController {
  @override
  bool build() => false;

  @override
  Future<void> markCompleted() async {
    state = true;
  }
}

class _SmokeAuthController extends AuthController {
  var requestOtpCalls = 0;
  var verifyOtpCalls = 0;

  @override
  AuthState build() => const AuthState.unauthenticated();

  @override
  Future<bool> requestOtp(String rawPhone) async {
    requestOtpCalls += 1;
    state = const AuthState.codeSent(
      phone: '+79991234567',
      expiresInSeconds: 300,
    );
    return true;
  }

  @override
  Future<bool> verifyOtp(String code) async {
    verifyOtpCalls += 1;
    state = const AuthState.authenticated(
      user: AuthUser(
        id: '11111111-1111-4111-8111-111111111111',
        phone: '+79991234567',
        role: 'USER',
        isBlocked: false,
      ),
    );
    return true;
  }
}

class _CompletedOnboardingController extends OnboardingController {
  @override
  bool build() => true;

  @override
  Future<void> markCompleted() async {}
}

class _AuthenticatedSmokeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'borrower-1',
      phone: '+79991234567',
      role: 'USER',
      isBlocked: false,
      name: 'Анна',
    ),
  );
}

class _SmokeCatalogService extends CatalogService {
  _SmokeCatalogService() : super(Dio());

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
    return CatalogState(items: [_smokeItem], hasMore: false, nextOffset: 1);
  }

  @override
  Future<List<CatalogCategory>> fetchCategories() async => [_smokeCategory];

  @override
  Future<List<String>> fetchAreas() async => ['Хамовники'];
}

class _SmokeFavoriteService extends FavoriteService {
  _SmokeFavoriteService() : super(Dio());

  @override
  Future<List<CatalogItem>> list() async => [];

  @override
  Future<void> add(String itemId) async {}

  @override
  Future<void> remove(String itemId) async {}
}

class _SmokeBookingService extends BookingService {
  _SmokeBookingService() : super(Dio());

  final List<BookingMessage> _messages = [
    BookingMessage(
      id: 'message-owner',
      bookingId: _smokeBooking.id,
      author: 'COUNTERPARTY',
      clientMessageId: null,
      body: 'Вещь можно забрать после 18:00.',
      createdAt: DateTime.utc(2026, 8, 30, 12),
    ),
  ];

  @override
  Future<BookingMessagePage> listMessages(
    String bookingId, {
    String? cursor,
    int limit = 50,
  }) async {
    return BookingMessagePage(items: [..._messages], nextCursor: null);
  }

  @override
  Future<BookingMessage> sendMessage({
    required String bookingId,
    required String body,
    required String clientMessageId,
  }) async {
    final message = BookingMessage(
      id: 'message-${_messages.length + 1}',
      bookingId: bookingId,
      author: 'SELF',
      clientMessageId: clientMessageId,
      body: body,
      createdAt: DateTime.utc(2026, 8, 30, 12, _messages.length),
    );
    _messages.add(message);
    return message;
  }

  @override
  Future<void> markMessagesRead(String bookingId) async {}
}

class _SmokeDraftStorage extends CreateItemDraftStorage {
  @override
  Future<LocalCreateItemDraft?> load() async => null;

  @override
  Future<void> save(LocalCreateItemDraft draft) async {}

  @override
  Future<void> clear() async {}
}

class _SmokeProfileService extends ProfileService {
  _SmokeProfileService() : super(Dio());

  UserProfile _profile = _smokeProfile;

  @override
  Future<UserProfile> fetchProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String city,
  }) async {
    _profile = _profile.copyWith(name: name, city: city);
    return _profile;
  }
}

const _smokeCategory = CatalogCategory(
  id: 'category-home',
  name: 'Для дома',
  slug: 'home',
  safetyNotice: 'Проверьте состояние вещи при передаче.',
);

final _smokeItem = CatalogItem(
  id: 'item-projector',
  title: 'Проектор для домашнего кино',
  description: 'Исправный проектор для фильмов и презентаций.',
  condition: 'GOOD',
  completeness: 'Проектор, пульт и HDMI-кабель',
  handoverTerms: 'Передача по договорённости в чате',
  pricePerDay: 650,
  depositAmount: null,
  category: _smokeCategory,
  owner: CatalogOwner(id: 'owner-1', name: 'Иван', city: 'Москва'),
  area: 'Хамовники',
  approximateLocation: ApproximateLocation(
    latitude: 55.733,
    longitude: 37.574,
    precision: 'COARSE',
  ),
  photos: [],
  createdAt: DateTime.utc(2026, 8, 20),
  updatedAt: DateTime.utc(2026, 8, 30),
  distanceBucket: 'до 3 км',
);

final _smokeBooking = ParticipantBooking(
  id: 'booking-confirmed',
  itemId: _smokeItem.id,
  actorRole: 'BORROWER',
  startDate: DateTime.utc(2026, 9, 1),
  endDate: DateTime.utc(2026, 9, 2),
  status: 'CONFIRMED',
  nextAction: const BookingNextAction(
    code: 'PREPARE_HANDOVER',
    title: 'Согласуйте передачу',
    description: 'Напишите владельцу удобное время.',
  ),
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
    listingVersion: '2026-08-30:1',
    offerVersion: 'demo-2026-08-30',
    cancellationPolicyVersion: 'demo-2026-08-30',
  ),
  expiresAt: null,
  cancellationReason: null,
  handover: null,
  counterpartyContact: null,
  createdAt: DateTime.utc(2026, 8, 30, 10),
);

final _smokeOwnedItem = OwnedItem(
  id: _smokeItem.id,
  title: _smokeItem.title,
  description: _smokeItem.description,
  condition: _smokeItem.condition,
  completeness: _smokeItem.completeness,
  handoverTerms: _smokeItem.handoverTerms,
  status: 'APPROVED',
  publicArea: _smokeItem.area,
  address: 'Москва, улица Примерная, 1',
  latitude: 55.733,
  longitude: 37.574,
  pricePerDay: _smokeItem.pricePerDay,
  depositAmount: null,
  category: _smokeCategory,
  updatedAt: DateTime.utc(2026, 8, 30),
  photos: const [],
);

final _smokeProfile = UserProfile(
  id: 'borrower-1',
  phone: '+79991234567',
  name: 'Анна',
  city: 'Москва',
  avatarUrl: null,
  role: 'USER',
  kycStatus: null,
  isBlocked: false,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 30),
);
