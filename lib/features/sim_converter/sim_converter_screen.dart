import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import '../esim_manager/roam_lpa_screen.dart';
import 'sim_converter_data.dart';
import 'sim_converter_repository.dart';

class SimConverterScreen extends StatefulWidget {
  const SimConverterScreen({super.key});

  @override
  State<SimConverterScreen> createState() => _SimConverterScreenState();
}

class _SimConverterScreenState extends State<SimConverterScreen> {
  final _repository = SimConverterRepository();
  final _activationCode = TextEditingController();
  SimConverterWorkspace? _workspace;
  ActivationParseResult? _parseResult;
  bool _loading = true;
  bool _parsing = false;
  bool _openingLpaManager = false;
  String? _error;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _activationCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _workspace == null;
      _error = null;
    });
    try {
      final workspace = await _repository.fetchConversions();
      if (mounted) setState(() => _workspace = workspace);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'SIM converter history could not be loaded.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _parse() async {
    final value = _activationCode.text.trim();
    if (value.isEmpty || _parsing) return;
    setState(() {
      _parsing = true;
      _parseError = null;
      _parseResult = null;
    });
    try {
      final result = await _repository.parseActivationCode(value);
      if (mounted) setState(() => _parseResult = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _parseError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _parseError = 'Activation code could not be parsed.');
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) return;
    _activationCode.text = data!.text!.trim();
    setState(() {});
  }

  Future<void> _openLpaManager() async {
    final activationCode = _activationCode.text.trim();
    if (activationCode.isEmpty || _openingLpaManager) return;
    setState(() => _openingLpaManager = true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => RoamLpaScreen(activationCode: activationCode),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingLpaManager = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversions =
        _workspace?.conversions ?? const <SimConversionSummary>[];
    final canProgram =
        _parseResult?.valid == true && _activationCode.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('SIM Converter'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            B2BSpacing.lg,
            B2BSpacing.xs,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text(
              'Profile inspection',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Validate an eSIM activation code and review server-recorded conversion history.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            B2BSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activation code parser',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: B2BSpacing.sm),
                  TextField(
                    controller: _activationCode,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'LPA:1\$... or provider activation code',
                      suffixIcon: IconButton(
                        onPressed: _paste,
                        tooltip: 'Paste',
                        icon: const Icon(Icons.content_paste_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: B2BSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _parsing ? null : _parse,
                    icon: _parsing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(_parsing ? 'Parsing...' : 'Validate code'),
                  ),
                  if (_parseError != null) ...[
                    const SizedBox(height: B2BSpacing.md),
                    Text(
                      _parseError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_parseResult != null) ...[
                    const SizedBox(height: B2BSpacing.lg),
                    _ParseResultCard(
                      result: _parseResult!,
                      canProgram: canProgram,
                      openingLpaManager: _openingLpaManager,
                      onProgram: _openLpaManager,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Conversion history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_workspace != null)
                  Text(
                    '${_workspace!.total} total',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: B2BSpacing.md),
            if (_loading && _workspace == null)
              const ContentLoadingState(label: 'Loading conversion history...')
            else if (_error != null && _workspace == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (conversions.isEmpty)
              const ContentEmptyState(
                icon: Icons.sim_card_download_outlined,
                title: 'No conversions yet',
                message: 'Server-recorded conversion jobs will appear here.',
              )
            else
              for (final item in conversions) ...[
                B2BSurface(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(B2BRadius.sm),
                        ),
                        child: const Icon(
                          Icons.sim_card_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.profileName.isNotEmpty
                                  ? item.profileName
                                  : 'Conversion ${item.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (item.iccid.isNotEmpty)
                              Text(
                                item.iccid,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: B2BSpacing.sm),
                      Text(
                        item.status,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: B2BSpacing.sm),
              ],
            const SizedBox(height: B2BSpacing.lg),
            const B2BSurface(
              backgroundColor: AppColors.surfaceMuted,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: B2BSpacing.sm),
                  Expanded(
                    child: Text(
                      'Physical SIM programming and USB-reader operations are intentionally not exposed in this mobile workspace.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParseResultCard extends StatelessWidget {
  const _ParseResultCard({
    required this.result,
    required this.canProgram,
    required this.openingLpaManager,
    required this.onProgram,
  });

  final ActivationParseResult result;
  final bool canProgram;
  final bool openingLpaManager;
  final VoidCallback onProgram;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (result.smdpAddress.isNotEmpty) ('SM-DP+', result.smdpAddress),
      if (result.matchingId.isNotEmpty) ('Matching ID', result.matchingId),
      if (result.iccid.isNotEmpty) ('ICCID', result.iccid),
    ];
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.md),
      decoration: BoxDecoration(
        color: (result.valid ? AppColors.success : AppColors.warning)
            .withValues(alpha: .08),
        borderRadius: BorderRadius.circular(B2BRadius.md),
        border: Border.all(
          color: (result.valid ? AppColors.success : AppColors.warning)
              .withValues(alpha: .25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.valid
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                color: result.valid ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: Text(
                  result.valid
                      ? 'Valid activation data'
                      : 'Activation data needs review',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (result.message.isNotEmpty) ...[
            const SizedBox(height: B2BSpacing.sm),
            Text(result.message),
          ],
          for (final row in rows) ...[
            const SizedBox(height: B2BSpacing.sm),
            Text(
              row.$1,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            SelectableText(
              row.$2,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          if (canProgram) ...[
            const SizedBox(height: B2BSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openingLpaManager ? null : onProgram,
                icon: openingLpaManager
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sim_card_download_rounded),
                label: Text(
                  openingLpaManager
                      ? 'Opening Roam2World eSIM Manager...'
                      : 'Program with Roam2World eSIM Manager',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
