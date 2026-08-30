import 'dart:async';
import 'dart:typed_data';

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
import '../data/create_item_draft_storage.dart';
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
  var _step = 0;
  var _draftLoading = true;
  var _photoError = false;
  Map<String, dynamic> _initialValue = const {};
  late final CreateItemDraftStorage _draftStorage;
  Future<void> _draftWrites = Future.value();

  @override
  void initState() {
    super.initState();
    _draftStorage = ref.read(createItemDraftStorageProvider);
    unawaited(_restoreDraft());
  }

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
      onDiscard: _draftStorage.clear,
      child: Scaffold(
        appBar: AppBar(title: const Text('Новое объявление')),
        body: SafeArea(
          child: _draftLoading
              ? const Center(child: CircularProgressIndicator())
              : categories.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
      initialValue: _initialValue,
      onChanged: _onFormChanged,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Шаг ${_step + 1} из 3',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(value: (_step + 1) / 3),
                ),
              ],
            ),
          ),
          if (error != null)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'Не удалось отправить объявление. Проверьте данные и повторите.',
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _photoStep(isSubmitting),
                _descriptionStep(categories, isSubmitting),
                _locationStep(isSubmitting),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    TextButton(
                      onPressed: isSubmitting ? null : _previousStep,
                      child: const Text('Назад'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : switch (_step) {
                              0 => _nextFromPhotos,
                              1 => _nextFromDescription,
                              _ => _submit,
                            },
                      child: isSubmitting && _step == 2
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_step == 2 ? 'На модерацию' : 'Далее'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoStep(bool isSubmitting) {
    return ListView(
      key: const ValueKey('create-item-photo-step'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Покажите вещь', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Добавьте до 5 чётких фото. Первое будет главным в каталоге.',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: isSubmitting ? null : _pickPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            _photos.isEmpty
                ? 'Добавить фото'
                : 'Выбрано фото: ${_photos.length}',
          ),
        ),
        if (_photoError)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Добавьте хотя бы одно фото',
              style: TextStyle(color: Colors.red),
            ),
          ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Нажмите на фото, чтобы сделать его главным.'),
          const SizedBox(height: 8),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _SelectedPhotoCard(
                photo: _photos[index],
                isCover: index == 0,
                enabled: !isSubmitting,
                onMakeCover: () => _makeCover(index),
                onDelete: () => _removePhoto(index),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _descriptionStep(List<CatalogCategory> categories, bool isSubmitting) {
    return ListView(
      key: const ValueKey('create-item-description-step'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Расскажите о вещи',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 12),
        Text(
          'Состояние и комплектация',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }

  Widget _locationStep(bool isSubmitting) {
    return ListView(
      key: const ValueKey('create-item-location-step'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Цена и место передачи',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Точный адрес видят только участники подтверждённой аренды.',
        ),
        const SizedBox(height: 16),
        _number(
          name: 'pricePerDay',
          label: 'Цена за день, ₽',
          min: 1,
          max: 1000000,
        ),
        const SizedBox(height: 12),
        Text('Место передачи', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
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
        const Text(
          'Координаты вводятся вручную — временно, до подключения карты.',
        ),
        const SizedBox(height: 12),
        Text('Подтверждение', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
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
      ],
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

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (_photos.isEmpty) {
      setState(() {
        _step = 0;
        _photoError = true;
      });
      return;
    }
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final values = form.value;
    await ref
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
    if (ref.read(createItemProvider).value != null) {
      await _draftStorage.clear();
      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
      }
    }
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
      _photoError = false;
    });
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftStorage.load();
    if (!mounted) {
      return;
    }
    setState(() {
      if (draft != null) {
        _step = draft.step < 0 ? 0 : (draft.step > 2 ? 2 : draft.step);
        _initialValue = {
          'categoryId': draft.categoryId,
          'title': draft.title,
          'description': draft.description,
          'condition': draft.condition,
          'completeness': draft.completeness,
          'handoverTerms': draft.handoverTerms,
          'pricePerDay': draft.pricePerDay,
          'publicArea': draft.publicArea,
        };
        _hasUnsavedChanges = _initialValue.values.any(
          (value) => value is String && value.isNotEmpty,
        );
      }
      _draftLoading = false;
    });
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _persistDraft();
  }

  void _persistDraft() {
    final values = _formKey.currentState?.instantValue ?? _initialValue;
    final draft = LocalCreateItemDraft(
      step: _step,
      categoryId: _stringValue(values['categoryId']),
      title: _stringValue(values['title']),
      description: _stringValue(values['description']),
      condition: _stringValue(values['condition']),
      completeness: _stringValue(values['completeness']),
      handoverTerms: _stringValue(values['handoverTerms']),
      pricePerDay: _stringValue(values['pricePerDay']),
      publicArea: _stringValue(values['publicArea']),
    );
    _draftWrites = _draftWrites
        .catchError((Object _, StackTrace _) {})
        .then((_) => _draftStorage.save(draft));
    unawaited(_draftWrites.catchError((Object _, StackTrace _) {}));
  }

  String? _stringValue(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return value;
  }

  void _nextFromPhotos() {
    if (_photos.isEmpty) {
      setState(() => _photoError = true);
      return;
    }
    setState(() {
      _photoError = false;
      _step = 1;
    });
    _persistDraft();
  }

  void _nextFromDescription() {
    if (!_validateFields(const [
      'title',
      'description',
      'categoryId',
      'condition',
      'completeness',
      'handoverTerms',
    ])) {
      return;
    }
    setState(() => _step = 2);
    _persistDraft();
  }

  bool _validateFields(List<String> names) {
    var valid = true;
    final fields = _formKey.currentState?.fields;
    if (fields == null) {
      return false;
    }
    for (final name in names) {
      if (!(fields[name]?.validate() ?? false)) {
        valid = false;
      }
    }
    return valid;
  }

  void _previousStep() {
    if (_step == 0) {
      return;
    }
    setState(() => _step -= 1);
    _persistDraft();
  }

  void _makeCover(int index) {
    if (index <= 0 || index >= _photos.length) {
      return;
    }
    setState(() {
      final selected = _photos[index];
      _photos = [
        selected,
        for (var itemIndex = 0; itemIndex < _photos.length; itemIndex += 1)
          if (itemIndex != index) _photos[itemIndex],
      ];
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos = [
        for (var itemIndex = 0; itemIndex < _photos.length; itemIndex += 1)
          if (itemIndex != index) _photos[itemIndex],
      ];
      _photoError = _photos.isEmpty;
    });
  }
}

class _SelectedPhotoCard extends StatefulWidget {
  const _SelectedPhotoCard({
    required this.photo,
    required this.isCover,
    required this.enabled,
    required this.onMakeCover,
    required this.onDelete,
  });

  final XFile photo;
  final bool isCover;
  final bool enabled;
  final VoidCallback onMakeCover;
  final VoidCallback onDelete;

  @override
  State<_SelectedPhotoCard> createState() => _SelectedPhotoCardState();
}

class _SelectedPhotoCardState extends State<_SelectedPhotoCard> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.photo.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant _SelectedPhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.path != widget.photo.path) {
      _bytes = widget.photo.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.enabled,
      label: widget.isCover
          ? 'Главное фото ${widget.photo.name}'
          : 'Сделать главным фото ${widget.photo.name}',
      child: SizedBox(
        width: 136,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: InkWell(
              key: ValueKey('selected-photo-${widget.photo.name}'),
              onTap: widget.enabled ? widget.onMakeCover : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List>(
                    future: _bytes,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const _PhotoPreviewFallback();
                      }
                      if (!snapshot.hasData) {
                        return const ColoredBox(
                          color: Color(0xFFFFF0D6),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            const _PhotoPreviewFallback(),
                      );
                    },
                  ),
                  if (widget.isCover)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 15),
                              SizedBox(width: 4),
                              Text('Главное', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton.filledTonal(
                      key: ValueKey(
                        'delete-selected-photo-${widget.photo.name}',
                      ),
                      onPressed: widget.enabled ? widget.onDelete : null,
                      tooltip: 'Удалить фото ${widget.photo.name}',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          widget.photo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPreviewFallback extends StatelessWidget {
  const _PhotoPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFF0D6),
      child: Center(child: Icon(Icons.broken_image_outlined, size: 36)),
    );
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
                    : () => context.go('/items/mine'),
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
