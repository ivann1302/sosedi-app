import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../data/support_models.dart';
import '../data/support_service.dart';
import '../domain/support_create_controller.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({this.initialSubject, this.initialMessage, super.key});

  final String? initialSubject;
  final String? initialMessage;

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportTicketsProvider);
    final create = ref.watch(supportCreateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Поддержка')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Не отправляйте OTP, данные карты или документы. '
                    'Финансовые споры оформляются отдельно из бронирования.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Новое обращение',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: 'subject',
                    initialValue: widget.initialSubject,
                    decoration: const InputDecoration(labelText: 'Тема'),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.minLength(3),
                      FormBuilderValidators.maxLength(120),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  FormBuilderTextField(
                    name: 'message',
                    initialValue: widget.initialMessage,
                    decoration: const InputDecoration(
                      labelText: 'Опишите вопрос',
                    ),
                    minLines: 3,
                    maxLines: 6,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.minLength(10),
                      FormBuilderValidators.maxLength(2000),
                    ]),
                  ),
                ],
              ),
            ),
            if (create.hasError) ...[
              const SizedBox(height: 12),
              Text(
                userFacingError(
                  create.error!,
                  fallback: 'Не удалось отправить обращение',
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Мои обращения',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            tickets.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      userFacingError(
                        error,
                        fallback: 'Не удалось загрузить обращения',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(supportTicketsProvider),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
              data: (values) => values.isEmpty
                  ? const Text('Обращений пока нет')
                  : Column(
                      children: values
                          .map((ticket) => _TicketCard(ticket: ticket))
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            key: const ValueKey('support-primary-action'),
            onPressed: create.isLoading ? null : _submit,
            child: create.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Отправить', textAlign: TextAlign.center),
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
    final success = await ref
        .read(supportCreateProvider.notifier)
        .submit(
          CreateSupportTicketDraft(
            subject: (form.value['subject']! as String).trim(),
            message: (form.value['message']! as String).trim(),
          ),
        );
    if (success && mounted) {
      form.reset();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Обращение отправлено')));
    }
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => context.push('/support/${ticket.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _status(ticket.status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(ticket.message),
                if (ticket.adminResponse != null) ...[
                  const Divider(),
                  Text(
                    'Ответ поддержки',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(ticket.adminResponse!),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _status(String value) => switch (value) {
    'IN_PROGRESS' => 'В работе',
    'CLOSED' => 'Закрыто',
    _ => 'Открыто',
  };
}
