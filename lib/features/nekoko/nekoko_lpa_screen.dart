import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nlpa2/main.dart' as nekoko;
import 'package:nlpa2/plugins/plugin_manager.dart';
import 'package:nlpa2/services/db_init_native.dart'
    if (dart.library.js_interop) 'package:nlpa2/services/db_init_web.dart';
import 'package:nlpa2/services/deep_link_service.dart';
import 'package:nlpa2/services/local_notification_service.dart';
import 'package:nlpa2/settings/app_settings.dart';
import 'package:nlpa2/utils/migration_helper.dart';

class NekokoLpaScreen extends StatefulWidget {
  const NekokoLpaScreen({super.key, this.activationCode});

  final String? activationCode;

  @override
  State<NekokoLpaScreen> createState() => _NekokoLpaScreenState();
}

class _NekokoLpaScreenState extends State<NekokoLpaScreen> {
  static Future<void>? _initialization;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _initializeAndQueueCode();
  }

  Future<void> _initializeAndQueueCode() async {
    await (_initialization ??= _initializeNekoko());
    final code = widget.activationCode?.trim();
    if (code != null && code.isNotEmpty) {
      final normalized = code.toLowerCase().startsWith('lpa:')
          ? code
          : 'LPA:$code';
      await DeepLinkService().setPendingLpa(normalized);
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('eSIM Device Manager')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'eSIM yöneticisi başlatılamadı: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Stack(
          children: [
            const ProviderScope(child: nekoko.MyApp()),
            Positioned(
              left: 12,
              top: MediaQuery.paddingOf(context).top + 8,
              child: Material(
                color: Colors.white,
                elevation: 2,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Roam2World’e dön',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
