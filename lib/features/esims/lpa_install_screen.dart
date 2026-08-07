import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'esim_catalog.dart';
import 'lpa_bridge.dart';

class LpaInstallScreen extends StatefulWidget {
  const LpaInstallScreen({super.key, required this.esim});
  final MobileEsim esim;
  @override
  State<LpaInstallScreen> createState() => _LpaInstallScreenState();
}

class _LpaInstallScreenState extends State<LpaInstallScreen> {
  final _bridge = LpaBridge();
  LpaCapability? _capability;
  bool _checking = true;
  bool _installing = false;
  bool _installed = false;
  String? _installError;

  @override
  void initState() {
    super.initState();
    _checkCapability();
  }

  Future<void> _checkCapability() async {
    setState(() {
      _checking = true;
      _installError = null;
    });
    final capability = await _bridge.capability();
    if (!mounted) return;
    setState(() {
      _capability = capability;
      _checking = false;
    });
  }

  Future<void> _install() async {
    final code = widget.esim.activationCode.isNotEmpty
        ? widget.esim.activationCode
        : widget.esim.qrCode;
    setState(() {
      _installing = true;
      _installError = null;
    });
    try {
      final result = await _bridge.installActivationCode(code);
      if (!mounted) return;
      setState(() => _installed = result.installed);
    } on LpaBridgeException catch (error) {
      if (!mounted) return;
      setState(() => _installError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _installError = 'eSIM profili yüklenemedi.');
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final capability = _capability;
    return Scaffold(
      appBar: AppBar(title: const Text('Cihaza Yükle (LPA)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _EsimCard(esim: widget.esim),
            const SizedBox(height: 28),
            if (_checking) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Text(
                'Cihaz LPA desteği kontrol ediliyor…',
                textAlign: TextAlign.center,
              ),
            ] else if (_installed) ...[
              const Icon(Icons.check_circle_rounded, size: 84, color: Colors.green),
              const SizedBox(height: 18),
              const Text(
                'eSIM başarıyla yüklendi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Android sistem LPA işlemi başarıyla tamamladı.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.done_rounded),
                label: const Text('Tamam'),
              ),
            ] else if (capability != null) ...[
              Icon(
                capability.esimSupported
                    ? Icons.sim_card_rounded
                    : Icons.info_outline_rounded,
                size: 84,
                color: capability.esimSupported
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 18),
              Text(
                capability.directInstallSupported
                    ? 'eSIM kuruluma hazır'
                    : (capability.esimSupported
                        ? 'eSIM destekleniyor'
                        : 'Doğrudan LPA kullanılamıyor'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                capability.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              if (capability.transport != 'none') ...[
                const SizedBox(height: 10),
                Text(
                  'Transport: ${capability.transport}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (_installError != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.red.withValues(alpha: .2)),
                  ),
                  child: Text(
                    _installError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (capability.directInstallSupported)
                ElevatedButton.icon(
                  onPressed: _installing ? null : _install,
                  icon: _installing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.install_mobile_rounded),
                  label: Text(
                    _installing ? 'Android onayı bekleniyor…' : 'Kurulumu Başlat',
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Uygulama, desteklenen ve yetkili bir LPA transport bulunmadan profili yüklenmiş gibi göstermeyecek.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checkCapability,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar Kontrol Et'),
                ),
              ],
            ],
            if (!_installed) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _installing ? null : () => Navigator.of(context).pop(),
                child: const Text('Geri'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EsimCard extends StatelessWidget {
  const _EsimCard({required this.esim});
  final MobileEsim esim;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              esim.packageName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              esim.provider,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (esim.iccid.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'ICCID  ${esim.iccid}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      );
}
