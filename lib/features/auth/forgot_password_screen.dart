import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final repository = AuthRepository();
  bool sent = false;
  bool submitting = false;
  bool resetComplete = false;
  String? errorMessage;

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false) || submitting) return;
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      await repository.requestPasswordReset(emailController.text);
      if (!mounted) return;
      setState(() => sent = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _confirmReset() async {
    if (submitting) return;
    final otp = otpController.text.trim();
    final password = passwordController.text;
    if (otp.isEmpty || password.length < 8) {
      setState(() {
        errorMessage =
            'Enter the email code and a password of at least 8 characters.';
      });
      return;
    }
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      await repository.verifyPasswordResetOtp(
        email: emailController.text,
        otp: otp,
      );
      await repository.confirmPasswordReset(
        email: emailController.text,
        otp: otp,
        newPassword: password,
      );
      if (!mounted) return;
      setState(() => resetComplete = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      gradient: B2BGradients.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: B2BShadows.card,
                    ),
                    child: Icon(
                      sent
                          ? Icons.mark_email_read_rounded
                          : Icons.lock_reset_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    resetComplete
                        ? 'Password updated'
                        : sent
                        ? 'Check your inbox'
                        : 'Reset your password',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    resetComplete
                        ? 'You can now sign in with your new password.'
                        : sent
                        ? 'We sent a password reset code to ${emailController.text}.'
                        : 'Enter the email address connected to your Roam2World account.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(B2BRadius.xl),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: B2BShadows.card,
                    ),
                    child: !sent
                        ? Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recovery email',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  validator: (value) {
                                    final email = value?.trim() ?? '';
                                    if (email.isEmpty || !email.contains('@')) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                if (errorMessage != null) ...[
                                  Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                FilledButton(
                                  onPressed: submitting ? null : _submit,
                                  child: Text(
                                    submitting ? 'Sending…' : 'Send reset code',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : resetComplete
                        ? Column(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 48,
                              ),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('Back to sign in'),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  borderRadius: BorderRadius.circular(
                                    B2BRadius.md,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Reset code sent successfully.',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: otpController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reset code',
                                  prefixIcon: Icon(Icons.password_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'New password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: submitting ? null : _confirmReset,
                                child: Text(
                                  submitting ? 'Updating…' : 'Update password',
                                ),
                              ),
                              TextButton(
                                onPressed: submitting
                                    ? null
                                    : () => setState(() {
                                        sent = false;
                                        errorMessage = null;
                                      }),
                                child: const Text('Try another email'),
                              ),
                            ],
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
}
