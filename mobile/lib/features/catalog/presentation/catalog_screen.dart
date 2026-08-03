import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../../../core/theme/app_theme.dart';
import '../data/catalog_models.dart';
import '../domain/catalog_controller.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final categories = ref.watch(catalogCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Вещи рядом')),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        userFacingError(
                          error,
                          fallback: 'Категории недоступны',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(catalogCategoriesProvider),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
                data: (value) => DropdownButtonFormField<String>(
                  initialValue: '',
                  decoration: const InputDecoration(labelText: 'Категория'),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Все категории'),
                    ),
                    ...value.map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(catalogProvider.notifier).selectCategory(value),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _PriceFilter(),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _RadiusFilter(),
            ),
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
                            child: RefreshIndicator(
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
                                                    catalogProvider.notifier,
                                                  )
                                                  .loadMore(),
                                              child: const Text('Показать ещё'),
                                            ),
                                    );
                                  }
                                  return _CatalogCard(item: value.items[index]);
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
    final coverUrl = item.photos
        .where((photo) => photo.isCover)
        .map((photo) => photo.thumbnailUrl ?? photo.previewUrl)
        .whereType<String>()
        .firstOrNull;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: 'Открыть объявление ${item.title}',
        child: InkWell(
          onTap: () => context.push('/items/${item.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 144,
                child: coverUrl == null
                    ? Semantics(
                        image: true,
                        label: 'Фото отсутствует',
                        child: ColoredBox(
                          color: AppColors.warmSand,
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 36,
                            color: AppColors.slate800,
                          ),
                        ),
                      )
                    : Image.network(
                        coverUrl,
                        semanticLabel: 'Фото ${item.title}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: AppColors.warmSand,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.slate800,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_price(item.pricePerDay)} ₽ / день',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          item.category.name,
                          item.area,
                          if (item.distanceBucket != null) item.distanceBucket!,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
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
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Пока нет доступных вещей', textAlign: TextAlign.center),
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
            Text(message),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
