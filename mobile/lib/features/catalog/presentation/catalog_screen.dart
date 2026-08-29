import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../../../core/theme/app_theme.dart';
import '../data/catalog_models.dart';
import '../domain/catalog_controller.dart';
import '../../map/presentation/catalog_map_stub.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  bool _showDemoMap = false;
  String? _selectedDemoItemId;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final categories = ref.watch(catalogCategoriesProvider);
    final compactMapAction =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final mapActionIcon = Icon(
      _showDemoMap ? Icons.view_list_outlined : Icons.map_outlined,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Найти'),
        actions: [
          if (AppConfig.demoStubsEnabled)
            if (compactMapAction)
              IconButton(
                onPressed: _toggleDemoMap,
                tooltip: _showDemoMap
                    ? 'Показать список'
                    : 'Показать демо-карту',
                icon: mapActionIcon,
              )
            else
              TextButton.icon(
                onPressed: _toggleDemoMap,
                icon: mapActionIcon,
                label: Text(_showDemoMap ? 'Список' : 'Карта (демо)'),
              ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Что хотите найти?',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.slate700,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) =>
                    ref.read(catalogProvider.notifier).search(value),
              ),
            ),
            _QuickFilters(categories: categories),
            const SizedBox(height: 8),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _CatalogError(
                  message: userFacingError(
                    error,
                    fallback: 'Не удалось загрузить каталог',
                  ),
                  onRetry: () =>
                      ref.read(catalogProvider.notifier).refreshCatalog(),
                ),
                data: (value) => value.items.isEmpty
                    ? const _EmptyCatalog()
                    : Column(
                        children: [
                          if (value.isRefreshing)
                            const LinearProgressIndicator(),
                          if (value.refreshError != null)
                            MaterialBanner(
                              content: Text(
                                '${value.refreshError}. Показаны ранее '
                                'загруженные данные',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => ref
                                      .read(catalogProvider.notifier)
                                      .refreshCatalog(),
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          Expanded(
                            child: _showDemoMap
                                ? CatalogMapStub(
                                    items: value.items,
                                    selectedItemId: _selectedDemoItemId,
                                    onItemSelected: (itemId) => setState(
                                      () => _selectedDemoItemId = itemId,
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: () => ref
                                        .read(catalogProvider.notifier)
                                        .refreshCatalog(),
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount:
                                          value.items.length +
                                          (value.hasMore ? 1 : 0),
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        if (index == value.items.length) {
                                          return Center(
                                            child: value.isLoadingMore
                                                ? const CircularProgressIndicator()
                                                : OutlinedButton(
                                                    onPressed: () => ref
                                                        .read(
                                                          catalogProvider
                                                              .notifier,
                                                        )
                                                        .loadMore(),
                                                    child: const Text(
                                                      'Показать ещё',
                                                    ),
                                                  ),
                                          );
                                        }
                                        return _CatalogCard(
                                          item: value.items[index],
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDemoMap() {
    setState(() => _showDemoMap = !_showDemoMap);
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({required this.categories});

  final AsyncValue<List<CatalogCategory>> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const _AvailabilityChip(),
          const SizedBox(width: 8),
          categories.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const _CategoryErrorChip(),
            data: (value) => _CategoryChips(categories: value),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.tune, size: 18),
            label: const Text('Фильтры'),
            onPressed: () => _showFilters(context),
          ),
          const SizedBox(width: 8),
          const _SortChip(),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FilterSheet(),
    );
  }
}

class _SortChip extends ConsumerStatefulWidget {
  const _SortChip();

  @override
  ConsumerState<_SortChip> createState() => _SortChipState();
}

class _SortChipState extends ConsumerState<_SortChip> {
  CatalogSort _sort = CatalogSort.newest;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CatalogSort>(
      initialValue: _sort,
      tooltip: 'Сортировка',
      onSelected: _select,
      itemBuilder: (context) => CatalogSort.values
          .map(
            (sort) => PopupMenuItem(
              value: sort,
              child: Text(_label(sort)),
            ),
          )
          .toList(growable: false),
      child: Chip(
        avatar: const Icon(Icons.sort, size: 18),
        label: Text(_label(_sort)),
      ),
    );
  }

  Future<void> _select(CatalogSort sort) async {
    if (sort == _sort) {
      return;
    }
    setState(() => _sort = sort);
    await ref.read(catalogProvider.notifier).setSort(sort);
  }

  String _label(CatalogSort sort) => switch (sort) {
    CatalogSort.newest => 'Сначала новые',
    CatalogSort.priceAsc => 'Сначала дешевле',
    CatalogSort.priceDesc => 'Сначала дороже',
  };
}

class _CategoryChips extends ConsumerStatefulWidget {
  const _CategoryChips({required this.categories});

  final List<CatalogCategory> categories;

  @override
  ConsumerState<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends ConsumerState<_CategoryChips> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('Все категории'),
          selected: _selectedId == null,
          onSelected: (_) => _select(null),
        ),
        for (final category in widget.categories) ...[
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(category.name),
            selected: _selectedId == category.id,
            onSelected: (_) => _select(category.id),
          ),
        ],
      ],
    );
  }

  void _select(String? categoryId) {
    if (_selectedId == categoryId) {
      return;
    }
    setState(() => _selectedId = categoryId);
    ref.read(catalogProvider.notifier).selectCategory(categoryId);
  }
}

class _CategoryErrorChip extends ConsumerWidget {
  const _CategoryErrorChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      avatar: const Icon(Icons.refresh, size: 18),
      label: const Text('Категории'),
      onPressed: () => ref.invalidate(catalogCategoriesProvider),
    );
  }
}

class _AvailabilityChip extends ConsumerStatefulWidget {
  const _AvailabilityChip();

  @override
  ConsumerState<_AvailabilityChip> createState() => _AvailabilityChipState();
}

class _AvailabilityChipState extends ConsumerState<_AvailabilityChip> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return InputChip(
      avatar: const Icon(Icons.date_range_outlined, size: 18),
      label: Text(range == null ? 'Даты' : _label(context, range)),
      onPressed: _pick,
      onDeleted: range == null ? null : _clear,
    );
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      initialDateRange: _range,
      helpText: 'Выберите период аренды',
      saveText: 'Применить',
    );
    if (range == null || !mounted) {
      return;
    }
    setState(() => _range = range);
    await ref
        .read(catalogProvider.notifier)
        .setAvailability(_dateOnly(range.start), _dateOnly(range.end));
  }

  Future<void> _clear() async {
    setState(() => _range = null);
    await ref.read(catalogProvider.notifier).setAvailability(null, null);
  }

  String _label(BuildContext context, DateTimeRange range) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatCompactDate(range.start)}–'
        '${localizations.formatCompactDate(range.end)}';
  }

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Фильтры',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Закрыть',
                ),
              ],
            ),
            const _AreaFilter(),
            const SizedBox(height: 12),
            const _PriceFilter(),
            const SizedBox(height: 12),
            const _RadiusFilter(),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Показать результаты'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaFilter extends ConsumerStatefulWidget {
  const _AreaFilter();

  @override
  ConsumerState<_AreaFilter> createState() => _AreaFilterState();
}

class _AreaFilterState extends ConsumerState<_AreaFilter> {
  String? _area;

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(catalogAreasProvider);
    return areas.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => OutlinedButton.icon(
        onPressed: () => ref.invalidate(catalogAreasProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('Повторить загрузку районов'),
      ),
      data: (values) => DropdownButtonFormField<String>(
        initialValue: _area,
        decoration: const InputDecoration(
          labelText: 'Район',
          helperText: 'Ручной выбор не использует геолокацию',
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Любой район')),
          ...values.map(
            (area) => DropdownMenuItem(value: area, child: Text(area)),
          ),
        ],
        onChanged: _apply,
      ),
    );
  }

  Future<void> _apply(String? area) async {
    setState(() => _area = area);
    await ref.read(catalogProvider.notifier).setArea(area);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _RadiusFilter extends ConsumerStatefulWidget {
  const _RadiusFilter();

  @override
  ConsumerState<_RadiusFilter> createState() => _RadiusFilterState();
}

class _RadiusFilterState extends ConsumerState<_RadiusFilter> {
  static const _radii = [1.0, 3.0, 5.0, 10.0, 25.0, 50.0];

  double? _radiusKm;
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<double>(
      initialValue: _radiusKm,
      decoration: InputDecoration(
        labelText: 'Радиус поиска',
        helperText: 'Геопозиция используется только для поиска рядом',
        suffixIcon: _isApplying
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Без ограничения')),
        ..._radii.map(
          (radius) => DropdownMenuItem(
            value: radius,
            child: Text('До ${radius.toInt()} км'),
          ),
        ),
      ],
      onChanged: _isApplying ? null : _apply,
    );
  }

  Future<void> _apply(double? radiusKm) async {
    setState(() => _isApplying = true);
    try {
      if (radiusKm != null) {
        final granted = await requestPermissionFromUserAction(
          context: context,
          ref: ref,
          permission: AppPermission.location,
        );
        if (!granted) {
          return;
        }
      }
      await ref.read(catalogProvider.notifier).setRadius(radiusKm);
      if (mounted) {
        setState(() => _radiusKm = radiusKm);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                error,
                fallback: 'Не удалось применить радиус поиска',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
}

class _PriceFilter extends ConsumerStatefulWidget {
  const _PriceFilter();

  @override
  ConsumerState<_PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends ConsumerState<_PriceFilter> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      initiallyExpanded: true,
      title: const Text('Цена за день'),
      children: [
        FormBuilder(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('minPrice', 'От')),
              const SizedBox(width: 8),
              Expanded(child: _field('maxPrice', 'До')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _apply, child: const Text('Применить')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(String name, String label) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(labelText: label, suffixText: '₽'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.numeric(errorText: 'Введите число'),
        FormBuilderValidators.min(0, errorText: 'Не меньше 0'),
      ]),
    );
  }

  void _apply() {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final minPrice = _number(form.value['minPrice']);
    final maxPrice = _number(form.value['maxPrice']);
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цена «От» не должна быть больше «До»')),
      );
      return;
    }
    ref.read(catalogProvider.notifier).setPriceRange(minPrice, maxPrice);
  }

  double? _number(Object? value) {
    final text = value?.toString().trim().replaceFirst(',', '.') ?? '';
    return text.isEmpty ? null : double.parse(text);
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final coverPhoto =
        item.photos.where((photo) => photo.isCover).firstOrNull ??
        item.photos.firstOrNull;
    final coverUrl = coverPhoto?.thumbnailUrl ?? coverPhoto?.previewUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: 'Открыть объявление ${item.title}',
        child: InkWell(
          onTap: () => context.push('/items/${item.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl == null
                        ? const _CatalogPhotoPlaceholder()
                        : Image.network(
                            coverUrl,
                            semanticLabel: 'Фото ${item.title}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: AppColors.warmSand,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 44,
                                  color: AppColors.slate800,
                                ),
                              ),
                            ),
                          ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            _condition(item.condition),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_price(item.pricePerDay)} ₽ / день',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.slate700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [
                              item.category.name,
                              item.area,
                              if (item.distanceBucket != null)
                                item.distanceBucket!,
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  String _condition(String value) => switch (value) {
    'NEW' => 'Новое',
    'LIKE_NEW' => 'Как новое',
    'GOOD' => 'Хорошее состояние',
    'FAIR' => 'Есть следы использования',
    _ => 'Состояние указано',
  };
}

class _CatalogPhotoPlaceholder extends StatelessWidget {
  const _CatalogPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Фото отсутствует',
      child: const ColoredBox(
        color: AppColors.warmSand,
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 52,
            color: AppColors.slate800,
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.slate700,
            ),
            const SizedBox(height: 12),
            Text(
              'Пока нет доступных вещей',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Попробуйте изменить запрос, категорию или радиус поиска.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.slate700,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
