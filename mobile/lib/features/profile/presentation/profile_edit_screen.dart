import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../data/profile_models.dart';
import '../data/profile_service.dart';
import '../domain/profile_editor_controller.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  var _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final editor = ref.watch(profileEditorControllerProvider);
    final isSaving = editor.isLoading;
    final error = editor.hasError ? editor.error?.toString() : null;

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(title: const Text('Редактировать профиль')),
        body: SafeArea(
          child: profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Не удалось загрузить профиль')),
            data: (value) => FormBuilder(
              key: _formKey,
              initialValue: {
                'name': value.name ?? '',
                'city': value.city ?? '',
              },
              onChanged: _markDirty,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _Avatar(profile: value),
                        const SizedBox(height: 8),
                        Align(
                          child: TextButton.icon(
                            onPressed: isSaving ? null : _pickAvatar,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Заменить фото'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Основная информация',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        FormBuilderTextField(
                          key: const ValueKey('profile-name-field'),
                          name: 'name',
                          decoration: const InputDecoration(labelText: 'Имя'),
                          textInputAction: TextInputAction.next,
                          validator: FormBuilderValidators.maxLength(80),
                        ),
                        const SizedBox(height: 16),
                        FormBuilderTextField(
                          key: const ValueKey('profile-city-field'),
                          name: 'city',
                          decoration: const InputDecoration(labelText: 'Город'),
                          textInputAction: TextInputAction.done,
                          validator: FormBuilderValidators.maxLength(80),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      onPressed: isSaving ? null : _save,
                      child: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (file == null || !mounted) {
      return;
    }

    await ref
        .read(profileEditorControllerProvider.notifier)
        .replaceAvatar(file);
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }

    final success = await ref
        .read(profileEditorControllerProvider.notifier)
        .updateProfile(
          name: (form.value['name'] as String? ?? '').trim(),
          city: (form.value['city'] as String? ?? '').trim(),
        );
    if (success && mounted) {
      setState(() => _hasUnsavedChanges = false);
      context.pop();
    }
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: CircleAvatar(
        radius: 48,
        backgroundImage: profile.avatarUrl == null
            ? null
            : NetworkImage(profile.avatarUrl!),
        child: profile.avatarUrl == null
            ? const Icon(Icons.person_outline, size: 40)
            : null,
      ),
    );
  }
}
