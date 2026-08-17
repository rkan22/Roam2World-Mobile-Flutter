import 'dart:ui';

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
      backgroundColor: const Color(0xFF071222),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/onboarding/onboarding_global_travel.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66030B18),
                  Color(0xDD071222),
                  Color(0xFF071222),
                ],
                stops: [0, .46, .82],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          Image.asset(
                            'assets/branding/roam2world_logo_transparent.png',
                            width: 190,
                            fit: BoxFit.contain,
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 92),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: .35),
                          ),
                        ),
                        child: Icon(
                          resetComplete
                              ? Icons.verified_rounded
                              : sent
                              ? Icons.mark_email_read_rounded
                              : Icons.lock_reset_rounded,
                          color: AppColors.primary,
                          size: 29,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        resetComplete
                            ? 'Password updated'
                            : sent
                            ? 'Check your inbox'
                            : 'Recover your account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.05,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        resetComplete
                            ? 'Your workspace is secure. Sign in using your new password.'
                            : sent
                            ? 'Enter the secure code sent to ${emailController.text}.'
                            : 'We will send a secure verification code to your business email.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF081629,
                              ).withValues(alpha: .56),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .16),
                              ),
                              boxShadow: B2BShadows.hero,
                            ),
                            child: _recoveryContent(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 17,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Secure account recovery',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
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
        ],
      ),
    );
  }

  Widget _recoveryContent() {
    if (!sent) {
      return Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use the email linked to your partner account.',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: emailController,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: _fieldDecoration(
                'Email address',
                Icons.mail_outline_rounded,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            if (errorMessage != null) _errorMessage(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ? null : _submit,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.outgoing_mail),
                label: Text(submitting ? 'Sending…' : 'Send secure code'),
              ),
            ),
          ],
        ),
      );
    }

    if (resetComplete) {
      return Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 54,
          ),
          const SizedBox(height: 14),
          const Text(
            'Your password is ready.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Return to sign in'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify and reset',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: otpController,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration(
            'Verification code',
            Icons.password_rounded,
          ),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: passwordController,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: _fieldDecoration(
            'New password',
            Icons.lock_outline_rounded,
          ),
        ),
        if (errorMessage != null) _errorMessage(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: submitting ? null : _confirmReset,
            icon: submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(submitting ? 'Updating…' : 'Update password'),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: submitting
                ? null
                : () => setState(() {
                    sent = false;
                    errorMessage = null;
                  }),
            child: const Text('Use another email'),
          ),
        ),
      ],
    );
  }

  Widget _errorMessage() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      errorMessage!,
      style: const TextStyle(
        color: Color(0xFFFF8A8A),
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: .14)),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .07),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}
