import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_controller.dart';
import '../domain/auth_state.dart';
import '../domain/auth_validators.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),
                Icon(
                  Icons.handyman,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Вход по SMS',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('Укажите российский номер телефона.'),
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
                    prefixIcon: Icon(Icons.phone),
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
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: authState.isSubmitting ? null : _submit,
                  icon: authState.isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sms),
                  label: const Text('Получить код'),
                ),
              ],
            ),
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
    final success = await ref.read(authControllerProvider.notifier).requestOtp(
          phone,
        );

    if (mounted && success) {
      context.go('/auth/otp');
    }
  }
}
