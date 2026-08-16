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
  final controller = PageController();
  final storage = TokenStorage();
  int page = 0;

  static const items = [
    (
      Icons.public_rounded,
      'Sell connectivity anywhere',
      'Browse global and regional eSIM plans from one premium business workspace.',
      Color(0xFF6D5CE7),
    ),
    (
      Icons.qr_code_2_rounded,
      'Deliver eSIMs instantly',
      'Create orders, access QR codes and share activation details in seconds.',
      Color(0xFF0EA5E9),
    ),
    (
      Icons.insights_rounded,
      'Run your business smarter',
      'Track wallet balance, orders, activations and performance wherever you work.',
      Color(0xFF14B8A6),
    ),
  ];

  Future<void> _completeOnboarding() async {
    await storage.markOnboardingCompleted();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: B2BGradients.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: B2BShadows.card,
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text('Roam2World', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: items.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 520;
                      final artworkHeight = compact
                          ? (constraints.maxHeight * .48).clamp(170.0, 220.0)
                          : (constraints.maxHeight * .58).clamp(240.0, 380.0);

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          compact ? 10 : 18,
                          24,
                          10,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 20,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  maxWidth: 430,
                                ),
                                height: artworkHeight,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(
                                    B2BRadius.xxl,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                  boxShadow: B2BShadows.elevated,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        item.$4.withValues(alpha: .95),
                                        AppColors.heroEnd,
                                      ],
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: -34,
                                        top: -28,
                                        child: Container(
                                          width: compact ? 120 : 160,
                                          height: compact ? 120 : 160,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: .10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: -28,
                                        bottom: -40,
                                        child: Container(
                                          width: compact ? 140 : 190,
                                          height: compact ? 140 : 190,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: .08,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Container(
                                          width: compact ? 84 : 112,
                                          height: compact ? 84 : 112,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: .15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              compact ? 26 : 34,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: .20,
                                              ),
                                            ),
                                          ),
                                          child: Icon(
                                            item.$1,
                                            size: compact ? 42 : 54,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 18 : 34),
                              Text(
                                item.$2,
                                textAlign: TextAlign.center,
                                style: compact
                                    ? theme.textTheme.headlineMedium
                                    : theme.textTheme.headlineLarge,
                              ),
                              SizedBox(height: compact ? 8 : 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                ),
                                child: Text(
                                  item.$3,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) => AnimatedContainer(
                    duration: B2BMotion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 7,
                    width: page == index ? 28 : 7,
                    decoration: BoxDecoration(
                      color: page == index
                          ? AppColors.primary
                          : AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: FilledButton.icon(
                onPressed: () {
                  if (page == items.length - 1) {
                    _completeOnboarding();
                  } else {
                    controller.nextPage(
                      duration: B2BMotion.standard,
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                icon: Icon(
                  page == items.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.chevron_right_rounded,
                ),
                label: Text(
                  page == items.length - 1 ? 'Get started' : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
