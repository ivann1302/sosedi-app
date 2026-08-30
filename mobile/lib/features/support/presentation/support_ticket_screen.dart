import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/permissions/permission_prompt.dart';
import '../data/support_models.dart';
import '../data/support_service.dart';
import '../domain/support_message_create_controller.dart';

final supportPhotoPickerProvider = Provider<SupportPhotoPicker>((ref) {
  return SupportPhotoPicker(ImagePicker());
});

class SupportPhotoPicker {
  const SupportPhotoPicker(this._picker);

  final ImagePicker _picker;

  Future<List<XFile>> pick({required int limit}) {
    return _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
      limit: limit,
    );
  }
}

class SupportTicketScreen extends ConsumerStatefulWidget {
  const SupportTicketScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<SupportTicketScreen> createState() =>
      _SupportTicketScreenState();
}

class _SupportTicketScreenState extends ConsumerState<SupportTicketScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<XFile> _attachments = const [];

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(supportTicketProvider(widget.ticketId));
    return Scaffold(
      appBar: AppBar(title: const Text('Обращение')),
      body: SafeArea(
        child: ticket.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить обращение',
            ),
            onRetry: () =>
                ref.invalidate(supportTicketProvider(widget.ticketId)),
          ),
          data: _buildTicket,
        ),
      ),
    );
  }

  Widget _buildTicket(SupportTicket ticket) {
    final messages = ref.watch(supportMessagesProvider(widget.ticketId));
    final sending = ref.watch(supportMessageCreateProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(ticket.subject, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(_status(ticket.status)),
        const SizedBox(height: 16),
        _MessageCard(label: 'Вы', body: ticket.message),
        messages.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _LoadError(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить переписку',
            ),
            onRetry: () =>
                ref.invalidate(supportMessagesProvider(widget.ticketId)),
          ),
          data: (values) {
            final hasCanonicalAdminResponse =
                ticket.adminResponse != null &&
                values.any(
                  (message) =>
                      message.authorRole == 'SUPPORT' &&
                      message.body == ticket.adminResponse,
                );
            return Column(
              children: [
                if (ticket.adminResponse != null && !hasCanonicalAdminResponse)
                  _MessageCard(label: 'Поддержка', body: ticket.adminResponse!),
                ...values.map(
                  (message) => _MessageCard(
                    label: message.authorRole == 'SUPPORT' ? 'Поддержка' : 'Вы',
                    body: message.body,
                    attachments: message.attachments,
                    onOpenAttachment: (attachment) =>
                        _openAttachment(attachment.id),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (ticket.status == 'CLOSED')
          const Text('Обращение закрыто. Создайте новое, если вопрос остался.')
        else ...[
          FormBuilder(
            key: _formKey,
            child: FormBuilderTextField(
              name: 'body',
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Сообщение'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(2),
                FormBuilderValidators.maxLength(2000),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: sending.isLoading || _attachments.length >= 3
                ? null
                : _pickAttachments,
            icon: const Icon(Icons.attach_file),
            label: Text(
              _attachments.isEmpty
                  ? 'Добавить фото'
                  : 'Добавить ещё (${_attachments.length}/3)',
            ),
          ),
          if (_attachments.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _attachments
                  .map(
                    (attachment) => InputChip(
                      label: Text(attachment.name),
                      onDeleted: sending.isLoading
                          ? null
                          : () => setState(
                              () => _attachments = _attachments
                                  .where((candidate) => candidate != attachment)
                                  .toList(growable: false),
                            ),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (sending.hasError) ...[
            const SizedBox(height: 8),
            Text(
              userFacingError(
                sending.error!,
                fallback: 'Не удалось отправить сообщение',
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: sending.isLoading ? null : _send,
            child: sending.isLoading
                ? const CircularProgressIndicator()
                : const Text('Отправить'),
          ),
        ],
      ],
    );
  }

  Future<void> _send() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final success = await ref
        .read(supportMessageCreateProvider.notifier)
        .submit(
          ticketId: widget.ticketId,
          body: (form.value['body']! as String).trim(),
          attachments: _attachments,
        );
    if (success && mounted) {
      form.reset();
      setState(() => _attachments = const []);
    }
  }

  Future<void> _pickAttachments() async {
    final allowed = await requestPermissionFromUserAction(
      context: context,
      ref: ref,
      permission: AppPermission.photos,
    );
    if (!allowed || !mounted) {
      return;
    }
    final selected = await ref
        .read(supportPhotoPickerProvider)
        .pick(limit: 3 - _attachments.length);
    if (!mounted || selected.isEmpty) {
      return;
    }
    setState(() {
      _attachments = [
        ..._attachments,
        ...selected,
      ].take(3).toList(growable: false);
    });
  }

  Future<void> _openAttachment(String attachmentId) async {
    try {
      final uri = await ref
          .read(supportServiceProvider)
          .getAttachmentDownloadUri(widget.ticketId, attachmentId);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw const ApiException(
          code: 'ATTACHMENT_OPEN_FAILED',
          message: 'Не удалось открыть вложение',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingError(error, fallback: 'Не удалось открыть вложение'),
          ),
        ),
      );
    }
  }

  String _status(String value) => switch (value) {
    'IN_PROGRESS' => 'В работе',
    'CLOSED' => 'Закрыто',
    _ => 'Открыто',
  };
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.label,
    required this.body,
    this.attachments = const [],
    this.onOpenAttachment,
  });

  final String label;
  final String body;
  final List<SupportAttachment> attachments;
  final ValueChanged<SupportAttachment>? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final isUser = label == 'Вы';
    return Column(
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    textAlign: isUser ? TextAlign.right : TextAlign.left,
                  ),
                  if (attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (var index = 0; index < attachments.length; index += 1)
                      TextButton.icon(
                        onPressed: onOpenAttachment == null
                            ? null
                            : () => onOpenAttachment!(attachments[index]),
                        icon: const Icon(Icons.image_outlined),
                        label: Text('Открыть вложение ${index + 1}'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
