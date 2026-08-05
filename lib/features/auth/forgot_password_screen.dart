import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool sent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              height: 72,
              width: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 26),
            Text(sent ? 'Check your inbox' : 'Reset your password', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              sent ? 'We sent password reset instructions to ${emailController.text}.' : 'Enter the email address connected to your Roam2World account.',
              style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            if (!sent)
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) setState(() => sent = true);
                      },
                      child: const Text('Send Reset Link'),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(22)),
                child: const Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.success), SizedBox(width: 12), Expanded(child: Text('Reset email sent successfully.', style: TextStyle(fontWeight: FontWeight.w800)))]),
              ),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Back to Sign In')),
              TextButton(onPressed: () => setState(() => sent = false), child: const Text('Try another email')),
            ],
          ],
        ),
      ),
    );
  }
}
