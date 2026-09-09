import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/listing_point_picker.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../../../shared/widgets/inline_select_field.dart';
import '../../../shared/widgets/item_photo_image.dart';
import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../../booking/domain/booking_date_rules.dart';
import '../../catalog/domain/catalog_controller.dart';
import '../../payments/data/marketplace_policy_models.dart';
import '../../payments/data/marketplace_policy_service.dart';
import '../data/owned_item_models.dart';
import '../data/owned_items_service.dart';
import '../domain/edit_item_controller.dart';
import 'create_item_screen.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  const EditItemScreen({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  var _hasUnsavedChanges = false;
  String? _depositMode;
  GeoPoint? _selectedPoint;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ownedItemsProvider);
    final categories = ref.watch(catalogCategoriesProvider);
    final update = ref.watch(editItemProvider);
    final photoUpload = ref.watch(editItemPhotoProvider);
    final policy = ref.watch(marketplacePolicyProvider);

    if (update.value != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактирование')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'На модерации',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Изменения сохранены и будут опубликованы после проверки.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Готово'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(title: const Text('Редактирование')),
        body: SafeArea(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _Retry(onRetry: () => ref.invalidate(ownedItemsProvider)),
            data: (ownedItems) {
              final matches = ownedItems.where(
                (item) => item.id == widget.itemId,
              );
              if (matches.isEmpty) {
                return const Center(child: Text('Объявление не найдено'));
              }
              final item = matches.single;
              final selectedPoint =
                  _selectedPoint ??
                  (latitude: item.latitude, longitude: item.longitude);
              final initialDepositMode =
                  item.depositAmount != null && item.depositAmount! > 0
                  ? 'with'
                  : 'none';
              final depositMode = _depositMode ?? initialDepositMode;
              return categories.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _Retry(
                  onRetry: () => ref.invalidate(catalogCategoriesProvider),
                ),
                data: (values) => FormBuilder(
                  key: _formKey,
                  initialValue: {
                    'title': item.title,
                    'description': item.description,
                    'categoryId': item.category.id,
                    'condition': item.condition,
                    'completeness': item.completeness,
                    'handoverTerms': item.handoverTerms,
                    'pricePerDay': _price(item.pricePerDay),
                    'publicArea': item.publicArea,
                    'address': item.address,
                    'depositMode': depositMode,
                    'depositAmount': item.depositAmount == null
                        ? null
                        : _price(item.depositAmount!),
                  },
                  onChanged: _markDirty,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: [
                            _PhotoEditor(
                              item: item,
                              isLoading: photoUpload.isLoading,
                              error: photoUpload.error,
                              onAdd: () => _appendPhotos(item),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Объявление',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _text(
                              name: 'title',
                              label: 'Название',
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(3),
                                FormBuilderValidators.maxLength(120),
                              ],
                            ),
                            _text(
                              name: 'description',
                              label: 'Описание',
                              maxLines: 4,
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(10),
                                FormBuilderValidators.maxLength(4000),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Состояние и комплектация',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            FormBuilderInlineSelect<String>(
                              name: 'categoryId',
                              decoration: const InputDecoration(
                                labelText: 'Категория',
                              ),
                              items: values
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category.id,
                                      child: Text(category.name),
                                    ),
                                  )
                                  .toList(growable: false),
                              validator: FormBuilderValidators.required(),
                            ),
                            const SizedBox(height: 12),
                            FormBuilderInlineSelect<String>(
                              name: 'condition',
                              decoration: const InputDecoration(
                                labelText: 'Состояние',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'NEW',
                                  child: Text('Новое'),
                                ),
                                DropdownMenuItem(
                                  value: 'LIKE_NEW',
                                  child: Text('Как новое'),
                                ),
                                DropdownMenuItem(
                                  value: 'GOOD',
                                  child: Text('Хорошее'),
                                ),
                                DropdownMenuItem(
                                  value: 'FAIR',
                                  child: Text('Удовлетворительное'),
                                ),
                              ],
                              validator: FormBuilderValidators.required(),
                            ),
                            const SizedBox(height: 12),
                            _text(
                              name: 'completeness',
                              label: 'Комплектация',
                              maxLines: 2,
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(3),
                                FormBuilderValidators.maxLength(1000),
                              ],
                            ),
                            _text(
                              name: 'handoverTerms',
                              label: 'Условия передачи и использования',
                              helperText:
                                  'Опишите, как передадите вещь, что проверить при получении и какие правила использования важны. Точный адрес укажете на следующем шаге.',
                              hintText:
                                  'Например: встречаемся у метро, вместе проверяем комплект',
                              maxLines: 3,
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(3),
                                FormBuilderValidators.maxLength(1000),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Цена и место передачи',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _number(
                              name: 'pricePerDay',
                              label: 'Цена за день, ₽',
                              min: 1,
                              max: 1000000,
                            ),
                            _depositControls(
                              policy,
                              update.isLoading,
                              depositMode,
                            ),
                            _text(
                              name: 'publicArea',
                              label: 'Район',
                              hintText: 'Например: Пресненский',
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(2),
                                FormBuilderValidators.maxLength(120),
                              ],
                            ),
                            _text(
                              name: 'address',
                              label: 'Адрес передачи',
                              hintText: 'Например: Москва, ул. Лесная, д. 10',
                              helperText:
                                  'Точный адрес увидят только участники подтверждённой аренды.',
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.minLength(5),
                                FormBuilderValidators.maxLength(300),
                              ],
                              enabled: !update.isLoading,
                            ),
                            OutlinedButton.icon(
                              onPressed: update.isLoading
                                  ? null
                                  : () => _pickLocation(selectedPoint),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Изменить точку на карте'),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Точка выбрана'),
                            ),
                            const SizedBox(height: 24),
                            _AvailabilityEditor(itemId: item.id),
                            if (update.hasError) ...[
                              const SizedBox(height: 16),
                              const Text('Не удалось сохранить изменения'),
                            ],
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: update.isLoading
                                  ? null
                                  : () => _submit(item),
                              child: update.isLoading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Сохранить и отправить на модерацию',
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _depositControls(
    AsyncValue<MarketplacePolicy> policy,
    bool isSubmitting,
    String depositMode,
  ) {
    return policy.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => Row(
        children: [
          const Expanded(child: Text('Не удалось загрузить условия залога')),
          TextButton(
            onPressed: () => ref.invalidate(marketplacePolicyProvider),
            child: const Text('Повторить'),
          ),
        ],
      ),
      data: (value) {
        final maximumMinor = value.deposit.maximumMinor;
        if (!value.deposit.enabled) {
          return const SizedBox.shrink();
        }
        if (maximumMinor == null) {
          return const Text('Не удалось загрузить условия залога');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Залог', style: Theme.of(context).textTheme.titleMedium),
            Text('Максимальный залог: ${formatDepositRubles(maximumMinor)} ₽'),
            FormBuilderRadioGroup<String>(
              name: 'depositMode',
              enabled: !isSubmitting,
              onChanged: (mode) {
                if (mode != null && mode != depositMode) {
                  setState(() => _depositMode = mode);
                }
              },
              options: const [
                FormBuilderFieldOption(
                  value: 'none',
                  child: Text('Без залога'),
                ),
                FormBuilderFieldOption(value: 'with', child: Text('С залогом')),
              ],
            ),
            if (depositMode == 'with')
              FormBuilderTextField(
                name: 'depositAmount',
                decoration: const InputDecoration(labelText: 'Сумма залога, ₽'),
                enabled: !isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _text({
    required String name,
    required String label,
    required List<String? Function(String?)> validators,
    int maxLines = 1,
    String? hintText,
    String? helperText,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormBuilderTextField(
        name: name,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          helperMaxLines: helperText == null ? null : 3,
        ),
        maxLines: maxLines,
        enabled: enabled,
        validator: FormBuilderValidators.compose(validators),
      ),
    );
  }

  Widget _number({
    required String name,
    required String label,
    required num min,
    required num max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormBuilderTextField(
        name: name,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
          FormBuilderValidators.numeric(),
          FormBuilderValidators.min(min),
          FormBuilderValidators.max(max),
        ]),
      ),
    );
  }

  void _submit(OwnedItem item) {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final values = form.value;
    final selectedPoint =
        _selectedPoint ?? (latitude: item.latitude, longitude: item.longitude);
    int? depositAmountMinor;
    final policy = ref.read(marketplacePolicyProvider).value;
    if (policy?.deposit.enabled == true) {
      if (values['depositMode'] == 'with') {
        final maximumMinor = policy!.deposit.maximumMinor;
        if (maximumMinor == null) {
          return;
        }
        try {
          depositAmountMinor = parseDepositAmountMinor(
            values['depositAmount'] as String? ?? '',
            maximumMinor: maximumMinor,
          );
        } on DepositAmountFormatException catch (error) {
          form.fields['depositAmount']?.invalidate(error.message);
          return;
        }
      } else {
        depositAmountMinor = 0;
      }
    }
    ref
        .read(editItemProvider.notifier)
        .submit(
          item.id,
          UpdateItemDraft(
            title: (values['title']! as String).trim(),
            description: (values['description']! as String).trim(),
            categoryId: values['categoryId']! as String,
            condition: values['condition']! as String,
            completeness: (values['completeness']! as String).trim(),
            handoverTerms: (values['handoverTerms']! as String).trim(),
            pricePerDay: _double(values['pricePerDay']),
            publicArea: (values['publicArea']! as String).trim(),
            address: (values['address']! as String).trim(),
            latitude: selectedPoint.latitude,
            longitude: selectedPoint.longitude,
            depositAmountMinor: depositAmountMinor,
          ),
        );
  }

  double _double(Object? value) => double.parse(value! as String);

  Future<void> _pickLocation(GeoPoint initialPoint) async {
    final point = await ref.read(listingPointPickerProvider)(
      context,
      initialPoint,
    );
    if (!mounted || point == null) {
      return;
    }
    setState(() {
      _selectedPoint = point;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _appendPhotos(OwnedItem item) async {
    final allowed = await requestPermissionFromUserAction(
      context: context,
      ref: ref,
      permission: AppPermission.photos,
    );
    if (!allowed || !mounted) {
      return;
    }
    final picked = await ref.read(itemPhotoPickerProvider).pick();
    if (!mounted || picked.isEmpty) {
      return;
    }
    final remaining = 5 - item.photos.length;
    if (remaining <= 0) {
      return;
    }
    final success = await ref
        .read(editItemPhotoProvider.notifier)
        .append(
          item.id,
          picked.take(remaining).toList(growable: false),
          startSortOrder: item.photos.fold(
            0,
            (next, photo) =>
                photo.sortOrder >= next ? photo.sortOrder + 1 : next,
          ),
        );
    if (!mounted || !success) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Фото добавлены и отправлены на модерацию')),
    );
  }

  String _price(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }
}

class _PhotoEditor extends StatelessWidget {
  const _PhotoEditor({
    required this.item,
    required this.isLoading,
    required this.error,
    required this.onAdd,
  });

  final OwnedItem item;
  final bool isLoading;
  final Object? error;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final atLimit = item.photos.length >= 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Фото: ${item.photos.length} из 5'),
        const SizedBox(height: 8),
        if (item.photos.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.photos
                .map(
                  (photo) => Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: photo.thumbnailUrl == null
                        ? Icon(
                            photo.isCover
                                ? Icons.photo_outlined
                                : Icons.image_outlined,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: ItemPhotoImage(
                              source: photo.thumbnailUrl!,
                              semanticLabel: 'Фото объявления',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                )
                .toList(growable: false),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isLoading || atLimit ? null : onAdd,
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(atLimit ? 'Достигнут лимит фото' : 'Добавить фото'),
        ),
        if (error != null)
          Text(userFacingError(error!, fallback: 'Не удалось добавить фото')),
      ],
    );
  }
}

class _AvailabilityEditor extends ConsumerWidget {
  const _AvailabilityEditor({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(unavailablePeriodsProvider(itemId));
    final action = ref.watch(editItemAvailabilityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Недоступные даты', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('Отметьте дни, когда вещь нельзя забронировать.'),
        const SizedBox(height: 12),
        periods.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Row(
            children: [
              Expanded(
                child: Text(
                  userFacingError(
                    error,
                    fallback: 'Не удалось загрузить календарь',
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(unavailablePeriodsProvider(itemId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
          data: (values) => values.isEmpty
              ? const Text('Периоды не добавлены')
              : Column(
                  children: values
                      .map(
                        (period) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_busy_outlined),
                          title: Text(
                            '${_date(period.startDate)} — '
                            '${_date(period.endDate)}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Удалить период',
                            onPressed: action.isLoading
                                ? null
                                : () => _remove(context, ref, period.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: action.isLoading ? null : () => _add(context, ref),
          icon: action.isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Добавить период'),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: bookingHorizonDays)),
    );
    if (selected == null || !context.mounted) {
      return;
    }
    if (!isAllowedBookingRange(selected.start, selected.end, today)) {
      _showMessage(
        context,
        'Один период должен быть не длиннее $bookingMaxDays дней',
      );
      return;
    }
    final success = await ref
        .read(editItemAvailabilityProvider.notifier)
        .add(
          itemId,
          CreateUnavailablePeriodDraft(
            startDate: _apiDate(selected.start),
            endDate: _apiDate(selected.end),
          ),
        );
    if (!success && context.mounted) {
      _showActionError(context, ref);
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    String periodId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить период?'),
        content: const Text('Эти даты снова станут доступны для бронирования.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final success = await ref
        .read(editItemAvailabilityProvider.notifier)
        .remove(itemId, periodId);
    if (!success && context.mounted) {
      _showActionError(context, ref);
    }
  }

  void _showActionError(BuildContext context, WidgetRef ref) {
    final error = ref.read(editItemAvailabilityProvider).error;
    _showMessage(
      context,
      error == null
          ? 'Не удалось изменить календарь'
          : userFacingError(error, fallback: 'Не удалось изменить календарь'),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Повторить')),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

String _apiDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
