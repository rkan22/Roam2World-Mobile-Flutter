import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'esim_catalog.dart';
import 'esims_repository.dart';
import 'lpa_install_screen.dart';

class EsimDetailScreen extends StatefulWidget {
  const EsimDetailScreen({super.key, required this.initialEsim});

  final MobileEsim initialEsim;

  @override
  State<EsimDetailScreen> createState() => _EsimDetailScreenState();
}

class _EsimDetailScreenState extends State<EsimDetailScreen> {
  final _repository = EsimsRepository();
  late MobileEsim _esim;
  bool _loading = true;
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
      if (mounted) setState(() => _error = 'SIM/eSIM details could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String value, String label) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied.')),
    );
  }

  Future<void> _openLpa() async {
    if (_esim.isPhysicalSim || !_esim.hasQr) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LpaInstallScreen(esim: _esim)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                B2BSpacing.lg,
                B2BSpacing.sm,
                B2BSpacing.lg,
                B2BSpacing.xxl,
              ),
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        _esim.isPhysicalSim ? 'SIM Detail' : 'eSIM Detail',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
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
                  const ContentLoadingState(label: 'Loading inventory details...')
                else if (_error != null)
                  ContentErrorState(message: _error!, onRetry: _load)
                else ...[
                  _HeroCard(esim: _esim),
                  const SizedBox(height: B2BSpacing.md),
                  if (!_esim.isPhysicalSim) ...[
                    _InstallationCard(esim: _esim, onCopy: _copy),
                    const SizedBox(height: B2BSpacing.md),
                  ],
                  _InfoCard(esim: _esim),
                  if (_esim.usageRatio != null) ...[
                    const SizedBox(height: B2BSpacing.md),
                    _UsageCard(esim: _esim),
                  ],
                  if (!_esim.isPhysicalSim && _esim.hasQr) ...[
                    const SizedBox(height: B2BSpacing.md),
                    FilledButton.icon(
                      onPressed: _openLpa,
                      icon: const Icon(Icons.install_mobile_rounded),
                      label: const Text('Install eSIM'),
                    ),
                  ],
                  if (_esim.activationCode.isNotEmpty) ...[
                    const SizedBox(height: B2BSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => _copy(_esim.activationCode, 'Activation details'),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.esim});

  final MobileEsim esim;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(esim);
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.xl),
      decoration: BoxDecoration(
        gradient: B2BGradients.primary,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        boxShadow: B2BShadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: Icon(
                  esim.isPhysicalSim ? Icons.sim_card_rounded : Icons.qr_code_2_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esim.packageName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Text(
                      '${esim.provider} · ${esim.isPhysicalSim ? 'SIM Card' : 'eSIM'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(B2BRadius.full),
                ),
                child: Text(
                  _statusLabel(esim),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.xl),
          Text(
            esim.isPhysicalSim
                ? 'Physical SIM inventory'
                : esim.hasQr
                    ? 'Installation ready'
                    : 'Provisioning in progress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (esim.iccid.isNotEmpty) ...[
            const SizedBox(height: B2BSpacing.sm),
            Text(
              'ICCID ${esim.iccid}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstallationCard extends StatelessWidget {
  const _InstallationCard({required this.esim, required this.onCopy});

  final MobileEsim esim;
  final Future<void> Function(String value, String label) onCopy;

  @override
  Widget build(BuildContext context) {
    final qrValue = esim.qrCode.isNotEmpty ? esim.qrCode : esim.activationCode;
    final renderQr = esim.hasQr && !qrValue.startsWith('http');
    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Installation', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: B2BSpacing.xs),
          Text(
            esim.hasQr ? 'Scan or install directly on this device.' : 'Activation details are not ready yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: B2BSpacing.lg),
          Center(
            child: esim.hasQr
                ? renderQr
                    ? QrImageView(data: qrValue, size: 190)
                    : const Icon(Icons.qr_code_2_rounded, size: 90, color: AppColors.primary)
                : const Icon(Icons.hourglass_top_rounded, size: 70, color: AppColors.textSecondary),
          ),
          if (esim.smdpAddress.isNotEmpty) ...[
            const SizedBox(height: B2BSpacing.lg),
            _CopyField(label: 'SM-DP+', value: esim.smdpAddress, onCopy: onCopy),
          ],
          if (esim.matchingId.isNotEmpty) ...[
            const SizedBox(height: B2BSpacing.sm),
            _CopyField(label: 'Matching ID', value: esim.matchingId, onCopy: onCopy),
          ],
          if (qrValue.isNotEmpty) ...[
            const SizedBox(height: B2BSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => onCopy(qrValue, 'QR data'),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy QR data'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyField extends StatelessWidget {
  const _CopyField({required this.label, required this.value, required this.onCopy});

  final String label;
  final String value;
  final Future<void> Function(String value, String label) onCopy;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(B2BSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(B2BRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: B2BSpacing.xxs),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onCopy(value, label),
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.esim});

  final MobileEsim esim;

  @override
  Widget build(BuildContext context) => B2BSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: B2BSpacing.sm),
            _InfoRow(label: 'Customer', value: esim.customerName.isEmpty ? 'Not assigned' : esim.customerName),
            _InfoRow(label: 'ICCID', value: esim.iccid.isEmpty ? 'Pending' : esim.iccid),
            _InfoRow(label: 'Provider', value: esim.provider),
            _InfoRow(label: 'Type', value: esim.isPhysicalSim ? 'SIM Card' : 'eSIM'),
            if (esim.dataLabel.isNotEmpty) _InfoRow(label: 'Data', value: esim.dataLabel),
            if (esim.validityLabel.isNotEmpty) _InfoRow(label: 'Validity', value: esim.validityLabel),
            if (esim.installStatus.isNotEmpty) _InfoRow(label: 'Install status', value: esim.installStatus),
            _InfoRow(label: 'Expires', value: _formatDate(esim.expiresAt), last: true),
          ],
        ),
      );
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.esim});

  final MobileEsim esim;

  @override
  Widget build(BuildContext context) {
    final ratio = esim.usageRatio ?? 0;
    return B2BSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Data usage', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text('${(ratio * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: B2BSpacing.md),
          LinearProgressIndicator(value: ratio),
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
          border: last ? null : Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            const SizedBox(width: B2BSpacing.md),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

String _statusLabel(MobileEsim esim) {
  if (esim.isExpired) return 'Expired';
  if (esim.isActive) return 'Active';
  if (esim.isPending) return 'Pending';
  return esim.status.isEmpty ? 'Unknown' : esim.status;
}

Color _statusColor(MobileEsim esim) {
  if (esim.isExpired) return AppColors.danger;
  if (esim.isActive) return AppColors.success;
  if (esim.isPending) return AppColors.warning;
  return AppColors.primary;
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Not available';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
}
