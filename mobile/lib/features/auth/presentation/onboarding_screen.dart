import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sosedi_logo.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

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
      usesBrandMark: true,
    ),
    _OnboardingSlide(
      icon: Icons.verified_user,
      title: 'Надежные сделки',
      text: 'Профили, модерация и понятные правила для обеих сторон аренды.',
    ),
    _OnboardingSlide(
      icon: Icons.map,
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SosediLogo(markSize: 28),
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
                        Container(
                          width: 152,
                          height: 152,
                          decoration: BoxDecoration(
                            color: AppColors.warmSand,
                            borderRadius: BorderRadius.circular(AppRadii.large),
                          ),
                          alignment: Alignment.center,
                          child: slide.usesBrandMark
                              ? const SosediLogo(
                                  markSize: 82,
                                  showWordmark: false,
                                )
                              : Icon(
                                  slide.icon,
                                  size: 64,
                                  color: AppColors.slate800,
                                ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < _slides.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _page ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _page
                            ? AppColors.brand500
                            : AppColors.line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _continue(isLastPage),
                icon: Icon(
                  isLastPage ? Icons.phone_android : Icons.arrow_forward,
                ),
                label: Text(isLastPage ? 'Войти по SMS' : 'Далее'),
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

    await ref.read(onboardingCompletedProvider.notifier).markCompleted();

    if (mounted) {
      context.go('/auth/phone');
    }
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.text,
    this.usesBrandMark = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool usesBrandMark;
}
