import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  static const items = [
    (Icons.public_rounded, 'Global eSIM catalogue', 'Find and sell regional and global data packages from one mobile workspace.'),
    (Icons.qr_code_2_rounded, 'Instant delivery', 'Create orders, access QR codes and send activation details in seconds.'),
    (Icons.insights_rounded, 'Business control', 'Track wallet balance, orders, activations and usage from anywhere.'),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.go('/login'), child: const Text('Skip')),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: items.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 190,
                          width: 190,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.navy]),
                            borderRadius: BorderRadius.circular(56),
                          ),
                          child: Icon(item.$1, size: 88, color: Colors.white),
                        ),
                        const SizedBox(height: 42),
                        Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),
                        Text(item.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: page == index ? 24 : 8,
                decoration: BoxDecoration(color: page == index ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(99)),
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              child: ElevatedButton(
                onPressed: () {
                  if (page == items.length - 1) {
                    context.go('/login');
                  } else {
                    controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
                  }
                },
                child: Text(page == items.length - 1 ? 'Get Started' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
