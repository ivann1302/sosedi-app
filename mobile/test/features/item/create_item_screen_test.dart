import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/permissions/app_permissions.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/catalog/data/catalog_service.dart';
import 'package:mobile/features/item/data/create_item_draft_storage.dart';
import 'package:mobile/features/item/data/create_item_models.dart';
import 'package:mobile/features/item/data/create_item_service.dart';
import 'package:mobile/features/item/presentation/create_item_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('rejects an invalid create item form', (tester) async {
    _useTallSurface(tester);
    final service = _FakeCreateItemService();
    await tester.pumpWidget(_app(service, picker: _FakePhotoPicker()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Далее'));
    await tester.pump();
    expect(find.text('Добавьте хотя бы одно фото'), findsOneWidget);

    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pump();

    expect(service.calls, 0);
    expect(find.text('Обязательное поле'), findsWidgets);
  });

  testWidgets('submits a valid item and shows moderation status', (
    tester,
  ) async {
    _useTallSurface(tester);
    final service = _FakeCreateItemService();
    await tester.pumpWidget(_app(service, picker: _FakePhotoPicker()));
    await tester.pumpAndSettle();

    expect(find.text('Шаг 1 из 3'), findsOneWidget);
    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.patchValue({
      'title': 'Перфоратор',
      'description': 'Рабочий перфоратор для домашних работ',
      'categoryId': category.id,
      'condition': 'GOOD',
      'completeness': 'Кейс и два бура',
      'handoverTerms': 'Проверить при передаче',
      'pricePerDay': '450',
      'publicArea': 'Хамовники',
      'address': 'Москва, улица Примерная, 1',
      'latitude': '55.75',
      'longitude': '37.62',
      'ownershipConfirmed': true,
      'conditionConfirmed': true,
      'completenessConfirmed': true,
      'safetyAndMarketplaceRulesAccepted': true,
    });
    await tester.pump();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 3 из 3'), findsOneWidget);
    await tester.tap(find.text('На модерацию'));
    await tester.pumpAndSettle();

    expect(service.calls, 1);
    expect(service.lastDraft?.listingRulesVersion, '2026-07-28');
    expect(find.text('На модерации'), findsOneWidget);
  });

  testWidgets('selects item photos before submission', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      _app(_FakeCreateItemService(), picker: _FakePhotoPicker()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();

    expect(find.text('Выбрано фото: 1'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('previews photos and lets the lender change the cover', (
    tester,
  ) async {
    _useTallSurface(tester);
    final picker = _FakePhotoPicker([
      _photo('first.png'),
      _photo('second.png'),
    ]);
    await tester.pumpWidget(_app(_FakeCreateItemService(), picker: picker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('selected-photo-first.png'));
    final second = find.byKey(const ValueKey('selected-photo-second.png'));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(
      find.descendant(of: first, matching: find.text('Главное')),
      findsOneWidget,
    );

    await tester.tap(second);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: second, matching: find.text('Главное')),
      findsOneWidget,
    );

    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 2 из 3'), findsOneWidget);

    await tester.tap(find.text('Назад'));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 1 из 3'), findsOneWidget);
    expect(
      find.descendant(of: second, matching: find.text('Главное')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('delete-selected-photo-second.png')),
    );
    await tester.pumpAndSettle();
    expect(second, findsNothing);
    expect(first, findsOneWidget);
  });

  testWidgets('shows a fallback when a selected photo cannot be read', (
    tester,
  ) async {
    _useTallSurface(tester);
    final picker = _FakePhotoPicker([
      XFile(
        'missing-photo-does-not-exist.png',
        name: 'missing.png',
        mimeType: 'image/png',
      ),
    ]);
    await tester.pumpWidget(_app(_FakeCreateItemService(), picker: picker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить фото'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('does not open the picker after photo permission is denied', (
    tester,
  ) async {
    _useTallSurface(tester);
    final picker = _FakePhotoPicker();
    await tester.pumpWidget(
      _app(
        _FakeCreateItemService(),
        picker: picker,
        permissions: _FakePermissionGateway(PermissionStatus.denied),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();

    expect(find.text('Доступ к фотографиям'), findsOneWidget);
    expect(find.text('Открыть настройки'), findsNothing);
    expect(picker.calls, 0);
  });

  testWidgets('opens settings only after an explicit permanent-denial action', (
    tester,
  ) async {
    _useTallSurface(tester);
    final permissions = _FakePermissionGateway(
      PermissionStatus.permanentlyDenied,
    );
    await tester.pumpWidget(
      _app(_FakeCreateItemService(), permissions: permissions),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();
    expect(permissions.settingsCalls, 0);

    await tester.tap(find.text('Открыть настройки'));
    await tester.pumpAndSettle();

    expect(permissions.settingsCalls, 1);
  });

  testWidgets('preserves an unfinished draft through resize and resume', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_FakeCreateItemService()));
    await tester.pumpAndSettle();

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.fields['title']!.didChange('Дрель из черновика');
    form.fields['address']!.didChange('Москва, улица Примерная, 1');
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = const Size(932, 430);
    await tester.pumpAndSettle();

    expect(form.instantValue['title'], 'Дрель из черновика');
    expect(form.instantValue['address'], 'Москва, улица Примерная, 1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores only safe draft fields after recreating the screen', (
    tester,
  ) async {
    _useTallSurface(tester);
    final storage = _FakeDraftStorage();
    await tester.pumpWidget(
      _app(_FakeCreateItemService(), draftStorage: storage),
    );
    await tester.pumpAndSettle();

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.fields['title']!.didChange('Дрель из черновика');
    form.fields['address']!.didChange('Москва, секретный адрес');
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _app(_FakeCreateItemService(), draftStorage: storage),
    );
    await tester.pumpAndSettle();

    final restored = tester.state<FormBuilderState>(find.byType(FormBuilder));
    expect(restored.instantValue['title'], 'Дрель из черновика');
    expect(restored.instantValue['address'], isNull);
    expect(storage.draft?.title, 'Дрель из черновика');
  });

  testWidgets('moves back between the three publication steps', (tester) async {
    _useTallSurface(tester);
    await tester.pumpWidget(
      _app(_FakeCreateItemService(), picker: _FakePhotoPicker()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 2 из 3'), findsOneWidget);

    await tester.tap(find.text('Назад'));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 1 из 3'), findsOneWidget);
  });

  testWidgets('asks before system back discards an unfinished draft', (
    tester,
  ) async {
    _useTallSurface(tester);
    final storage = _FakeDraftStorage();
    await tester.pumpWidget(
      _app(_FakeCreateItemService(), draftStorage: storage),
    );
    await tester.pumpAndSettle();

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.fields['title']!.didChange('Дрель из черновика');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Отменить изменения?'), findsOneWidget);
    await tester.tap(find.text('Продолжить редактирование'));
    await tester.pumpAndSettle();
    expect(form.fields['title']!.value, 'Дрель из черновика');
    expect(find.byType(CreateItemScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отменить изменения'));
    await tester.pumpAndSettle();
    expect(storage.draft, isNull);
  });

  testWidgets('keeps a focused field visible above keyboard and safe areas', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 900);
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        _FakeCreateItemService(),
        draftStorage: _FakeDraftStorage(const LocalCreateItemDraft(step: 2)),
      ),
    );
    await tester.pumpAndSettle();

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.fields['address']!.focus();
    form.fields['address']!.ensureScrollableVisibility();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final address = find.widgetWithText(
      FormBuilderTextField,
      'Точный адрес передачи (приватно)',
    );
    expect(tester.getBottomRight(address).dy, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  CreateItemService service, {
  ItemPhotoPicker? picker,
  AppPermissionGateway? permissions,
  CreateItemDraftStorage? draftStorage,
}) {
  return ProviderScope(
    overrides: [
      catalogServiceProvider.overrideWithValue(_FakeCatalogService()),
      createItemServiceProvider.overrideWithValue(service),
      createItemDraftStorageProvider.overrideWithValue(
        draftStorage ?? _FakeDraftStorage(),
      ),
      appPermissionGatewayProvider.overrideWithValue(
        permissions ?? _FakePermissionGateway(PermissionStatus.granted),
      ),
      if (picker != null) itemPhotoPickerProvider.overrideWithValue(picker),
    ],
    child: const MaterialApp(home: CreateItemScreen()),
  );
}

void _useTallSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1000, 4000);
  addTearDown(tester.view.reset);
}

class _FakeCatalogService extends CatalogService {
  _FakeCatalogService() : super(Dio());

  @override
  Future<List<CatalogCategory>> fetchCategories() async => [category];
}

class _FakeCreateItemService extends CreateItemService {
  _FakeCreateItemService() : super(Dio());

  int calls = 0;
  CreateItemDraft? lastDraft;

  @override
  Future<CreateItemResult> create(
    CreateItemDraft draft, {
    required String requestId,
  }) async {
    calls += 1;
    lastDraft = draft;
    return const CreateItemResult(id: 'item-1', status: 'PENDING');
  }
}

class _FakePhotoPicker extends ItemPhotoPicker {
  _FakePhotoPicker([List<XFile>? photos])
    : _photos = photos ?? [_photo('photo.jpg')],
      super(ImagePicker());

  final List<XFile> _photos;
  var calls = 0;

  @override
  Future<List<XFile>> pick() async {
    calls += 1;
    return _photos;
  }
}

XFile _photo(String name) {
  return XFile.fromData(
    Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    ),
    path: name,
    name: name,
    mimeType: 'image/png',
  );
}

class _FakeDraftStorage extends CreateItemDraftStorage {
  _FakeDraftStorage([this.draft]);

  LocalCreateItemDraft? draft;

  @override
  Future<LocalCreateItemDraft?> load() async => draft;

  @override
  Future<void> save(LocalCreateItemDraft value) async {
    draft = value;
  }

  @override
  Future<void> clear() async {
    draft = null;
  }
}

class _FakePermissionGateway implements AppPermissionGateway {
  _FakePermissionGateway(this.status);

  final PermissionStatus status;
  var settingsCalls = 0;

  @override
  Future<PermissionStatus> request(AppPermission permission) async => status;

  @override
  Future<bool> openSettings() async {
    settingsCalls += 1;
    return true;
  }
}

const category = CatalogCategory(
  id: '22222222-2222-4222-8222-222222222222',
  name: 'Инструменты',
  slug: 'tools',
  safetyNotice: 'Используйте защитные очки',
);
