import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'admin_commercial_repository.dart';

class AdminCommercialScreen extends StatefulWidget {
  const AdminCommercialScreen({super.key});

  @override
  State<AdminCommercialScreen> createState() => _AdminCommercialScreenState();
}

class _AdminCommercialScreenState extends State<AdminCommercialScreen> {
  final _repository = AdminCommercialRepository();
  AdminCommercialData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await _repository.fetch();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Admin commercial data could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Admin Commercial'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
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
            Text('Pricing & reports', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: B2BSpacing.xs),
            const Text(
              'Live admin pricing-rule inventory and business totals from the mobile admin API.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: B2BSpacing.lg),
            B2BSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.replay_circle_filled_outlined, color: AppColors.primary),
                    title: const Text('Provider retry queue', style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text('Review failed provider orders and run verified recovery actions'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.adminProviderRetry),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.route_outlined, color: AppColors.primary),
                    title: const Text('Provider routing', style: TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: const Text('Manage live B2B provider priority, primary route and availability'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.adminRouting),
                  ),
                ],
              ),
            ),
            const SizedBox(height: B2BSpacing.lg),
            if (_loading && data == null)
              const ContentLoadingState(label: 'Loading admin commercial data...')
            else if (_error != null && data == null)
              ContentErrorState(message: _error!, onRetry: _load)
            else if (data != null) ...[
              _reports(data.reports),
              const SizedBox(height: B2BSpacing.xl),
              _pricing(data.pricing),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reports(AdminReportsSnapshot report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business reports', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.sm),
        Row(
          children: [
            Expanded(
              child: B2BMetricCard(
                label: 'Total sales',
                value: '${report.currency} ${report.totalSales.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: B2BMetricCard(
                label: 'Orders',
                value: '${report.totalOrders}',
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: B2BSpacing.sm),
        Row(
          children: [
            Expanded(
              child: B2BMetricCard(
                label: 'Completed',
                value: '${report.completedOrders}',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(
              child: B2BMetricCard(
                label: 'Failed',
                value: '${report.failedOrders}',
                icon: Icons.error_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: B2BSpacing.sm),
        B2BSurface(
          child: Column(
            children: [
              _row('Resellers', report.totalResellers, report.activeResellers),
              const Divider(height: B2BSpacing.xl),
              _row('Dealers', report.totalDealers, report.activeDealers),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pricing(AdminPricingSnapshot pricing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile pricing rules', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: B2BSpacing.sm),
        Row(
          children: [
            Expanded(child: B2BMetricCard(label: 'Rules', value: '${pricing.totalRules}', icon: Icons.price_change_outlined)),
            const SizedBox(width: B2BSpacing.sm),
            Expanded(child: B2BMetricCard(label: 'Active', value: '${pricing.activeRules}', icon: Icons.toggle_on_outlined)),
          ],
        ),
        const SizedBox(height: B2BSpacing.sm),
        B2BMetricCard(
          label: 'Featured',
          value: '${pricing.featuredRules}',
          icon: Icons.star_outline_rounded,
        ),
        const SizedBox(height: B2BSpacing.md),
        if (pricing.items.isEmpty)
          const ContentEmptyState(
            icon: Icons.sell_outlined,
            title: 'No pricing rules',
            message: 'The admin pricing endpoint returned no mobile package rules.',
          )
        else
          B2BSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < pricing.items.length; index++) ...[
                  _pricingTile(pricing.items[index]),
                  if (index != pricing.items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _pricingTile(AdminPricingItem item) {
    final subtitle = [
      if (item.provider.isNotEmpty) item.provider,
      if (item.packageId.isNotEmpty) item.packageId,
    ].join(' · ');
    return ListTile(
      leading: Icon(
        item.isActive ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
        color: item.isActive ? AppColors.success : AppColors.textMuted,
      ),
      title: Text(item.packageName, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: item.isFeatured
          ? const Icon(Icons.star_rounded, color: AppColors.warning)
          : null,
    );
  }

  Widget _row(String label, int total, int active) => Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text('$active active / $total total', style: const TextStyle(color: AppColors.textSecondary)),
        ],
      );
}
