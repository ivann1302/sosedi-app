import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/auth_intent.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sosedi_logo.dart';
import '../domain/auth_controller.dart';
import '../domain/auth_state.dart';
import '../domain/auth_validators.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (authState is! AuthCodeSent) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            final returnTo = widget.returnTo;
            context.go(
              returnTo == null
                  ? '/auth/phone'
                  : routeWithReturnTo('/auth/phone', returnTo),
            );
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Назад',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SosediLogo(markSize: 28),
                const SizedBox(height: 48),
                Text(
                  'Введите код',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'SMS отправлено на ${authState.phone}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                FormBuilderTextField(
                  name: 'code',
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: AuthValidators.validateOtp,
                  decoration: const InputDecoration(
                    labelText: 'Код из SMS',
                    prefixIcon: Icon(
                      Icons.sms_outlined,
                      color: AppColors.slate700,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                if (authState.errorMessage != null)
                  Text(
                    authState.errorMessage!,
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
                      : const Icon(Icons.check),
                  label: const Text('Продолжить'),
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

    final code = form.value['code'] as String;
    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(code);

    if (mounted && success) {
      context.go(widget.returnTo ?? '/catalog');
    }
  }
}
