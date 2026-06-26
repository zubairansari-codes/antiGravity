/// Onboarding screen — 3-page intro carousel for first-time users.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/home/presentation/providers/settings_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.record_voice_over_rounded,
      title: 'Speak your ideas naturally',
      description:
          'Just tap the mic and talk through your ideas, problems, or dreams. No typing required.',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      icon: Icons.psychology_rounded,
      title: 'AI organizes your thoughts',
      description:
          'Our AI agent listens, challenges assumptions, and helps you explore angles you might have missed.',
      color: AppColors.accent,
    ),
    _OnboardingPage(
      icon: Icons.checklist_rounded,
      title: 'Get actionable plans',
      description:
          'Walk away with a refined idea, a ready-to-use prompt, and a 3-step action plan you can execute today.',
      color: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _finish() {
    ref.read(onboardingCompleteProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index],
              ),
            ),

            // Progress dots + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finish();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'Next'
                            : 'Get Started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative illustration
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: color,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
