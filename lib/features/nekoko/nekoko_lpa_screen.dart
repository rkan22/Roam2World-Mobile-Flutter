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
    return Scaffold(
      appBar: AppBar(title: const Text('NekokoLPA2')),
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'NekokoLPA2 başlatılamadı: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return const ProviderScope(child: nekoko.MyApp());
        },
      ),
    );
  }
}
