import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import 'auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthRepository _authRepository;
  bool _rememberMe = true;
  bool _hidePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) context.go(AppRoutes.dashboard);
    } on ApiException catch (error) {
      _showError(error.message);
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                  Color(0x55030B18),
                  Color(0xCC071222),
                  Color(0xFF071222),
                ],
                stops: [0, .34, .62],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/branding/roam2world_logo_transparent.png',
                          width: 250,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 132),
                      const Text(
                        'Business without borders.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          height: 1.04,
                          letterSpacing: -1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect customers, deliver eSIMs and grow your operation from anywhere.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: .76),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: .14,
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Text(
                                      'SECURE B2B ACCESS',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10.5,
                                        letterSpacing: .8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Access your workspace',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Enter your partner credentials to continue.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white60,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    enabled: !_isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: _fieldDecoration(
                                      'Email address',
                                      Icons.mail_outline_rounded,
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'Enter your email address';
                                      }
                                      if (!text.contains('@')) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    enabled: !_isLoading,
                                    obscureText: _hidePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration:
                                        _fieldDecoration(
                                          'Password',
                                          Icons.lock_outline_rounded,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () => setState(
                                                    () => _hidePassword =
                                                        !_hidePassword,
                                                  ),
                                            icon: Icon(
                                              _hidePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                    validator: (value) {
                                      if ((value ?? '').isEmpty) {
                                        return 'Enter your password';
                                      }
                                      if ((value ?? '').length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: _isLoading
                                            ? null
                                            : (value) => setState(
                                                () =>
                                                    _rememberMe = value ?? true,
                                              ),
                                      ),
                                      Text(
                                        'Remember me',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => context.push(
                                                AppRoutes.forgotPassword,
                                              ),
                                        child: const Text('Forgot password?'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _isLoading ? null : _submit,
                                      icon: _isLoading
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.login_rounded),
                                      label: Text(
                                        _isLoading
                                            ? 'Signing in...'
                                            : 'Open workspace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 17,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Encrypted partner access',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
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

  InputDecoration _fieldDecoration(String label, IconData icon) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: .12)),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .07),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}
