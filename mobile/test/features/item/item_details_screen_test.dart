import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/marketplace_documents_config.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/data/auth_models.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/item/data/item_service.dart';
import 'package:mobile/features/item/presentation/item_details_screen.dart';
import 'package:mobile/features/safety/data/safety_service.dart';

void main() {
  testWidgets('shows public details without an exact pickup address', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(item.id).overrideWith((ref) async => item),
        ],
        child: MaterialApp(home: ItemDetailsScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Перфоратор'), findsOneWidget);
    expect(find.text('450 ₽ / день'), findsOneWidget);
    expect(find.text('Хамовники'), findsOneWidget);
    expect(find.text('Иван'), findsOneWidget);
    expect(find.text('Кейс и два бура'), findsOneWidget);
    expect(find.text('Используйте защитные очки'), findsOneWidget);
    expect(find.text('Доступность проверяется по датам'), findsOneWidget);
    expect(find.textContaining('Тверская'), findsNothing);
  });

  testWidgets('shows a terminal state for an unavailable item', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider('missing').overrideWith(
            (ref) => throw const ApiException(
              code: 'ITEM_NOT_FOUND',
              message: 'Не найдено',
            ),
          ),
        ],
        child: const MaterialApp(home: ItemDetailsScreen(itemId: 'missing')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Объявление больше недоступно'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);
  });

  testWidgets('opens date selection from the safe booking CTA', (tester) async {
    _useTallSurface(tester);
    final router = GoRouter(
      initialLocation: '/items/${item.id}',
      routes: [
        GoRoute(
          path: '/items/:id',
          builder: (_, _) => ItemDetailsScreen(itemId: item.id),
        ),
        GoRoute(
          path: '/items/:id/booking',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Выбор дат открыт'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(item.id).overrideWith((ref) async => item),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Выбрать даты'));
    await tester.pumpAndSettle();

    expect(find.text('Выбор дат открыт'), findsOneWidget);
  });

  testWidgets('sends the owner to listing management instead of self-booking', (
    tester,
  ) async {
    _useTallSurface(tester);
    final router = GoRouter(
      initialLocation: '/items/${item.id}',
      routes: [
        GoRoute(
          path: '/items/:id',
          builder: (_, _) => ItemDetailsScreen(itemId: item.id),
        ),
        GoRoute(
          path: '/items/:id/edit',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Управление открыто'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_OwnerController.new),
          itemDetailsProvider(item.id).overrideWith((ref) async => item),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Выбрать даты'), findsNothing);
    await tester.tap(find.text('Управлять объявлением'));
    await tester.pumpAndSettle();

    expect(find.text('Управление открыто'), findsOneWidget);
  });

  testWidgets('shows the exact published rental rules version', (tester) async {
    _useTallSurface(tester);
    final router = GoRouter(
      initialLocation: '/items/${item.id}',
      routes: [
        GoRoute(
          path: '/items/:id',
          builder: (_, _) => ItemDetailsScreen(itemId: item.id),
        ),
        GoRoute(
          path: '/profile/documents',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Документы открыты'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(item.id).overrideWith((ref) async => item),
          marketplaceDocumentsConfigProvider.overrideWithValue(documents),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Правила аренды · версия 2026-08-01.2'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('Правила аренды'));
    await tester.tap(find.textContaining('Правила аренды'));
    await tester.pumpAndSettle();

    expect(find.text('Документы открыты'), findsOneWidget);
  });

  testWidgets('retries item loading after an offline error', (tester) async {
    _useTallSurface(tester);
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(item.id).overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) {
              throw Exception('offline');
            }
            return item;
          }),
        ],
        child: MaterialApp(home: ItemDetailsScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Перфоратор'), findsOneWidget);
  });

  testWidgets('reports an item and explicitly blocks its owner', (
    tester,
  ) async {
    _useTallSurface(tester);
    final safety = _FakeSafetyService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemDetailsProvider(item.id).overrideWith((ref) async => item),
          authControllerProvider.overrideWith(_AuthenticatedController.new),
          safetyServiceProvider.overrideWithValue(safety),
        ],
        child: MaterialApp(home: ItemDetailsScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Пожаловаться на объявление'));
    await tester.tap(find.text('Пожаловаться на объявление'));
    await tester.pumpAndSettle();
    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.patchValue({
      'reason': 'UNSAFE_ITEM',
      'description': 'У вещи повреждён защитный кожух.',
    });
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Отправить'),
      ),
    );
    await tester.pumpAndSettle();

    expect(safety.reportCalls, 1);
    expect(safety.lastTargetType, 'ITEM');
    await tester.ensureVisible(find.text('Заблокировать владельца'));
    await tester.tap(find.text('Заблокировать владельца'));
    await tester.pumpAndSettle();
    expect(find.text('Заблокировать пользователя?'), findsOneWidget);
    expect(safety.blockCalls, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Заблокировать'),
      ),
    );
    await tester.pumpAndSettle();

    expect(safety.blockCalls, 1);
  });
}

class _FakeSafetyService extends SafetyService {
  _FakeSafetyService() : super(Dio());

  var reportCalls = 0;
  var blockCalls = 0;
  String? lastTargetType;

  @override
  Future<void> createReport({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    reportCalls += 1;
    lastTargetType = targetType;
  }

  @override
  Future<void> blockUser(String userId) async {
    blockCalls += 1;
  }
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

class _OwnerController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(
    user: AuthUser(
      id: 'owner-1',
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

const documents = MarketplaceDocumentsConfig(
  offerVersion: '2026-08-01.1',
  offerUrl: 'https://docs.sosedi.ru/documents/offer/2026-08-01.1/',
  cancellationPolicyVersion: '2026-08-01.2',
  rentalRulesUrl: 'https://docs.sosedi.ru/documents/rental-rules/2026-08-01.2/',
  privacyVersion: '2026-08-01.3',
  privacyUrl: 'https://docs.sosedi.ru/documents/privacy/2026-08-01.3/',
);
