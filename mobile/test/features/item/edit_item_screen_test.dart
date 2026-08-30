import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/permissions/app_permissions.dart';
import 'package:mobile/features/catalog/data/catalog_models.dart';
import 'package:mobile/features/catalog/domain/catalog_controller.dart';
import 'package:mobile/features/item/data/create_item_service.dart';
import 'package:mobile/features/item/data/owned_item_models.dart';
import 'package:mobile/features/item/data/owned_items_service.dart';
import 'package:mobile/features/item/presentation/create_item_screen.dart';
import 'package:mobile/features/item/presentation/edit_item_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  testWidgets('edits an owned item and shows moderation status', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 4000);
    addTearDown(tester.view.reset);
    final service = _FakeOwnedItemsService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownedItemsProvider.overrideWith((ref) async => [item]),
          catalogCategoriesProvider.overrideWith((ref) async => [category]),
          ownedItemsServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(home: EditItemScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();

    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.patchValue({
      'title': 'Перфоратор Bosch',
      'condition': 'LIKE_NEW',
      'completeness': 'Кейс, два бура и ограничитель',
      'handoverTerms': 'Проверить при встрече',
      'pricePerDay': '500',
      'publicArea': 'Арбат',
      'address': 'Москва, улица Новый Арбат, 1',
      'latitude': '55.752',
      'longitude': '37.6',
    });
    await tester.pump();
    await tester.tap(find.text('Сохранить и отправить на модерацию'));
    await tester.pumpAndSettle();

    expect(service.lastDraft?.title, 'Перфоратор Bosch');
    expect(service.lastDraft?.condition, 'LIKE_NEW');
    expect(service.lastDraft?.completeness, 'Кейс, два бура и ограничитель');
    expect(service.lastDraft?.publicArea, 'Арбат');
    expect(service.lastDraft?.address, 'Москва, улица Новый Арбат, 1');
    expect(service.lastDraft?.latitude, 55.752);
    expect(find.text('На модерации'), findsOneWidget);
  });

  testWidgets('removes an owner unavailable period after confirmation', (
    tester,
  ) async {
    final service = _FakeOwnedItemsService(
      periods: [
        UnavailablePeriod(
          id: 'period-1',
          itemId: item.id,
          startDate: DateTime.utc(2026, 8),
          endDate: DateTime.utc(2026, 8, 3),
          createdAt: DateTime.utc(2026, 7, 29),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownedItemsProvider.overrideWith((ref) async => [item]),
          catalogCategoriesProvider.overrideWith((ref) async => [category]),
          ownedItemsServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(home: EditItemScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('01.08.2026 — 03.08.2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Удалить период'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();

    expect(service.deletedPeriodId, 'period-1');
    expect(find.text('Периоды не добавлены'), findsOneWidget);
  });

  testWidgets('appends photos after the existing cover', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 4000);
    addTearDown(tester.view.reset);
    final upload = _FakeCreateItemService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownedItemsProvider.overrideWith((ref) async => [item]),
          catalogCategoriesProvider.overrideWith((ref) async => [category]),
          ownedItemsServiceProvider.overrideWithValue(_FakeOwnedItemsService()),
          createItemServiceProvider.overrideWithValue(upload),
          itemPhotoPickerProvider.overrideWithValue(_FakePhotoPicker()),
          appPermissionGatewayProvider.overrideWithValue(
            _GrantedPermissionGateway(),
          ),
        ],
        child: MaterialApp(home: EditItemScreen(itemId: item.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Фото: 1 из 5'), findsOneWidget);
    await tester.tap(find.text('Добавить фото'));
    await tester.pumpAndSettle();

    expect(upload.itemId, item.id);
    expect(upload.startSortOrder, 1);
    expect(upload.photoCount, 1);
    expect(
      find.text('Фото добавлены и отправлены на модерацию'),
      findsOneWidget,
    );
  });
}

class _FakeOwnedItemsService extends OwnedItemsService {
  _FakeOwnedItemsService({List<UnavailablePeriod> periods = const []})
    : periods = [...periods],
      super(Dio());

  UpdateItemDraft? lastDraft;
  final List<UnavailablePeriod> periods;
  String? deletedPeriodId;

  @override
  Future<OwnedItem> updateItem(String id, UpdateItemDraft draft) async {
    lastDraft = draft;
    return item.copyWith(
      title: draft.title,
      description: draft.description,
      condition: draft.condition,
      completeness: draft.completeness,
      handoverTerms: draft.handoverTerms,
      category: category,
      pricePerDay: draft.pricePerDay,
      publicArea: draft.publicArea,
      address: draft.address,
      latitude: draft.latitude,
      longitude: draft.longitude,
      status: 'PENDING',
    );
  }

  @override
  Future<List<UnavailablePeriod>> fetchUnavailablePeriods(
    String itemId,
  ) async => [...periods];

  @override
  Future<void> deleteUnavailablePeriod(String itemId, String periodId) async {
    deletedPeriodId = periodId;
    periods.removeWhere((period) => period.id == periodId);
  }
}

class _FakeCreateItemService extends CreateItemService {
  _FakeCreateItemService() : super(Dio());

  String? itemId;
  int? startSortOrder;
  int? photoCount;

  @override
  Future<void> appendPhotos(
    String itemId,
    List<XFile> photos, {
    required int startSortOrder,
  }) async {
    this.itemId = itemId;
    this.startSortOrder = startSortOrder;
    photoCount = photos.length;
  }
}

class _FakePhotoPicker extends ItemPhotoPicker {
  _FakePhotoPicker() : super(ImagePicker());

  @override
  Future<List<XFile>> pick() async => [
    XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'new-photo.jpg',
      mimeType: 'image/jpeg',
    ),
  ];
}

class _GrantedPermissionGateway implements AppPermissionGateway {
  @override
  Future<bool> openSettings() async => true;

  @override
  Future<PermissionStatus> request(AppPermission permission) async =>
      PermissionStatus.granted;
}

const category = CatalogCategory(
  id: 'category-1',
  name: 'Инструменты',
  slug: 'tools',
  safetyNotice: 'Используйте защитные очки',
);

final item = OwnedItem(
  id: 'item-1',
  title: 'Перфоратор',
  description: 'Рабочий перфоратор для домашних работ',
  condition: 'GOOD',
  completeness: 'Кейс и два бура',
  handoverTerms: 'Проверить при передаче',
  status: 'APPROVED',
  publicArea: 'Хамовники',
  address: 'Москва, улица Примерная, 1',
  latitude: 55.75,
  longitude: 37.62,
  pricePerDay: 450,
  depositAmount: null,
  category: category,
  updatedAt: DateTime.utc(2026, 7, 29),
  photos: [
    CatalogPhoto(
      id: 'photo-1',
      sortOrder: 0,
      isCover: true,
      createdAt: DateTime.utc(2026, 7, 29),
    ),
  ],
);
