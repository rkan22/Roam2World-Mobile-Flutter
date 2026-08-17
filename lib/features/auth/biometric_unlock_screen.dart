import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_state.dart';
import '../../core/auth/biometric_auth_service.dart';
import '../../core/routing/app_router.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_colors.dart';

class BiometricUnlockScreen extends StatefulWidget {
  const BiometricUnlockScreen({super.key});

  @override
  State<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends State<BiometricUnlockScreen> {
  bool _authenticating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _message = null;
    });
    final unlocked = await BiometricAuthService.instance.authenticate();
    if (!mounted) return;
    if (unlocked) {
      context.go(AppRoutes.dashboard);
      return;
    }
    setState(() {
      _authenticating = false;
      _message = 'Face ID could not verify your identity.';
    });
  }

  Future<void> _usePassword() async {
    await BiometricAuthService.instance.disable();
    await TokenStorage().clear();
    AuthState.instance.signedOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071222),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/branding/roam2world_logo_transparent.png',
                    width: 250,
                  ),
                  const SizedBox(height: 54),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .35),
                      ),
                    ),
                    child: const Icon(
                      Icons.face_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Unlock your workspace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _message ?? 'Confirm your identity securely with Face ID.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _authenticating ? null : _unlock,
                      icon: _authenticating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.face_rounded),
                      label: Text(
                        _authenticating ? 'Verifying…' : 'Unlock with Face ID',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _authenticating ? null : _usePassword,
                    child: const Text('Sign in with password instead'),
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
