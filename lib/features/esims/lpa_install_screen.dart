import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'ccid_profile_installer.dart';
import 'esim_catalog.dart';
import 'lpa_bridge.dart';

enum _InstallStage {
  compatibility,
  reader,
  card,
  downloading,
  installing,
  success,
  failure,
}

class LpaInstallScreen extends StatefulWidget {
  const LpaInstallScreen({super.key, required this.esim});

  final MobileEsim esim;

  @override
  State<LpaInstallScreen> createState() => _LpaInstallScreenState();
}

class _LpaInstallScreenState extends State<LpaInstallScreen> {
  final _bridge = LpaBridge();
  final _ccidInstaller = CcidProfileInstaller();

  _InstallStage _stage = _InstallStage.compatibility;
  LpaCapability? _capability;
  bool _busy = true;
  String? _readerName;
  String? _atr;
  String? _error;
  double _progress = 0;
  String _progressMessage = 'Hazırlanıyor…';

  String get _activationCode => widget.esim.activationCode.isNotEmpty
      ? widget.esim.activationCode
      : widget.esim.qrCode;

  @override
  void initState() {
    super.initState();
    _checkCompatibility();
  }

  @override
  void dispose() {
    _ccidInstaller.disconnect();
    super.dispose();
  }

  Future<void> _checkCompatibility() async {
    setState(() {
      _stage = _InstallStage.compatibility;
      _busy = true;
      _error = null;
      _progress = 0;
    });
    final capability = await _bridge.capability();
    if (!mounted) return;
    setState(() {
      _capability = capability;
      _busy = false;
    });
  }

  void _continueFromCompatibility() {
    final capability = _capability;
    if (capability == null) return;
    if (capability.ccidAvailable) {
      setState(() => _stage = _InstallStage.reader);
      return;
    }
    if (capability.directInstallSupported) {
      _installWithSystemLpa();
      return;
    }
    setState(() {
      _stage = _InstallStage.failure;
      _error = capability.reason;
    });
  }

  Future<void> _connectReader() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final readers = _capability?.ccidReaders ?? const <String>[];
      final connection = await _ccidInstaller.connect(
        readerName: readers.isEmpty ? null : readers.first,
      );
      if (!mounted) return;
      setState(() {
        _readerName = connection.reader;
        _atr = connection.atr;
        _stage = _InstallStage.card;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _InstallStage.failure;
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _installWithCcid() async {
    setState(() {
      _stage = _InstallStage.downloading;
      _busy = true;
      _error = null;
      _progress = .04;
      _progressMessage = 'SM-DP+ ile güvenli bağlantı kuruluyor…';
    });

    try {
      await _ccidInstaller.install(
        _activationCode,
        onUpdate: (update) {
          if (!mounted) return;
          setState(() {
            _progress = update.progress.clamp(0.0, 1.0).toDouble();
            _progressMessage = update.message;
            _stage = switch (update.stage) {
              CcidInstallStage.connecting ||
              CcidInstallStage.authenticating ||
              CcidInstallStage.downloading => _InstallStage.downloading,
              CcidInstallStage.installing => _InstallStage.installing,
              CcidInstallStage.completed => _InstallStage.success,
            };
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _InstallStage.failure;
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _installWithSystemLpa() async {
    setState(() {
      _stage = _InstallStage.installing;
      _busy = true;
      _error = null;
      _progress = .2;
      _progressMessage = 'Android LPA onayı bekleniyor…';
    });
    try {
      final result = await _bridge.installActivationCode(_activationCode);
      if (!mounted) return;
      setState(() {
        if (result.installed) {
          _progress = 1;
          _stage = _InstallStage.success;
        } else {
          _stage = _InstallStage.failure;
          _error = 'Android LPA kurulumu tamamlamadı.';
        }
      });
    } on LpaBridgeException catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _InstallStage.failure;
        _error = error.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry() async {
    await _ccidInstaller.disconnect();
    await _checkCompatibility();
  }

  @override
  Widget build(BuildContext context) {
    final step = switch (_stage) {
      _InstallStage.compatibility => 1,
      _InstallStage.reader => 2,
      _InstallStage.card => 3,
      _InstallStage.downloading => 4,
      _InstallStage.installing => 5,
      _InstallStage.success || _InstallStage.failure => 6,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'eSIM Kurulumu',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressRail(current: step, failed: _stage == _InstallStage.failure),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: SingleChildScrollView(
                  key: ValueKey(_stage),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  child: _stageBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageBody() {
    return switch (_stage) {
      _InstallStage.compatibility => _compatibilityView(),
      _InstallStage.reader => _readerView(),
      _InstallStage.card => _cardView(),
      _InstallStage.downloading => _progressView(
          icon: Icons.cloud_download_outlined,
          title: 'Profil İndiriliyor',
          subtitle: _progressMessage,
        ),
      _InstallStage.installing => _progressView(
          icon: Icons.sim_card_download_outlined,
          title: 'Profile Yükleniyor',
          subtitle: _progressMessage,
          warning: 'Reader bağlantısını kesmeyin.',
        ),
      _InstallStage.success => _resultView(success: true),
      _InstallStage.failure => _resultView(success: false),
    };
  }

  Widget _compatibilityView() {
    final capability = _capability;
    final ready = capability?.ccidAvailable == true ||
        capability?.directInstallSupported == true;
    return _StageCard(
      icon: Icons.verified_user_outlined,
      title: 'Uyumluluk Kontrolü',
      subtitle: _busy
          ? 'Cihazınız kontrol ediliyor…'
          : ready
          ? 'Kurulum için gerekli bağlantılar hazır.'
          : 'Desteklenen LPA transport bulunamadı.',
      children: [
        _CheckRow(
          label: 'Android cihaz',
          value: capability?.platform == 'android' ? 'Destekleniyor' : 'Kontrol edildi',
          passed: capability != null,
        ),
        _CheckRow(
          label: 'İnternet bağlantısı',
          value: 'Gerekli',
          passed: true,
        ),
        _CheckRow(
          label: 'USB CCID reader',
          value: capability?.ccidAvailable == true
              ? 'Bulundu'
              : capability?.directInstallSupported == true
              ? 'Sistem LPA kullanılacak'
              : 'Bulunamadı',
          passed: ready,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy || !ready ? null : _continueFromCompatibility,
          child: Text(_busy ? 'Kontrol ediliyor…' : 'Devam'),
        ),
        if (!ready && !_busy) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _checkCompatibility,
            child: const Text('Tekrar Kontrol Et'),
          ),
        ],
      ],
    );
  }

  Widget _readerView() {
    final readers = _capability?.ccidReaders ?? const <String>[];
    final reader = readers.isEmpty ? 'USB CCID Reader' : readers.first;
    return _StageCard(
      icon: Icons.usb_rounded,
      title: 'CCID Reader',
      subtitle: 'Kart okuyucu bağlantısı ve Android USB izni kontrol edilecek.',
      children: [
        _InfoSurface(
          icon: Icons.usb_outlined,
          title: reader,
          subtitle: 'Reader bulundu',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _busy ? null : _connectReader,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link_rounded),
          label: Text(_busy ? 'USB izni bekleniyor…' : 'Reader’a Bağlan'),
        ),
      ],
    );
  }

  Widget _cardView() {
    return _StageCard(
      icon: Icons.sim_card_outlined,
      title: 'eUICC Kart',
      subtitle: 'Kart algılandı ve ATR başarıyla doğrulandı.',
      children: [
        _CheckRow(label: 'Reader', value: _readerName ?? '-', passed: true),
        _CheckRow(label: 'Kart algılandı', value: 'Hazır', passed: true),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'ATR  ${_groupAtr(_atr)}',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 13,
              letterSpacing: .6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _installWithCcid,
          child: const Text('Profili İndir ve Yükle'),
        ),
      ],
    );
  }

  Widget _progressView({
    required IconData icon,
    required String title,
    required String subtitle,
    String? warning,
  }) {
    return _StageCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      children: [
        _PlanSummary(esim: widget.esim),
        const SizedBox(height: 28),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: _progress <= 0 ? null : _progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(_progress * 100).round()}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (warning != null) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: .25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(child: Text(warning)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultView({required bool success}) {
    return _StageCard(
      icon: success ? Icons.check_rounded : Icons.close_rounded,
      iconColor: success ? AppColors.success : AppColors.danger,
      iconBackground: success ? AppColors.successSoft : AppColors.dangerSoft,
      title: success ? 'Kurulum Başarılı' : 'Kurulum Başarısız',
      subtitle: success
          ? 'eSIM profili başarıyla yüklendi.'
          : 'Profil yüklenemedi. Reader bağlantısını kontrol edip tekrar deneyin.',
      children: [
        if (success)
          _PlanSummary(esim: widget.esim)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.danger.withValues(alpha: .18)),
            ),
            child: Text(
              _cleanError(_error),
              style: const TextStyle(color: AppColors.danger, height: 1.4),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: success
              ? () => Navigator.of(context).pop(true)
              : _retry,
          child: Text(success ? 'Tamam' : 'Tekrar Dene'),
        ),
        if (!success) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Destek'),
          ),
        ],
      ],
    );
  }

  String _groupAtr(String? atr) {
    final value = (atr ?? '').replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (value.isEmpty) return '-';
    return [
      for (var i = 0; i < value.length; i += 2)
        value.substring(i, i + 2 > value.length ? value.length : i + 2),
    ].join(' ');
  }

  String _cleanError(String? value) {
    if (value == null || value.isEmpty) return 'Hata kodu: CCID-001';
    return value.replaceFirst('Exception: ', '');
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.current, required this.failed});

  final int current;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    const labels = ['Uyumluluk', 'Reader', 'Kart', 'İndir', 'Yükle', 'Sonuç'];
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 15),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index + 1 < current
                          ? AppColors.success
                          : index + 1 == current
                          ? failed
                                ? AppColors.danger
                                : AppColors.primary
                          : AppColors.surfaceMuted,
                      border: Border.all(
                        color: index + 1 <= current
                            ? failed && index + 1 == current
                                  ? AppColors.danger
                                  : AppColors.primary
                            : AppColors.borderStrong,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index + 1 <= current
                            ? Colors.white
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: index + 1 == current
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: index + 1 == current
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (index < labels.length - 1)
              Container(
                width: 8,
                height: 1,
                color: index + 1 < current
                    ? AppColors.success
                    : AppColors.borderStrong,
              ),
          ],
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primaryLight,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A020817),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.passed,
  });

  final String label;
  final String value;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: passed ? AppColors.success : AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSurface extends StatelessWidget {
  const _InfoSurface({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.statusColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.esim});

  final MobileEsim esim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esim.packageName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  esim.provider,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
