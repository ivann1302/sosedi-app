import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/auth_intent.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth_controller.dart';
import '../domain/auth_state.dart';
import '../domain/auth_validators.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final errorMessage = authState is AuthUnauthenticated
        ? authState.errorMessage
        : authState.errorMessage;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(publicAuthCancelTarget(widget.returnTo)),
          icon: const Icon(Icons.close),
          tooltip: 'Продолжить без входа',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Рады видеть вас',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Введите номер — пришлём код для входа.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                FormBuilderTextField(
                  name: 'phone',
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
                  ],
                  validator: AuthValidators.validateRussianPhone,
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    hintText: '+7 999 123 45 67',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.slate700,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                if (errorMessage != null)
                  Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      context.go(publicAuthCancelTarget(widget.returnTo)),
                  child: const Text('Продолжить без входа'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Смотреть каталог можно без входа. Телефон понадобится для '
                  'бронирования, публикации и личных разделов.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            key: const ValueKey('auth-primary-action'),
            onPressed: authState.isSubmitting ? null : _submit,
            child: authState.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Получить код', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }

    final phone = form.value['phone'] as String;
    final success = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(phone);

    if (mounted && success) {
      final returnTo = widget.returnTo;
      context.go(
        returnTo == null
            ? '/auth/otp'
            : routeWithReturnTo('/auth/otp', returnTo),
      );
    }
  }
}
