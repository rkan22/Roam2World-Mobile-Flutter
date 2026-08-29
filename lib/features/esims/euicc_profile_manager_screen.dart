import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nlpa2/models/euicc_profile.dart';

import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/r2w_toast.dart';
import 'ccid_profile_installer.dart';

const _simAsset = 'assets/images/lpa/euicc_sim.png';
const _activeSimAsset = 'assets/images/lpa/active_profile.png';
const _readerAsset = 'assets/images/lpa/ccid_reader.png';

class EuiccProfileManagerScreen extends StatefulWidget {
  const EuiccProfileManagerScreen({super.key});

  @override
  State<EuiccProfileManagerScreen> createState() => _ManagerState();
}

class _ManagerState extends State<EuiccProfileManagerScreen> {
  final _installer = CcidProfileInstaller();
  List<EuiccProfile> _profiles = const [];
  bool _loading = true;
  String? _reader;
  String? _error;
  String? _busyIccid;

  @override
  void initState() {
    super.initState();
    _connectAndLoad();
  }

  @override
  void dispose() {
    _installer.disconnect();
    super.dispose();
  }

  Future<void> _connectAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _installer.disconnect();
      final readers = await _installer.listReaders();
      if (readers.isEmpty) throw StateError('USB CCID kart okuyucu bulunamadı.');
      final connection = await _installer.connect(readerName: readers.first);
      final profiles = await _installer.listProfiles();
      if (!mounted) return;
      setState(() {
        _reader = connection.reader;
        _profiles = profiles;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _clean(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    try {
      final profiles = await _installer.listProfiles();
      if (mounted) setState(() => _profiles = profiles);
    } catch (_) {
      await _connectAndLoad();
    }
  }

  Future<void> _toggle(EuiccProfile profile, bool enabled) async {
    if (_busyIccid != null) return;
    setState(() => _busyIccid = profile.iccid);
    try {
      await _installer.setProfileEnabled(profile.iccid, enabled: enabled);
      await _reload();
      if (!mounted) return;
      R2WToast.success(
        context,
        enabled ? 'Profil etkinleştirildi.' : 'Profil devre dışı bırakıldı.',
      );
    } catch (error) {
      if (mounted) R2WToast.error(context, _clean(error));
    } finally {
      if (mounted) setState(() => _busyIccid = null);
    }
  }

  Future<void> _rename(EuiccProfile profile) async {
    final controller = TextEditingController(text: profile.displayName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profil adını değiştir'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 64,
          decoration: const InputDecoration(
            labelText: 'Profil adı',
            hintText: 'Örn. Avrupa Seyahati',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || value == profile.displayName) return;
    setState(() => _busyIccid = profile.iccid);
    try {
      await _installer.renameProfile(profile.iccid, value);
      await _reload();
      if (mounted) R2WToast.success(context, 'Profil adı güncellendi.');
    } catch (error) {
      if (mounted) R2WToast.error(context, _clean(error));
    } finally {
      if (mounted) setState(() => _busyIccid = null);
    }
  }

  Future<bool> _delete(EuiccProfile profile) async {
    if (profile.enabled) {
      R2WToast.warning(context, 'Aktif profili önce devre dışı bırakın.');
      return false;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('Profil silinsin mi?'),
        content: Text(
          profile.displayName +
              ' karttan kalıcı olarak silinecek. Bu işlem geri alınamaz.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Profili Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    setState(() => _busyIccid = profile.iccid);
    try {
      await _installer.deleteProfile(profile.iccid);
      await _reload();
      if (!mounted) return true;
      R2WToast.success(context, 'Profil karttan silindi.');
      return true;
    } catch (error) {
      if (mounted) R2WToast.error(context, _clean(error));
      return false;
    } finally {
      if (mounted) setState(() => _busyIccid = null);
    }
  }

  Future<void> _details(EuiccProfile profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfileDetail(
          profile: profile,
          onToggle: _toggle,
          onRename: _rename,
          onDelete: _delete,
        ),
      ),
    );
    await _reload();
  }

  String _clean(Object error) => error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    final activeProfiles = _profiles.where((profile) => profile.enabled);
    final activeProfile = activeProfiles.isEmpty ? null : activeProfiles.first;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'eUICC Yönetimi',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _connectAndLoad,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _connectAndLoad,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            if (!_loading && _error == null)
              _EuiccHero(
                reader: _reader,
                profileCount: _profiles.length,
                activeProfile: activeProfile,
              )
            else
              _ReaderBanner(reader: _reader, connected: _error == null),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _connectAndLoad)
            else if (_profiles.isEmpty)
              const _EmptyState()
            else ...[
              Row(
                children: [
                  Text(
                    'Yüklü Profiller',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _profiles.length.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final profile in _profiles) ...[
                _ProfileCard(
                  profile: profile,
                  busy: _busyIccid == profile.iccid,
                  onTap: () => _details(profile),
                  onToggle: (value) => _toggle(profile, value),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _EuiccHero extends StatelessWidget {
  const _EuiccHero({
    required this.reader,
    required this.profileCount,
    required this.activeProfile,
  });

  final String? reader;
  final int profileCount;
  final EuiccProfile? activeProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(B2BRadius.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: B2BShadows.card,
          ),
          child: Row(
            children: [
              Image.asset(
                _readerAsset,
                width: 132,
                height: 132,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, color: AppColors.success, size: 9),
                        SizedBox(width: 7),
                        Text(
                          'Reader Bağlı',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reader ?? 'USB CCID Reader',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$profileCount profil · ${activeProfile == null ? 0 : 1} aktif',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Aktif Profil',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              top: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                activeProfile == null ? _simAsset : _activeSimAsset,
                width: 100,
                height: 82,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeProfile?.displayName ?? 'Aktif profil yok',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      activeProfile == null
                          ? 'Bir profili etkinleştirerek kullanıma başlayın.'
                          : _masked(activeProfile!.iccid),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (activeProfile != null) ...[
                      const SizedBox(height: 8),
                      const _ActiveBadge(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.busy,
    required this.onTap,
    required this.onToggle,
  });

  final EuiccProfile profile;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(B2BRadius.xl),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: profile.enabled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFEAFBFF)],
                  )
                : null,
            color: profile.enabled ? null : AppColors.card,
            borderRadius: BorderRadius.circular(B2BRadius.xl),
            border: Border.all(
              color: profile.enabled
                  ? AppColors.primary.withValues(alpha: .30)
                  : AppColors.border,
            ),
            boxShadow: profile.enabled
                ? B2BShadows.elevated
                : B2BShadows.card,
          ),
          child: Row(
            children: [
              _ProfileImage(profile: profile, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (profile.enabled) const _ActiveBadge(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.serviceProviderName ?? 'eUICC profili',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _masked(profile.iccid),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              busy
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Switch(
                      value: profile.enabled,
                      onChanged: onToggle,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primaryDark,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetail extends StatefulWidget {
  const _ProfileDetail({
    required this.profile,
    required this.onToggle,
    required this.onRename,
    required this.onDelete,
  });

  final EuiccProfile profile;
  final Future<void> Function(EuiccProfile, bool) onToggle;
  final Future<void> Function(EuiccProfile) onRename;
  final Future<bool> Function(EuiccProfile) onDelete;

  @override
  State<_ProfileDetail> createState() => _ProfileDetailState();
}

class _ProfileDetailState extends State<_ProfileDetail> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Profil Detayı',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _ProfileDetailHero(profile: profile),
          const SizedBox(height: 24),
          const Text(
            'Profil Bilgileri',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(B2BRadius.xl),
              border: Border.all(color: AppColors.border),
              boxShadow: B2BShadows.card,
            ),
            child: Column(
              children: [
                _DetailRow(label: 'ICCID', value: profile.iccid),
                _DetailRow(
                  label: 'Sağlayıcı',
                  value: profile.serviceProviderName ?? '-',
                ),
                _DetailRow(label: 'Profil adı', value: profile.name ?? '-'),
                _DetailRow(
                  label: 'MCC / MNC',
                  value: (profile.mcc ?? '-') + ' / ' + (profile.mnc ?? '-'),
                ),
                _DetailRow(
                  label: 'Profil sınıfı',
                  value: _className(profile.profileClass),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await widget.onToggle(profile, !profile.enabled);
                    if (mounted) Navigator.pop(context);
                  },
            icon: Icon(
              profile.enabled
                  ? Icons.pause_circle_outline_rounded
                  : Icons.check_circle_outline_rounded,
            ),
            label: Text(
              profile.enabled ? 'Profili Devre Dışı Bırak' : 'Profili Aktif Et',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            onPressed: _busy
                ? null
                : () async {
                    await widget.onRename(profile);
                    if (mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Profil Adını Değiştir'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: _busy
                ? null
                : () async {
                    final deleted = await widget.onDelete(profile);
                    if (deleted && mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Profili Sil'),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailHero extends StatelessWidget {
  const _ProfileDetailHero({required this.profile});

  final EuiccProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020817), Color(0xFF0B2742), Color(0xFF075F73)],
        ),
        borderRadius: BorderRadius.circular(B2BRadius.xxl),
        boxShadow: B2BShadows.hero,
      ),
      child: Column(
        children: [
          Container(
            width: 136,
            height: 136,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: Colors.white.withValues(alpha: .13),
              ),
            ),
            child: Image.asset(
              profile.enabled ? _activeSimAsset : _simAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            profile.serviceProviderName ?? 'eUICC profili',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9FB4C8)),
          ),
          const SizedBox(height: 13),
          profile.enabled
              ? const _ActiveBadge(dark: true)
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(B2BRadius.pill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .14),
                    ),
                  ),
                  child: const Text(
                    'PASİF',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _masked(profile.iccid),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFBAE6FD),
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.profile, required this.size});
  final EuiccProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = profile.icon;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .08),
      decoration: BoxDecoration(
        color: profile.enabled ? AppColors.successSoft : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: icon != null && icon.isNotEmpty
          ? Image.memory(Uint8List.fromList(icon), fit: BoxFit.contain)
          : Image.asset(
              profile.enabled ? _activeSimAsset : _simAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
    );
  }
}

class _ReaderBanner extends StatelessWidget {
  const _ReaderBanner({required this.reader, required this.connected});
  final String? reader;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: connected ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.usb_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Reader Bağlı' : 'Reader Bekleniyor',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  reader ?? 'USB CCID reader bağlantısını kontrol edin.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({this.dark = false});

  final bool dark;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.success.withValues(alpha: .18)
            : AppColors.successSoft,
        borderRadius: BorderRadius.circular(99),
        border: dark
            ? Border.all(color: AppColors.success.withValues(alpha: .4))
            : null,
      ),
      child: Text(
        'AKTİF',
        style: TextStyle(
          color: dark ? const Color(0xFFBBF7D0) : AppColors.success,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .6,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          const Icon(Icons.usb_off_rounded, color: AppColors.warning, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Kart okuyucuya bağlanılamadı',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Image(image: AssetImage(_simAsset), width: 120, height: 120),
          SizedBox(height: 16),
          Text(
            'Kartta profil bulunamadı',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 7),
          Text(
            'Yeni bir eSIM profili yükledikten sonra burada görüntülenir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _masked(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 4) +
      ' •••• ' +
      value.substring(value.length - 4);
}

String _className(int value) => switch (value) {
  0 => 'Test',
  1 => 'Provisioning',
  _ => 'Operasyonel',
};
