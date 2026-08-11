import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'esim_catalog.dart';
import 'esims_repository.dart';
import 'lpa_install_screen.dart';
import 'provider_lifecycle_repository.dart';
import '../packages/package_catalog.dart';
import '../packages/packages_repository.dart';

class EsimDetailScreen extends StatefulWidget {
  const EsimDetailScreen({super.key, required this.initialEsim});

  final MobileEsim initialEsim;

  @override
  State<EsimDetailScreen> createState() => _EsimDetailScreenState();
}

class _EsimDetailScreenState extends State<EsimDetailScreen> {
  final _repository = EsimsRepository();
  final _lifecycleRepository = ProviderLifecycleRepository();
  final _packagesRepository = PackagesRepository();
  late MobileEsim _esim;
  bool _loading = true;
  bool _renewing = false;
  bool _operating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _esim = widget.initialEsim;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.fetchEsimDetail(widget.initialEsim.id);
      if (mounted) setState(() => _esim = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'eSIM details could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String value, String label) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  Future<void> _openLpa() async {
    if (!_esim.hasQr && _esim.activationCode.isEmpty) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LpaInstallScreen(esim: _esim)));
  }

  Future<void> _renewWithBackendOptions() async {
    setState(() => _renewing = true);
    try {
      final options = await _repository.fetchRenewalOptions(_esim);
      if (!mounted) return;
      if (options.isEmpty) {
        throw const ApiException(message: 'No renewal option is available.');
      }
      setState(() => _renewing = false);
      final selected = await showModalBottomSheet<MobileRenewalOption>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text('Renew eSIM', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Prices include the backend pricing and markup rules.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${option.dataGb} GB · ${option.validityDays} days',
                  ),
                  subtitle: Text(option.displayProvider),
                  trailing: Text(
                    option.formattedPrice,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() => _renewing = true);
      final provider = _esim.providerKey.toLowerCase();
      final message = provider.contains('tgt') || provider.contains('balkan')
          ? await _repository.renewTgtEsim(
              _esim.id,
              productCode: selected.productCode,
              dataGb: selected.dataGb,
              finalPrice: selected.price,
            )
          : await _repository.renewVodafoneEsim(
              _esim.id,
              selected.dataGb,
              finalPrice: selected.price,
            );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _renewing = false);
    }
  }

  Future<void> _refreshProviderData() async {
    setState(() => _operating = true);
    try {
      final provider = _esim.providerKey.toLowerCase();
      final ProviderOperationResult result;
      if (provider.contains('flexnet')) {
        result = await _lifecycleRepository.syncFlexnetEsim(_esim.id);
      } else if (provider.contains('worldmove')) {
        result = await _lifecycleRepository.checkWorldmoveUsage(
          iccid: _esim.iccid,
          orderId: _esim.providerOrderId,
        );
      } else if (provider.contains('airhub') || provider.contains('vodafone')) {
        result = await _lifecycleRepository.checkAirhubUsage(
          orderId: _esim.providerOrderId,
          iccid: _esim.iccid,
        );
      } else if (provider.contains('esimcard')) {
        result = await _lifecycleRepository.checkEsimcardUsage(
          _esim.iccid.isEmpty ? '${_esim.id}' : _esim.iccid,
        );
      } else {
        result = await _lifecycleRepository.checkSmartUsage(
          provider: provider,
          esimId: '${_esim.id}',
          iccid: _esim.iccid,
          orderId: _esim.providerOrderId,
        );
      }
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Live provider status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(result.data),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _operating = false);
    }
  }

  Future<void> _topUpWorldmove() async {
    if (_esim.iccid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A SIM or ICCID number is required for top-up.'),
        ),
      );
      return;
    }
    setState(() => _operating = true);
    try {
      final catalog = await _packagesRepository.fetchPackages(
        forceRefresh: true,
      );
      final packages = catalog.packages
          .where((item) => item.provider.toLowerCase().contains('worldmove'))
          .toList(growable: false);
      if (!mounted) return;
      if (packages.isEmpty) {
        throw const ApiException(
          message: 'No Worldmove top-up package is available.',
        );
      }
      setState(() => _operating = false);
      final selected = await showModalBottomSheet<MobilePackage>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .7,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: packages.length + 1,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Choose Worldmove top-up',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                }
                final package = packages[index - 1];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(package.name),
                  subtitle: Text(
                    '${package.dataLabel} · ${package.validityLabel}',
                  ),
                  trailing: Text(
                    package.formattedPrice,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () => Navigator.pop(context, package),
                );
              },
            ),
          ),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() => _operating = true);
      final result = await _lifecycleRepository.topUpWorldmove(
        packageId: selected.id,
        simNumber: _esim.iccid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isEmpty ? 'Top-up completed.' : result.message,
          ),
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _operating = false);
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Not available';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'eSIM details',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_loading)
                const ContentLoadingState(label: 'Loading eSIM details...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else ...[
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: B2BGradients.primary,
                    borderRadius: BorderRadius.circular(B2BRadius.xxl),
                    boxShadow: B2BShadows.hero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.sim_card_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _esim.packageName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _esim.provider,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(status: _esim.status),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        _esim.hasQr
                            ? 'Ready to install'
                            : 'Provisioning in progress',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          letterSpacing: -0.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _esim.hasQr
                            ? 'Activation data is available for customer delivery.'
                            : 'The activation package will appear here when provisioning finishes.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(B2BRadius.xl),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: theme.brightness == Brightness.light
                        ? B2BShadows.card
                        : null,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _esim.hasQr
                                  ? 'Installation QR'
                                  : 'Installation pending',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _esim.hasQr
                                  ? AppColors.accentSoft
                                  : AppColors.warningSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _esim.hasQr ? 'QR READY' : 'PENDING',
                              style: TextStyle(
                                color: _esim.hasQr
                                    ? AppColors.accent
                                    : AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _esim.hasQr
                            ? QrImageView(
                                data: _esim.qrCode.isNotEmpty
                                    ? _esim.qrCode
                                    : _esim.activationCode,
                                size: 184,
                              )
                            : const SizedBox(
                                height: 184,
                                child: Center(
                                  child: Icon(
                                    Icons.hourglass_top_rounded,
                                    size: 62,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                      if (_esim.hasQr) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _copy(
                            _esim.qrCode.isNotEmpty
                                ? _esim.qrCode
                                : _esim.activationCode,
                            'QR data',
                          ),
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy QR data'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoCard(esim: _esim, expiryLabel: _date(_esim.expiresAt)),
                OutlinedButton.icon(
                  onPressed: _operating ? null : _refreshProviderData,
                  icon: _operating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(
                    _operating ? 'Checking provider…' : 'Check live usage',
                  ),
                ),
                if (_esim.providerKey.toLowerCase().contains('tgt')) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _renewing ? null : _renewWithBackendOptions,
                    icon: _renewing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.autorenew_rounded),
                    label: Text(_renewing ? 'Renewing...' : 'Renew TGT eSIM'),
                  ),
                ],
                if (_esim.providerKey.toLowerCase().contains('worldmove')) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _operating ? null : _topUpWorldmove,
                    icon: const Icon(Icons.add_card_rounded),
                    label: const Text('Top up Worldmove SIM'),
                  ),
                ],
                if (_esim.providerKey.toLowerCase().contains('vodafone') ||
                    _esim.providerKey.toLowerCase().contains('airhub')) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _renewing ? null : _renewWithBackendOptions,
                    icon: const Icon(Icons.autorenew_rounded),
                    label: const Text('Renew Vodafone eSIM'),
                  ),
                ],
                if (_esim.hasQr || _esim.activationCode.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openLpa,
                    icon: const Icon(Icons.install_mobile_rounded),
                    label: const Text('Install on device'),
                  ),
                ],
                if (_esim.activationCode.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _copy(_esim.activationCode, 'Activation details'),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy activation details'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.esim, required this.expiryLabel});
  final MobileEsim esim;
  final String expiryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light
            ? B2BShadows.card
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Provisioning details', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Customer',
            value: esim.customerName.isEmpty
                ? 'Not assigned'
                : esim.customerName,
          ),
          _InfoRow(
            label: 'ICCID',
            value: esim.iccid.isEmpty ? 'Pending' : esim.iccid,
          ),
          _InfoRow(label: 'Provider', value: esim.provider),
          _InfoRow(
            label: 'Install status',
            value: esim.installStatus.isEmpty ? 'Unknown' : esim.installStatus,
          ),
          _InfoRow(label: 'Expires', value: expiryLabel, last: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
