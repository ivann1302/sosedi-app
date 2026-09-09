import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../shared/widgets/inline_select_field.dart';

class SafetyReportSubmission {
  const SafetyReportSubmission({
    required this.reason,
    required this.description,
  });

  final String reason;
  final String description;
}

Future<SafetyReportSubmission?> showSafetyReportDialog({
  required BuildContext context,
  required String targetType,
}) {
  final formKey = GlobalKey<FormBuilderState>();
  final reasons = _reasons(targetType);
  return showDialog<SafetyReportSubmission>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      title: const Text('Отправить жалобу'),
      scrollable: true,
      content: FormBuilder(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormBuilderInlineSelect<String>(
              name: 'reason',
              initialValue: reasons.first.code,
              decoration: const InputDecoration(labelText: 'Причина'),
              items: [
                for (final reason in reasons)
                  DropdownMenuItem(
                    value: reason.code,
                    child: Text(reason.label),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'description',
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Что произошло',
                hintText: 'Опишите факты без телефона и платёжных данных',
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(20),
                FormBuilderValidators.maxLength(1000),
              ]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final form = formKey.currentState;
            if (form == null || !form.saveAndValidate()) {
              return;
            }
            Navigator.pop(
              context,
              SafetyReportSubmission(
                reason: form.value['reason']! as String,
                description: (form.value['description']! as String).trim(),
              ),
            );
          },
          child: const Text('Отправить'),
        ),
      ],
    ),
  );
}

List<({String code, String label})> _reasons(String targetType) {
  return switch (targetType) {
    'ITEM' => const [
      (code: 'PROHIBITED_CATEGORY', label: 'Запрещённая категория'),
      (code: 'MISLEADING_LISTING', label: 'Недостоверное описание'),
      (code: 'UNSAFE_ITEM', label: 'Небезопасная вещь'),
      (code: 'SUSPECTED_FRAUD', label: 'Подозрение на мошенничество'),
      (code: 'OTHER', label: 'Другое'),
    ],
    'BOOKING' => const [
      (code: 'NO_SHOW', label: 'Участник не пришёл'),
      (code: 'UNSAFE_HANDOVER', label: 'Небезопасная передача'),
      (code: 'ITEM_NOT_AS_DESCRIBED', label: 'Вещь не соответствует описанию'),
      (code: 'HARASSMENT', label: 'Преследование или угрозы'),
      (code: 'OTHER', label: 'Другое'),
    ],
    'MESSAGE' => const [
      (code: 'HARASSMENT', label: 'Преследование или угрозы'),
      (code: 'PRIVACY_VIOLATION', label: 'Нарушение приватности'),
      (code: 'SUSPECTED_FRAUD', label: 'Подозрение на мошенничество'),
      (code: 'OTHER', label: 'Другое'),
    ],
    'REVIEW' => const [
      (code: 'HARASSMENT', label: 'Оскорбление или преследование'),
      (code: 'PRIVACY_VIOLATION', label: 'Нарушение приватности'),
      (code: 'SUSPECTED_FRAUD', label: 'Подозрение на поддельный отзыв'),
      (code: 'OTHER', label: 'Другое'),
    ],
    _ => const [
      (code: 'SUSPECTED_FRAUD', label: 'Подозрение на мошенничество'),
      (code: 'HARASSMENT', label: 'Преследование или угрозы'),
      (code: 'IMPERSONATION', label: 'Выдаёт себя за другого'),
      (code: 'PRIVACY_VIOLATION', label: 'Нарушение приватности'),
      (code: 'OTHER', label: 'Другое'),
    ],
  };
}
