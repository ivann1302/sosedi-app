import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../core/theme/app_theme.dart';

class InlineSelectField<T> extends StatefulWidget {
  const InlineSelectField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.decoration,
    this.enabled = true,
    this.maxOptionsHeight = 240,
    super.key,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final bool enabled;
  final double maxOptionsHeight;

  @override
  State<InlineSelectField<T>> createState() => _InlineSelectFieldState<T>();
}

class _InlineSelectFieldState<T> extends State<InlineSelectField<T>> {
  final _optionsKey = GlobalKey();
  var _expanded = false;

  @override
  void didUpdateWidget(covariant InlineSelectField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!widget.enabled || widget.onChanged == null || widget.items.isEmpty) &&
        _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onChanged != null;
    final selectedItem = _selectedItem();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          expanded: _expanded,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.small),
            onTap: enabled && widget.items.isNotEmpty ? _toggle : null,
            child: IgnorePointer(
              child: InputDecorator(
                isEmpty: selectedItem == null,
                isFocused: _expanded,
                decoration: widget.decoration.copyWith(
                  enabled: enabled,
                  suffixIcon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ),
                child:
                    selectedItem?.child ??
                    Text(
                      widget.decoration.hintText ?? 'Выберите вариант',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
              ),
            ),
          ),
        ),
        if (_expanded)
          ConstrainedBox(
            key: _optionsKey,
            constraints: BoxConstraints(maxHeight: widget.maxOptionsHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cloud,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final selected = item.value == widget.value;
                  return InkWell(
                    onTap: item.enabled ? () => _select(item.value) : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: item.child),
                            if (selected)
                              const Icon(
                                Icons.check_rounded,
                                color: AppColors.brandForeground,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  DropdownMenuItem<T>? _selectedItem() {
    for (final item in widget.items) {
      if (item.value == widget.value) {
        return item;
      }
    }
    return null;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _optionsKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(context, alignment: 0.5);
        }
      });
    }
  }

  void _select(T? value) {
    widget.onChanged?.call(value);
    setState(() => _expanded = false);
  }
}

class FormBuilderInlineSelect<T> extends StatelessWidget {
  const FormBuilderInlineSelect({
    required this.name,
    required this.items,
    required this.decoration,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String name;
  final List<DropdownMenuItem<T>> items;
  final InputDecoration decoration;
  final T? initialValue;
  final FormFieldValidator<T>? validator;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<T>(
      name: name,
      initialValue: initialValue,
      validator: validator,
      enabled: enabled,
      onChanged: onChanged,
      builder: (field) => InlineSelectField<T>(
        value: field.value,
        items: items,
        enabled: enabled,
        onChanged: field.didChange,
        decoration: decoration.copyWith(errorText: field.errorText),
      ),
    );
  }
}
