import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/widgets/r2w_toast.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'esim_history_repository.dart';

class EsimHistoryScreen extends StatefulWidget {
  const EsimHistoryScreen({super.key});

  @override
  State<EsimHistoryScreen> createState() => _EsimHistoryScreenState();
}

class _EsimHistoryScreenState extends State<EsimHistoryScreen> {
  final _repository = EsimHistoryRepository();
  final _searchController = TextEditingController();
  Timer? _searchTimer;
  bool _loading = true;
  String? _error;
  List<EsimHistoryItem> _items = const [];
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.fetchHistory(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _totalCount = page.totalCount;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'eSIM history could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/esims');
  }

  Future<void> _checkGb(EsimHistoryItem item) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final usage = await _repository.checkTgtGb(item.iccid);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Live TGT usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogRow(
                'ICCID',
                usage.iccid.isEmpty ? item.iccid : usage.iccid,
              ),
              _dialogRow(
                'Remaining',
                usage.remainingGb == null
                    ? 'Not reported'
                    : '${usage.remainingGb!.toStringAsFixed(2)} GB',
              ),
              _dialogRow(
                'Status',
                usage.status.isEmpty ? 'Not reported' : usage.status,
              ),
              _dialogRow(
                'Profile',
                usage.profileStatus.isEmpty
                    ? 'Not reported'
                    : usage.profileStatus,
              ),
              if (usage.orderNo.isNotEmpty) _dialogRow('Order', usage.orderNo),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      R2WToast.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      R2WToast.error(context, 'Live TGT usage could not be checked.');
    }
  }

  Widget _dialogRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('eSIM History'),
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
            B2BSpacing.md,
            B2BSpacing.lg,
            B2BSpacing.xxl,
          ),
          children: [
            Text(
              'Lifecycle history',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: B2BSpacing.xs),
            Text(
              '$_totalCount backend records across purchased and provisioned eSIMs.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search ICCID, customer, phone or package',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading)
              const ContentLoadingState(label: 'Loading eSIM history...')
            else if (_error != null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (_items.isEmpty)
              const ContentEmptyState(
                icon: Icons.history_rounded,
                title: 'No lifecycle records',
                message:
                    'The backend returned no eSIM history records for this account.',
              )
            else
              ..._items.map(_historyCard),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(EsimHistoryItem item) {
    final provider = item.displayProvider.isEmpty
        ? item.provider
        : item.displayProvider;
    final customer = item.customerName.isEmpty
        ? item.customerPhone
        : item.customerName;
    return Padding(
      padding: const EdgeInsets.only(bottom: B2BSpacing.sm),
      child: B2BSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.planName.isEmpty ? 'eSIM ${item.id}' : item.planName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  item.status,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: B2BSpacing.xs),
            if (customer.isNotEmpty)
              Text(
                customer,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            if (provider.isNotEmpty)
              Text(
                provider,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: B2BSpacing.sm),
            if (item.iccid.isNotEmpty) _infoRow('ICCID', item.iccid),
            if (item.orderNumber.isNotEmpty)
              _infoRow('Order', item.orderNumber),
            if (item.dataGb != null) _infoRow('Plan data', '${item.dataGb} GB'),
            if (item.remainingGb != null)
              _infoRow(
                'Recorded remaining',
                '${item.remainingGb!.toStringAsFixed(2)} GB',
              ),
            if (item.validityDays != null)
              _infoRow('Validity', '${item.validityDays} days'),
            if (item.supportsTgtGbCheck) ...[
              const SizedBox(height: B2BSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _checkGb(item),
                icon: const Icon(Icons.data_usage_rounded),
                label: const Text('Check live GB'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        SizedBox(
          width: 122,
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
