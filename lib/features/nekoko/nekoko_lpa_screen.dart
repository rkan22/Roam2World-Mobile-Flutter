import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nlpa2/l10n/app_localizations.dart' as nekoko_l10n;
import 'package:nlpa2/pages/main_tab_screen.dart';
import 'package:nlpa2/plugins/plugin_manager.dart';
import 'package:nlpa2/services/db_init_native.dart'
    if (dart.library.js_interop) 'package:nlpa2/services/db_init_web.dart';
import 'package:nlpa2/services/deep_link_service.dart';
import 'package:nlpa2/services/local_notification_service.dart';
import 'package:nlpa2/settings/app_settings.dart';
import 'package:nlpa2/utils/migration_helper.dart';
import 'package:nlpa2/widgets/profile_installation_dialog.dart';

import '../../core/theme/app_colors.dart';

class NekokoLpaScreen extends StatefulWidget {
  const NekokoLpaScreen({super.key, this.activationCode});

  final String? activationCode;

  @override
  State<NekokoLpaScreen> createState() => _NekokoLpaScreenState();
}

class _NekokoLpaScreenState extends State<NekokoLpaScreen> {
  static Future<void>? _initialization;
  late final Future<void> _ready;
  String? _pendingActivationCode;
  bool _installationDialogShown = false;

  @override
  void initState() {
    super.initState();
    _ready = _initializeAndQueueCode();
  }

  Future<void> _initializeAndQueueCode() async {
    await (_initialization ??= _initializeNekoko());
    final code = widget.activationCode?.trim();
    if (code != null && code.isNotEmpty) {
      _pendingActivationCode = code.toLowerCase().startsWith('lpa:')
          ? code
          : 'LPA:$code';
      await DeepLinkService().setPendingLpa(_pendingActivationCode!);
    }
  }

  static Future<void> _initializeNekoko() async {
    PluginManager();
    await initDb();
    await Future.wait<void>([
      AppSettings().init(),
      LocalNotificationService().init(),
    ]);
    DeepLinkService().init();
    MigrationHelper.performMigration();
  }

  void _showInstallationDialog() {
    final code = _pendingActivationCode;
    if (_installationDialogShown || code == null || !mounted) return;
    _installationDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProfileInstallationDialog(lpaCode: code),
      );
      await DeepLinkService().clearPendingLpa();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nekoko internal tool'),
            Text(
              'Secure profile installation',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _NekokoError(
              message: 'eSIM manager could not start: ${snapshot.error}',
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NekokoLoading();
          }
          _showInstallationDialog();
          return const ProviderScope(child: _RoamNekokoWorkspace());
        },
      ),
    );
  }
}

class _RoamNekokoWorkspace extends StatelessWidget {
  const _RoamNekokoWorkspace();

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      delegates: const [
        nekoko_l10n.AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.heroStart, AppColors.heroEnd],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.security_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage and install eSIM profiles without leaving Roam2World.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: MainTabScreen()),
        ],
      ),
    );
  }
}

class _NekokoLoading extends StatelessWidget {
  const _NekokoLoading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          'Preparing internal eSIM workspace…',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _NekokoError extends StatelessWidget {
  const _NekokoError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withValues(alpha: .2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
