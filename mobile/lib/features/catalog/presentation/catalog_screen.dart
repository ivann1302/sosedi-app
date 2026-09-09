import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/inline_select_field.dart';
import '../../../shared/widgets/item_photo_image.dart';
import '../data/catalog_models.dart';
import '../domain/catalog_controller.dart';
import '../../favorites/presentation/favorite_button.dart';
import '../../map/presentation/catalog_map.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({
    this.yandexTilesApiKey,
    this.mapTileProvider,
    super.key,
  });

  final String? yandexTilesApiKey;
  final TileProvider? mapTileProvider;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  static const _wideMapBreakpoint = 840.0;

  bool _showMap = false;
  String? _selectedMapItemId;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final categories = ref.watch(catalogCategoriesProvider);
    final mapApiKey = resolveProviderApiKey(
      widget.yandexTilesApiKey ?? AppConfig.yandexTilesApiKey ?? '',
    );
    final showWideMap =
        mapApiKey != null &&
        MediaQuery.sizeOf(context).width >= _wideMapBreakpoint;
    final compactMapAction =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final mapActionIcon = Icon(
      _showMap ? Icons.view_list_outlined : Icons.map_outlined,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Найти', maxLines: 1, overflow: TextOverflow.visible),
        actions: [
          if (mapApiKey != null && !showWideMap)
            if (compactMapAction)
              IconButton(
                onPressed: _toggleMap,
                tooltip: _showMap ? 'Показать список' : 'Показать карту',
                icon: mapActionIcon,
              )
            else
              SizedBox(
                width: 128,
                child: TextButton.icon(
                  onPressed: _toggleMap,
                  icon: mapActionIcon,
                  label: Text(_showMap ? 'Список' : 'Карта'),
                ),
              ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SizedBox(
                height: 48,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Что хотите найти?',
                    fillColor: AppColors.cloud,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadii.small),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadii.small),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadii.small),
                      ),
                      borderSide: BorderSide(
                        color: AppColors.brandForeground,
                        width: 2,
                      ),
                    ),
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
            ),
            _QuickFilters(categories: categories),
            const SizedBox(height: 4),
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
                            child: _buildResults(
                              value,
                              mapApiKey: mapApiKey,
                              showWideMap: showWideMap,
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

  void _toggleMap() {
    setState(() => _showMap = !_showMap);
  }

  Widget _buildResults(
    CatalogState value, {
    required String? mapApiKey,
    required bool showWideMap,
  }) {
    final list = _buildList(value);
    if (mapApiKey == null) return list;

    final map = _buildMap(value, mapApiKey);
    if (showWideMap) {
      return Row(
        children: [
          Expanded(
            flex: 5,
            child: KeyedSubtree(
              key: const ValueKey('catalog-wide-list'),
              child: list,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 7,
            child: KeyedSubtree(
              key: const ValueKey('catalog-wide-map'),
              child: map,
            ),
          ),
        ],
      );
    }

    return _showMap ? map : list;
  }

  Widget _buildMap(CatalogState value, String mapApiKey) {
    return CatalogMap(
      key: ValueKey(value.items.map((item) => item.id).join('|')),
      items: value.items,
      selectedItemId: _selectedMapItemId,
      onItemSelected: (itemId) => setState(() => _selectedMapItemId = itemId),
      apiKey: mapApiKey,
      tileProvider: widget.mapTileProvider,
    );
  }

  Widget _buildList(CatalogState value) {
    return RefreshIndicator(
      onRefresh: () => ref.read(catalogProvider.notifier).refreshCatalog(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final columns = constraints.maxWidth < 600 ? 2 : 3;
          final itemWidth =
              (constraints.maxWidth - 24 - 10 * (columns - 1)) / columns;
          return GridView.builder(
            key: const ValueKey('catalog-grid'),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              mainAxisExtent: itemWidth / 1.2 + (textScale > 1.5 ? 240 : 104),
            ),
            itemCount: value.items.length + (value.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == value.items.length) {
                return Center(
                  child: value.isLoadingMore
                      ? const CircularProgressIndicator()
                      : OutlinedButton(
                          onPressed: () =>
                              ref.read(catalogProvider.notifier).loadMore(),
                          child: const Text('Показать ещё'),
                        ),
                );
              }
              return _CatalogCard(item: value.items[index]);
            },
          );
        },
      ),
    );
  }
}

class _QuickFilters extends ConsumerStatefulWidget {
  const _QuickFilters({required this.categories});

  final AsyncValue<List<CatalogCategory>> categories;

  @override
  ConsumerState<_QuickFilters> createState() => _QuickFiltersState();
}

class _QuickFiltersState extends ConsumerState<_QuickFilters> {
  DateTimeRange? _range;
  String? _categoryId;
  String? _area;
  double? _minPrice;
  double? _maxPrice;

  @override
  Widget build(BuildContext context) {
    final category = _selectedCategory(widget.categories.value);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ActionChip(
            avatar: const Icon(Icons.tune, size: 18),
            label: const Text('Фильтры'),
            onPressed: () => _showFilters(context),
          ),
          if (_range case final range?) ...[
            const SizedBox(width: 8),
            InputChip(
              selected: true,
              label: Text(_dateLabel(context, range)),
              onPressed: () => _showFilters(context),
              onDeleted: _clearAvailability,
            ),
          ],
          if (category != null) ...[
            const SizedBox(width: 8),
            InputChip(
              selected: true,
              label: Text(category.name),
              onPressed: () => _showFilters(context),
              onDeleted: () => _selectCategory(null),
            ),
          ],
          if (_area case final area?) ...[
            const SizedBox(width: 8),
            InputChip(
              selected: true,
              label: Text(area),
              onPressed: () => _showFilters(context),
              onDeleted: () => _selectArea(null),
            ),
          ],
          if (_minPrice != null || _maxPrice != null) ...[
            const SizedBox(width: 8),
            InputChip(
              selected: true,
              label: Text(_priceLabel()),
              onPressed: () => _showFilters(context),
              onDeleted: () => _selectPrice(null, null),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) => _FilterSheet(
          categories: ref.watch(catalogCategoriesProvider),
          range: _range,
          categoryId: _categoryId,
          area: _area,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          onAvailabilityChanged: _selectAvailability,
          onCategoryChanged: _selectCategory,
          onAreaChanged: _selectArea,
          onPriceChanged: _selectPrice,
        ),
      ),
    );
  }

  Future<void> _selectAvailability(DateTimeRange? range) async {
    if (_range == range) {
      return;
    }
    setState(() => _range = range);
    await ref
        .read(catalogProvider.notifier)
        .setAvailability(
          range == null ? null : _dateOnly(range.start),
          range == null ? null : _dateOnly(range.end),
        );
  }

  Future<void> _clearAvailability() => _selectAvailability(null);

  Future<void> _selectCategory(String? categoryId) async {
    if (_categoryId == categoryId) {
      return;
    }
    setState(() => _categoryId = categoryId);
    await ref.read(catalogProvider.notifier).selectCategory(categoryId);
  }

  Future<void> _selectArea(String? area) async {
    if (_area == area) {
      return;
    }
    setState(() => _area = area);
    await ref.read(catalogProvider.notifier).setArea(area);
  }

  Future<void> _selectPrice(double? minPrice, double? maxPrice) async {
    if (_minPrice == minPrice && _maxPrice == maxPrice) {
      return;
    }
    setState(() {
      _minPrice = minPrice;
      _maxPrice = maxPrice;
    });
    await ref.read(catalogProvider.notifier).setPriceRange(minPrice, maxPrice);
  }

  CatalogCategory? _selectedCategory(List<CatalogCategory>? categories) {
    for (final category in categories ?? const <CatalogCategory>[]) {
      if (category.id == _categoryId) {
        return category;
      }
    }
    return null;
  }

  String _priceLabel() {
    if (_minPrice != null && _maxPrice != null) {
      return '${_price(_minPrice!)}–${_price(_maxPrice!)} ₽';
    }
    return _minPrice != null
        ? 'От ${_price(_minPrice!)} ₽'
        : 'До ${_price(_maxPrice!)} ₽';
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CatalogCategory> categories;
  final String? selectedId;
  final Future<void> Function(String?) onSelected;

  @override
  Widget build(BuildContext context) {
    return InlineSelectField<String>(
      key: const ValueKey('catalog-category-filter'),
      value: selectedId,
      decoration: const InputDecoration(labelText: 'Категория'),
      items: [
        const DropdownMenuItem(value: null, child: Text('Все категории')),
        ...categories.map(
          (category) =>
              DropdownMenuItem(value: category.id, child: Text(category.name)),
        ),
      ],
      onChanged: (value) => _select(context, value),
    );
  }

  Future<void> _select(BuildContext context, String? categoryId) async {
    if (selectedId == categoryId) {
      return;
    }
    await onSelected(categoryId);
    if (context.mounted) {
      Navigator.pop(context);
    }
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

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.range, required this.onChanged});

  final DateTimeRange? range;
  final Future<void> Function(DateTimeRange?) onChanged;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.date_range_outlined, size: 18),
      label: Text(range == null ? 'Даты' : _dateLabel(context, range!)),
      onPressed: () => _pick(context),
      onDeleted: range == null ? null : () => onChanged(null),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      initialDateRange: range,
      helpText: 'Выберите период аренды',
      saveText: 'Применить',
    );
    if (selectedRange == null || !context.mounted) {
      return;
    }
    await onChanged(selectedRange);
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.categories,
    required this.range,
    required this.categoryId,
    required this.area,
    required this.minPrice,
    required this.maxPrice,
    required this.onAvailabilityChanged,
    required this.onCategoryChanged,
    required this.onAreaChanged,
    required this.onPriceChanged,
  });

  final AsyncValue<List<CatalogCategory>> categories;
  final DateTimeRange? range;
  final String? categoryId;
  final String? area;
  final double? minPrice;
  final double? maxPrice;
  final Future<void> Function(DateTimeRange?) onAvailabilityChanged;
  final Future<void> Function(String?) onCategoryChanged;
  final Future<void> Function(String?) onAreaChanged;
  final Future<void> Function(double?, double?) onPriceChanged;

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
            Text('Даты', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _AvailabilityChip(
                range: range,
                onChanged: onAvailabilityChanged,
              ),
            ),
            const SizedBox(height: 16),
            categories.when(
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const Align(
                alignment: Alignment.centerLeft,
                child: _CategoryErrorChip(),
              ),
              data: (value) => _CategoryFilter(
                categories: value,
                selectedId: categoryId,
                onSelected: onCategoryChanged,
              ),
            ),
            const SizedBox(height: 16),
            _AreaFilter(area: area, onChanged: onAreaChanged),
            const SizedBox(height: 12),
            _PriceFilter(
              minPrice: minPrice,
              maxPrice: maxPrice,
              onChanged: onPriceChanged,
            ),
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
  const _AreaFilter({required this.area, required this.onChanged});

  final String? area;
  final Future<void> Function(String?) onChanged;

  @override
  ConsumerState<_AreaFilter> createState() => _AreaFilterState();
}

class _AreaFilterState extends ConsumerState<_AreaFilter> {
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
      data: (values) => InlineSelectField<String>(
        key: const ValueKey('catalog-area-filter'),
        value: widget.area,
        decoration: const InputDecoration(labelText: 'Район'),
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
    await widget.onChanged(area);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _PriceFilter extends ConsumerStatefulWidget {
  const _PriceFilter({
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  });

  final double? minPrice;
  final double? maxPrice;
  final Future<void> Function(double?, double?) onChanged;

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
              Expanded(
                child: _field('minPrice', 'От', initialValue: widget.minPrice),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field('maxPrice', 'До', initialValue: widget.maxPrice),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
                onPressed: _apply,
                child: const Text('Применить'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(String name, String label, {double? initialValue}) {
    return FormBuilderTextField(
      name: name,
      initialValue: initialValue == null ? null : _price(initialValue),
      decoration: InputDecoration(labelText: label, suffixText: '₽'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.numeric(errorText: 'Введите число'),
        FormBuilderValidators.min(0, errorText: 'Не меньше 0'),
      ]),
    );
  }

  Future<void> _apply() async {
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
    await widget.onChanged(minPrice, maxPrice);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  double? _number(Object? value) {
    final text = value?.toString().trim().replaceFirst(',', '.') ?? '';
    return text.isEmpty ? null : double.parse(text);
  }
}

String _dateLabel(BuildContext context, DateTimeRange range) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatCompactDate(range.start)}–'
      '${localizations.formatCompactDate(range.end)}';
}

String _dateOnly(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _price(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

class _CatalogCard extends ConsumerWidget {
  const _CatalogCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverPhoto =
        item.photos.where((photo) => photo.isCover).firstOrNull ??
        item.photos.firstOrNull;
    final coverUrl = coverPhoto?.thumbnailUrl ?? coverPhoto?.previewUrl;

    return Semantics(
      container: true,
      button: true,
      label: 'Открыть объявление ${item.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        onTap: () => context.push('/items/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl == null
                        ? const ItemPhotoPlaceholder()
                        : ItemPhotoImage(
                            source: coverUrl,
                            semanticLabel: 'Фото ${item.title}',
                            fit: BoxFit.cover,
                          ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: FavoriteButton(item: item),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_price(item.pricePerDay)} ₽ / день',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              [
                item.area,
                if (item.distanceBucket != null) item.distanceBucket,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _price(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
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
