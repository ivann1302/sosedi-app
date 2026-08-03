import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/domain/catalog_controller.dart';
import '../data/create_item_models.dart';
import '../domain/create_item_controller.dart';

const _listingRulesVersion = '2026-07-28';

final itemPhotoPickerProvider = Provider<ItemPhotoPicker>((ref) {
  return ItemPhotoPicker(ImagePicker());
});

class ItemPhotoPicker {
  const ItemPhotoPicker(this._picker);

  final ImagePicker _picker;

  Future<List<XFile>> pick() {
    return _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
      limit: 5,
    );
  }
}

class CreateItemScreen extends ConsumerStatefulWidget {
  const CreateItemScreen({super.key});

  @override
  ConsumerState<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends ConsumerState<CreateItemScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<XFile> _photos = const [];
  var _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(catalogCategoriesProvider);
    final submission = ref.watch(createItemProvider);

    if (submission.value case final result?) {
      return _CreatedItem(
        result: result,
        onRetryPhotos: () =>
            ref.read(createItemProvider.notifier).retryPhotos(),
      );
    }

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(title: const Text('Новое объявление')),
        body: SafeArea(
          child: categories.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _CategoriesError(
              onRetry: () => ref.invalidate(catalogCategoriesProvider),
            ),
            data: (value) => _buildForm(
              value,
              isSubmitting: submission.isLoading,
              error: submission.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    List<CatalogCategory> categories, {
    required bool isSubmitting,
    required Object? error,
  }) {
    return FormBuilder(
      key: _formKey,
      onChanged: _markDirty,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (error != null) ...[
            const Text(
              'Не удалось отправить объявление. Проверьте данные и повторите.',
            ),
            const SizedBox(height: 16),
          ],
          _text(
            name: 'title',
            label: 'Название',
            validators: [
              FormBuilderValidators.required(errorText: 'Обязательное поле'),
              FormBuilderValidators.minLength(3),
              FormBuilderValidators.maxLength(120),
            ],
          ),
          _text(
            name: 'description',
            label: 'Описание',
            maxLines: 4,
            validators: [
              FormBuilderValidators.required(errorText: 'Обязательное поле'),
              FormBuilderValidators.minLength(10),
              FormBuilderValidators.maxLength(4000),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FormBuilderDropdown<String>(
              name: 'categoryId',
              decoration: const InputDecoration(labelText: 'Категория'),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(growable: false),
              validator: FormBuilderValidators.required(
                errorText: 'Обязательное поле',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FormBuilderDropdown<String>(
              name: 'condition',
              decoration: const InputDecoration(labelText: 'Состояние'),
              items: const [
                DropdownMenuItem(value: 'NEW', child: Text('Новое')),
                DropdownMenuItem(value: 'LIKE_NEW', child: Text('Как новое')),
                DropdownMenuItem(value: 'GOOD', child: Text('Хорошее')),
                DropdownMenuItem(
                  value: 'FAIR',
                  child: Text('Удовлетворительное'),
                ),
              ],
              validator: FormBuilderValidators.required(
                errorText: 'Обязательное поле',
              ),
            ),
          ),
          _text(
            name: 'completeness',
            label: 'Комплектация',
            maxLines: 2,
            validators: [
              FormBuilderValidators.required(errorText: 'Обязательное поле'),
              FormBuilderValidators.minLength(3),
              FormBuilderValidators.maxLength(1000),
            ],
          ),
          _text(
            name: 'handoverTerms',
            label: 'Передача и безопасность',
            maxLines: 3,
            validators: [
              FormBuilderValidators.required(errorText: 'Обязательное поле'),
              FormBuilderValidators.minLength(3),
              FormBuilderValidators.maxLength(1000),
            ],
          ),
          _number(
            name: 'pricePerDay',
            label: 'Цена за день, ₽',
            min: 1,
            max: 1000000,
          ),
          _text(
            name: 'publicArea',
            label: 'Район для публичной карточки',
            validators: [
              FormBuilderValidators.required(errorText: 'Обязательное поле'),
              FormBuilderValidators.minLength(2),
              FormBuilderValidators.maxLength(120),
            ],
          ),
          _text(
            name: 'address',
            label: 'Точный адрес передачи (приватно)',
            validators: [
              FormBuilderValidators.required(errorText: 'Обязательное поле'),
              FormBuilderValidators.minLength(5),
              FormBuilderValidators.maxLength(300),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _number(
                  name: 'latitude',
                  label: 'Широта',
                  min: -90,
                  max: 90,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _number(
                  name: 'longitude',
                  label: 'Долгота',
                  min: -180,
                  max: 180,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isSubmitting ? null : _pickPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _photos.isEmpty
                  ? 'Добавить фото'
                  : 'Выбрано фото: ${_photos.length}',
            ),
          ),
          if (_photos.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _photos
                  .map(
                    (photo) => InputChip(
                      label: Text(photo.name),
                      onDeleted: isSubmitting
                          ? null
                          : () => setState(
                              () => _photos = _photos
                                  .where((candidate) => candidate != photo)
                                  .toList(growable: false),
                            ),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 12),
          _confirmation(
            'ownershipConfirmed',
            'Я вправе распоряжаться этой вещью',
          ),
          _confirmation('conditionConfirmed', 'Состояние вещи указано верно'),
          _confirmation(
            'completenessConfirmed',
            'Комплектация указана полностью',
          ),
          _confirmation(
            'safetyAndMarketplaceRulesAccepted',
            'Я принимаю правила публикации $_listingRulesVersion и требования безопасности категории',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Отправить на модерацию'),
          ),
        ],
      ),
    );
  }

  Widget _text({
    required String name,
    required String label,
    required List<String? Function(String?)> validators,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormBuilderTextField(
        name: name,
        decoration: InputDecoration(labelText: label),
        maxLines: maxLines,
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
          FormBuilderValidators.required(errorText: 'Обязательное поле'),
          FormBuilderValidators.numeric(),
          FormBuilderValidators.min(min),
          FormBuilderValidators.max(max),
        ]),
      ),
    );
  }

  Widget _confirmation(String name, String title) {
    return FormBuilderCheckbox(
      name: name,
      initialValue: false,
      title: Text(title),
      validator: FormBuilderValidators.equal(
        true,
        errorText: 'Нужно подтверждение',
      ),
    );
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final values = form.value;
    ref
        .read(createItemProvider.notifier)
        .submit(
          CreateItemDraft(
            categoryId: values['categoryId']! as String,
            title: (values['title']! as String).trim(),
            description: (values['description']! as String).trim(),
            condition: values['condition']! as String,
            completeness: (values['completeness']! as String).trim(),
            handoverTerms: (values['handoverTerms']! as String).trim(),
            pricePerDay: _double(values['pricePerDay']),
            publicArea: (values['publicArea']! as String).trim(),
            address: (values['address']! as String).trim(),
            latitude: _double(values['latitude']),
            longitude: _double(values['longitude']),
            ownershipConfirmed: values['ownershipConfirmed']! as bool,
            conditionConfirmed: values['conditionConfirmed']! as bool,
            completenessConfirmed: values['completenessConfirmed']! as bool,
            safetyAndMarketplaceRulesAccepted:
                values['safetyAndMarketplaceRulesAccepted']! as bool,
            listingRulesVersion: _listingRulesVersion,
          ),
          _photos,
        );
  }

  double _double(Object? value) => double.parse(value! as String);

  Future<void> _pickPhotos() async {
    final allowed = await requestPermissionFromUserAction(
      context: context,
      ref: ref,
      permission: AppPermission.photos,
    );
    if (!allowed || !mounted) {
      return;
    }
    final photos = await ref.read(itemPhotoPickerProvider).pick();
    if (!mounted || photos.isEmpty) {
      return;
    }
    setState(() {
      _photos = photos.take(5).toList(growable: false);
      _hasUnsavedChanges = true;
    });
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }
}

class _CreatedItem extends StatelessWidget {
  const _CreatedItem({required this.result, required this.onRetryPhotos});

  final CreateItemResult result;
  final VoidCallback onRetryPhotos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новое объявление')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'На модерации',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Объявление станет доступно в каталоге только после проверки.',
                textAlign: TextAlign.center,
              ),
              if (result.isUploadingPhotos) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                const Text('Загружаем фото…'),
              ],
              if (result.photoUploadFailed) ...[
                const SizedBox(height: 16),
                const Text(
                  'Объявление создано, но фото не загрузились.',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: onRetryPhotos,
                  child: const Text('Повторить загрузку фото'),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: result.isUploadingPhotos
                    ? null
                    : () => context.go('/home'),
                child: const Text('Готово'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('Повторить')),
    );
  }
}
