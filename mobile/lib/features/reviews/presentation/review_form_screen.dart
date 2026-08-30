import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../booking/data/booking_service.dart';
import '../data/review_service.dart';
import '../domain/review_submit_controller.dart';

class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingDetailsProvider(widget.bookingId));
    final reviews = ref.watch(bookingReviewsProvider(widget.bookingId));
    final submit = ref.watch(reviewSubmitProvider);
    final existing = reviews.value?.where((review) => review.author == 'SELF');
    final ownReview = existing?.isNotEmpty == true ? existing!.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Отзыв об аренде')),
      body: SafeArea(
        child: booking.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Error(
            message: userFacingError(
              error,
              fallback: 'Не удалось загрузить аренду',
            ),
            onRetry: () =>
                ref.invalidate(bookingDetailsProvider(widget.bookingId)),
          ),
          data: (value) {
            if (value.status != 'COMPLETED') {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Оценить можно только полностью завершённую аренду.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (reviews.isLoading && ownReview == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (reviews.hasError) {
              return _Error(
                message: userFacingError(
                  reviews.error!,
                  fallback: 'Не удалось проверить отзыв',
                ),
                onRetry: () =>
                    ref.invalidate(bookingReviewsProvider(widget.bookingId)),
              );
            }
            if (ownReview != null) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Icon(Icons.check_circle_outline, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    ownReview.hidden
                        ? 'Отзыв скрыт после проверки'
                        : ownReview.published
                        ? 'Отзыв опубликован'
                        : 'Отзыв сохранён',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var index = 0; index < ownReview.rating; index++)
                        const Icon(Icons.star_rounded, size: 30),
                    ],
                  ),
                  if (ownReview.text != null) ...[
                    const SizedBox(height: 12),
                    Text(ownReview.text!),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    ownReview.hidden
                        ? 'Оценка больше не участвует в публичном рейтинге. '
                              'Решение можно обжаловать через поддержку.'
                        : ownReview.published
                        ? 'Оценка неизменяема и подтверждена завершённой арендой.'
                        : 'Она станет видна после отзыва второй стороны или по истечении 14 дней.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Как прошла аренда?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Отзыв нельзя изменить. Он станет публичным после ответа второй стороны или через 14 дней.',
                ),
                const SizedBox(height: 20),
                FormBuilder(
                  key: _formKey,
                  child: Column(
                    children: [
                      FormBuilderDropdown<int>(
                        name: 'rating',
                        initialValue: 5,
                        decoration: const InputDecoration(labelText: 'Оценка'),
                        items: [
                          for (var rating = 5; rating >= 1; rating -= 1)
                            DropdownMenuItem(
                              value: rating,
                              child: Row(
                                children: [
                                  Text('$rating из 5'),
                                  const SizedBox(width: 10),
                                  for (var index = 0; index < rating; index++)
                                    const Icon(Icons.star_rounded, size: 16),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'text',
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Комментарий — необязательно',
                          hintText: 'Что особенно понравилось или было важно?',
                        ),
                        validator: (value) {
                          final length = value?.trim().length ?? 0;
                          if (length > 0 && length < 10) {
                            return 'Напишите не менее 10 символов или оставьте поле пустым';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                if (submit.hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    userFacingError(
                      submit.error!,
                      fallback: 'Не удалось отправить отзыв',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: submit.isLoading ? null : _submit,
                  icon: const Icon(Icons.star_outline),
                  label: Text(
                    submit.isLoading ? 'Сохраняем…' : 'Отправить отзыв',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final sent = await ref
        .read(reviewSubmitProvider.notifier)
        .submit(
          bookingId: widget.bookingId,
          rating: form.value['rating']! as int,
          text: form.value['text'] as String?,
        );
    if (sent && mounted) {
      ref.invalidate(bookingReviewsProvider(widget.bookingId));
    }
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
