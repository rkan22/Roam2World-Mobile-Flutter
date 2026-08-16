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
import 'provider_status_sheet.dart';
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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/esims');
    }
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
        isScrollControlled: true,
        builder: (context) {
          final theme = Theme.of(context);
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .72,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    'Renew eSIM',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prices include the backend pricing and markup rules.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final option in options) ...[
                    Material(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.pop(context, option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            boxShadow: theme.brightness == Brightness.light
                                ? B2BShadows.card
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${option.dataGb} GB · ${option.validityDays} days',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      option.displayProvider,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                option.formattedPrice,
                                maxLines: 1,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          );
        },
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
        isScrollControlled: true,
        builder: (context) => ProviderStatusSheet(data: result.data),
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

  String _displayPackageName(String rawName) {
    var name = rawName.trim();
    if (name.isEmpty) return 'eSIM package';

    name = name.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    const providerPrefixes = <String>[
      'Orange Big Data',
      'Orange Balkans',
      'Orange Europe',
      'Orange World',
      'T.T Turkey',
      'KPN Europe',
      'Roam2World',
      'Worldmove',
      'Vodafone',
      'Flexnet',
      'Airhub',
      'TGT',
    ];
    for (final prefix in providerPrefixes) {
      name = name.replaceFirst(
        RegExp(
          '^${RegExp.escape(prefix)}\\s*[-–—|:]\\s*',
          caseSensitive: false,
        ),
        '',
      );
    }

    name = name.replaceFirst(
      RegExp(
        r'^[A-Z0-9]{2,}(?:-[A-Z0-9]{2,})+\s*[-–—|:]\s*',
        caseSensitive: false,
      ),
      '',
    );
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name.isEmpty ? rawName.trim() : name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerKey = _esim.providerKey.toLowerCase();
    final statusColor = _esim.hasQr ? AppColors.success : AppColors.warning;

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
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'eSIM details',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: B2BSpacing.xxs),
                        Text(
                          _esim.provider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: B2BSpacing.lg),
              if (_loading)
                const ContentLoadingState(label: 'Loading eSIM details...')
              else if (_error != null)
                ContentErrorState(message: _error!, onRetry: _load)
              else ...[
                Container(
                  padding: const EdgeInsets.all(B2BSpacing.xl),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(B2BRadius.md),
                            ),
                            child: const Icon(
                              Icons.sim_card_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: B2BSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayPackageName(_esim.packageName),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: B2BSpacing.xxs),
                                Text(
                                  _esim.customerName.isEmpty
                                      ? 'Customer not assigned'
                                      : _esim.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: B2BSpacing.sm),
                          _StatusBadge(
                            status: _esim.hasQr ? 'Ready' : _esim.status,
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: B2BSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(B2BSpacing.md),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(B2BRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _esim.hasQr
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.hourglass_top_rounded,
                              color: statusColor,
                            ),
                            const SizedBox(width: B2BSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _esim.hasQr
                                        ? 'Ready to install'
                                        : 'Provisioning in progress',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _esim.hasQr
                                        ? 'Activation data is available for this line.'
                                        : 'Activation data will appear after provisioning finishes.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: B2BSpacing.lg),
                Text('Installation', style: theme.textTheme.titleLarge),
                const SizedBox(height: B2BSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(B2BSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(B2BRadius.xl),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusBadge(
                            status: _esim.hasQr ? 'QR READY' : 'PENDING',
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: B2BSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(B2BRadius.lg),
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
                                    size: 58,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                      if (_esim.hasQr) ...[
                        const SizedBox(height: B2BSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _copy(
                              _esim.qrCode.isNotEmpty
                                  ? _esim.qrCode
                                  : _esim.activationCode,
                              'QR data',
                            ),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy QR data'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: B2BSpacing.lg),
                _InfoCard(esim: _esim, expiryLabel: _date(_esim.expiresAt)),
                const SizedBox(height: B2BSpacing.lg),
                Text('Actions', style: theme.textTheme.titleLarge),
                const SizedBox(height: B2BSpacing.sm),
                _ActionButton(
                  onPressed: _operating ? null : _refreshProviderData,
                  icon: Icons.sync_rounded,
                  label: _operating ? 'Checking provider…' : 'Check live usage',
                  filled: false,
                  loading: _operating,
                ),
                if (providerKey.contains('tgt')) ...[
                  const SizedBox(height: B2BSpacing.sm),
                  _ActionButton(
                    onPressed: _renewing ? null : _renewWithBackendOptions,
                    icon: Icons.autorenew_rounded,
                    label: _renewing ? 'Renewing...' : 'Renew TGT eSIM',
                    filled: true,
                    loading: _renewing,
                  ),
                ],
                if (providerKey.contains('worldmove')) ...[
                  const SizedBox(height: B2BSpacing.sm),
                  _ActionButton(
                    onPressed: _operating ? null : _topUpWorldmove,
                    icon: Icons.add_card_rounded,
                    label: 'Top up Worldmove SIM',
                    filled: false,
                  ),
                ],
                if (providerKey.contains('vodafone') ||
                    providerKey.contains('airhub')) ...[
                  const SizedBox(height: B2BSpacing.sm),
                  _ActionButton(
                    onPressed: _renewing ? null : _renewWithBackendOptions,
                    icon: Icons.autorenew_rounded,
                    label: _renewing ? 'Renewing...' : 'Renew Vodafone eSIM',
                    filled: true,
                    loading: _renewing,
                  ),
                ],
                if (_esim.hasQr || _esim.activationCode.isNotEmpty) ...[
                  const SizedBox(height: B2BSpacing.sm),
                  _ActionButton(
                    onPressed: _openLpa,
                    icon: Icons.install_mobile_rounded,
                    label: 'Install on device',
                    filled: true,
                  ),
                ],
                if (_esim.activationCode.isNotEmpty) ...[
                  const SizedBox(height: B2BSpacing.sm),
                  _ActionButton(
                    onPressed: () =>
                        _copy(_esim.activationCode, 'Activation details'),
                    icon: Icons.copy_rounded,
                    label: 'Copy activation details',
                    filled: false,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.filled,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final iconWidget = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: iconWidget,
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: iconWidget,
              label: Text(label),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(B2BRadius.pill),
    ),
    child: Text(
      status,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.all(B2BSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Provisioning details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: B2BSpacing.sm),
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
