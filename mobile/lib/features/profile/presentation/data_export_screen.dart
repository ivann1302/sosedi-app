import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../data/profile_models.dart';
import '../domain/data_export_controller.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  var _codeRequested = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataExportControllerProvider);
    final export = state.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Экспорт данных')),
      body: SafeArea(
        child: export == null
            ? _RequestForm(
                formKey: _formKey,
                codeRequested: _codeRequested,
                loading: state.isLoading,
                error: state.hasError ? state.error.toString() : null,
                onRequestCode: _requestCode,
                onSubmit: _submit,
              )
            : _ExportResult(export: export),
      ),
    );
  }

  Future<void> _requestCode() async {
    final success = await ref
        .read(dataExportControllerProvider.notifier)
        .requestOtp();
    if (mounted && success) {
      setState(() => _codeRequested = true);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    await ref
        .read(dataExportControllerProvider.notifier)
        .create(form.value['code']! as String);
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.formKey,
    required this.codeRequested,
    required this.loading,
    required this.error,
    required this.onRequestCode,
    required this.onSubmit,
  });

  final GlobalKey<FormBuilderState> formKey;
  final bool codeRequested;
  final bool loading;
  final String? error;
  final VoidCallback onRequestCode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Получите копию своих данных',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Для защиты аккаунта мы отправим новый SMS-код. Экспорт содержит '
            'персональные данные — не пересылайте его посторонним.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: loading ? null : onRequestCode,
            icon: const Icon(Icons.sms_outlined),
            label: Text(
              codeRequested ? 'Отправить код ещё раз' : 'Получить код',
            ),
          ),
          if (codeRequested) ...[
            const SizedBox(height: 20),
            FormBuilderTextField(
              key: const ValueKey('data-export-code-field'),
              name: 'code',
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Введите код из SMS'),
                FormBuilderValidators.match(
                  RegExp(r'^\d{6}$'),
                  errorText: 'Код должен состоять из 6 цифр',
                ),
              ]),
              decoration: const InputDecoration(labelText: 'Код из SMS'),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loading ? null : onSubmit,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Подготовить экспорт'),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Если SMS недоступно, обратитесь в поддержку — там проверят '
            'владельца аккаунта без запроса лишних документов.',
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: loading ? null : () => context.push('/support/export'),
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('Обратиться в поддержку'),
          ),
        ],
      ),
    );
  }
}

class _ExportResult extends StatelessWidget {
  const _ExportResult({required this.export});

  final UserDataExport export;

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ').convert(export.toJson());
    final records = [
      ...export.listings,
      ...export.bookings,
      ...export.inbox,
      ...export.support,
      ...export.reports,
      ...export.blocks,
    ].length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Экспорт готов', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Схема ${export.schemaVersion} · записей $records'),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Конфиденциальные данные'),
            subtitle: Text(
              'JSON показан только на этом экране и не сохраняется приложением.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        SelectableText(
          json,
          key: const ValueKey('data-export-json'),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
