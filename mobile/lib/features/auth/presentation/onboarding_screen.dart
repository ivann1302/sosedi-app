import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sosedi_logo.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({this.returnTo, super.key});

  final String? returnTo;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.inventory_2_outlined,
      title: 'Всё нужное уже рядом',
      text:
          'Берите вещи у соседей, когда покупать их ради одного раза не хочется.',
    ),
    _OnboardingSlide(
      icon: Icons.shield_outlined,
      title: 'Надежные сделки',
      text: 'Профили, модерация и понятные правила для обеих сторон аренды.',
    ),
    _OnboardingSlide(
      icon: Icons.search_rounded,
      title: 'Быстрый поиск',
      text: 'Карта и каталог помогут найти подходящую вещь поблизости.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SosediLogo(markSize: 28),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Пропустить'),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 72, color: AppColors.slate800),
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.text,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_page + 1} из ${_slides.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (_page + 1) / _slides.length,
                        minHeight: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _continue(isLastPage),
                child: Text(isLastPage ? 'Смотреть вещи' : 'Далее'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue(bool isLastPage) async {
    if (!isLastPage) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }

    await _finish();
  }

  Future<void> _finish() async {
    await ref.read(onboardingCompletedProvider.notifier).markCompleted();
    if (mounted) {
      context.go(widget.returnTo ?? '/catalog');
    }
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;
}
