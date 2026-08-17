import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _storage = TokenStorage();
  int _page = 0;

  static const _items = [
    (
      'assets/onboarding/onboarding_global_travel.png',
      'Global connectivity, ready when you are',
      'Deliver trusted mobile connectivity to business travelers in destinations worldwide.',
      'GLOBAL COVERAGE',
      Icons.public_rounded,
    ),
    (
      'assets/onboarding/onboarding_esim_activation.png',
      'Activate eSIMs in seconds',
      'Create orders, access QR codes and share activation details from one secure workspace.',
      'INSTANT DELIVERY',
      Icons.bolt_rounded,
    ),
    (
      'assets/onboarding/onboarding_b2b_operations.png',
      'Run every operation with confidence',
      'Track orders, wallet activity, customers and team performance wherever business takes you.',
      'B2B OPERATIONS',
      Icons.insights_rounded,
    ),
  ];

  Future<void> _complete() async {
    await _storage.markOnboardingCompleted();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071222),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) =>
                _OnboardingPage(item: _items[index]),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/branding/roam2world_logo_transparent.png',
                    width: 190,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _complete,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  ...List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: B2BMotion.fast,
                      height: 7,
                      width: _page == index ? 28 : 7,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        color: _page == index
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: .32),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      if (_page == _items.length - 1) {
                        _complete();
                      } else {
                        _controller.nextPage(
                          duration: B2BMotion.standard,
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    icon: Icon(
                      _page == _items.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _page == _items.length - 1 ? 'Get started' : 'Continue',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final (String, String, String, String, IconData) item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(item.$1, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66030B18), Color(0x16030B18), Color(0xFF071222)],
              stops: [0, .48, .82],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 116),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: .55),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.$5, color: AppColors.primary, size: 16),
                          const SizedBox(width: 7),
                          Text(
                            item.$4,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: .8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.$2,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        height: 1.08,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.$3,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: .78),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
