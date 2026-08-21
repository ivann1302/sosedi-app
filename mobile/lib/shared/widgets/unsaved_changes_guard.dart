import 'dart:async';

import 'package:flutter/material.dart';

class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard({
    required this.hasUnsavedChanges,
    required this.child,
    this.onDiscard,
    super.key,
  });

  final bool hasUnsavedChanges;
  final Widget child;
  final FutureOr<void> Function()? onDiscard;

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  var _discardApproved = false;
  var _dialogOpen = false;

  @override
  void didUpdateWidget(UnsavedChangesGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hasUnsavedChanges) {
      _discardApproved = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !widget.hasUnsavedChanges || _discardApproved,
      onPopInvokedWithResult: _onPopInvoked,
      child: widget.child,
    );
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop || _dialogOpen) {
      return;
    }

    _dialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Отменить изменения?'),
        content: const Text('Введённые данные не сохранятся.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Продолжить редактирование'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Отменить изменения'),
          ),
        ],
      ),
    );
    _dialogOpen = false;

    if (discard != true || !mounted) {
      return;
    }

    await widget.onDiscard?.call();
    if (!mounted) {
      return;
    }
    setState(() => _discardApproved = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).maybePop(result);
      }
    });
  }
}
