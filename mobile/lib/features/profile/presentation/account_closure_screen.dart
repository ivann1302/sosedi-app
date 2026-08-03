import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/profile_models.dart';
import '../domain/account_closure_controller.dart';

class AccountClosureScreen extends ConsumerStatefulWidget {
  const AccountClosureScreen({super.key});

  @override
  ConsumerState<AccountClosureScreen> createState() =>
      _AccountClosureScreenState();
}

class _AccountClosureScreenState extends ConsumerState<AccountClosureScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountClosureControllerProvider);
    final result = state.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Закрытие аккаунта')),
      body: SafeArea(
        child: result == null
            ? _Confirmation(
                accepted: _accepted,
                loading: state.isLoading,
                error: state.hasError ? state.error.toString() : null,
                onChanged: (value) => setState(() => _accepted = value),
                onSubmit: () => ref
                    .read(accountClosureControllerProvider.notifier)
                    .closeAccount(),
              )
            : _Result(
                result: result,
                onFinish: () => ref
                    .read(authControllerProvider.notifier)
                    .logout(),
              ),
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({
    required this.accepted,
    required this.loading,
    required this.error,
    required this.onChanged,
    required this.onSubmit,
  });

  final bool accepted;
  final bool loading;
  final String? error;
  final ValueChanged<bool> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Что произойдёт',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Text('• Все сессии будут отозваны, профиль и объявления скрыты.'),
        const SizedBox(height: 8),
        const Text(
          '• Активные аренды, споры, платежи или обязательный срок хранения '
          'могут отложить анонимизацию.',
        ),
        const SizedBox(height: 8),
        const Text(
          '• Финансовый и audit след хранится только в обязательном объёме.',
        ),
        const SizedBox(height: 16),
        const Text('После отправки отменить запрос нельзя.'),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: accepted,
          onChanged: loading
              ? null
              : (value) => onChanged(value ?? false),
          title: const Text('Я понимаю последствия'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: accepted && !loading ? onSubmit : null,
          child: const Text('Закрыть аккаунт'),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.result, required this.onFinish});

  final AccountClosureResult result;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final pending = result.status == 'PENDING_OBLIGATIONS';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pending ? 'Запрос принят' : 'Аккаунт закрыт',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            pending
                ? 'Анонимизация завершится после закрытия активных обязательств.'
                : 'Персональные данные анонимизированы.',
          ),
          const Spacer(),
          FilledButton(
            onPressed: onFinish,
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }
}
