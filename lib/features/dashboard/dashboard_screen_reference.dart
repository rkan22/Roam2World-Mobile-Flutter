import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'dashboard_data.dart';
import 'dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.repository});

  final DashboardRepository? repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _channel = MethodChannel('com.roam2world.mobile/lpa');

  late final DashboardRepository _repository;
  DashboardData? _data;
  Object? _error;
  bool _loading = true;
  bool _showingStaleData = false;
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DashboardRepository();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _loading = _data == null;
        _error = null;
      });
    }

    try {
      final result = await _repository.fetchDashboard(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _data = result;
        _showingStaleData = _repository.lastFetchUsedStale;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const ContentLoadingState(label: 'Loading your dashboard...');
    }
    if (_error != null && _data == null) {
      return ContentErrorState(
        message: _error is ApiException
            ? (_error! as ApiException).message
            : 'Dashboard could not be loaded.',
        onRetry: () => _load(forceRefresh: true),
      );
    }

    final data = _data!;
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        children: [
          if (_showingStaleData) ...[
            _staleBanner(),
            const SizedBox(height: 14),
          ],
          _header(data),
          const SizedBox(height: 20),
          _wallet(data),
          const SizedBox(height: 18),
          _metrics(data),
          const SizedBox(height: 22),
          _recentPurchases(data),
          const SizedBox(height: 22),
          _quickActions(),
        ],
      ),
    );
  }

  Widget _header(DashboardData data) {
    final theme = Theme.of(context);
    final role = data.role.trim().isEmpty ? 'Partner' : data.role.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Welcome back, ${_friendlyRole(role)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          badge: true,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: B2BGradients.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: B2BShadows.card,
            ),
            child: Text(
              role.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _friendlyRole(String role) {
    final value = role.toLowerCase();
    if (value.contains('admin')) return 'Admin';
    if (value.contains('dealer')) return 'Dealer';
    if (value.contains('reseller')) return 'Reseller';
    if (value.contains('client')) return 'Client';
    return role;
  }

  Widget _wallet(DashboardData data) {
    final currency = data.currency.trim().isEmpty ? 'USD' : data.currency;
    final balance = _balanceVisible
        ? _money(data.balance, currency)
        : '••••••••';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: B2BGradients.primary,
        borderRadius: BorderRadius.circular(B2BRadius.xxl),
        boxShadow: B2BShadows.hero,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -52,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            left: 90,
            bottom: -95,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 24,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Wallet balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _balanceVisible = !_balanceVisible),
                    icon: Icon(
                      _balanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                balance,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.05,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available for new eSIM orders',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .70),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push('/wallet'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 46),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('Add funds'),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      currency,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metrics(DashboardData data) {
    final items = [
      _MetricData(
        'Today sales',
        _money(data.todaySales, data.currency),
        Icons.trending_up_rounded,
        AppColors.primary,
        AppColors.primaryLight,
      ),
      _MetricData(
        'Monthly sales',
        _money(data.monthlySales, data.currency),
        Icons.calendar_month_rounded,
        AppColors.sky,
        const Color(0xFFEAF7FE),
      ),
      _MetricData(
        'Active eSIMs',
        '${data.activeEsimCount}',
        Icons.sim_card_rounded,
        AppColors.success,
        AppColors.successSoft,
      ),
      _MetricData(
        'Expired eSIMs',
        '${data.expiredEsimCount}',
        Icons.schedule_rounded,
        AppColors.warning,
        AppColors.warningSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final item in items) SizedBox(width: width, child: _metricCard(item))],
        );
      },
    );
  }

  Widget _metricCard(_MetricData item) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(height: 16),
          Text(item.label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 5),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 19),
          ),
        ],
      ),
    );
  }

  Widget _recentPurchases(DashboardData data) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
            child: Row(
              children: [
                Expanded(child: Text('Recent purchases', style: theme.textTheme.titleLarge)),
                TextButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          if (data.recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your latest eSIM purchases will appear here.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < data.recentOrders.take(4).length; i++) ...[
              _orderRow(data.recentOrders[i], data.currency),
              if (i != data.recentOrders.take(4).length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
            ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _orderRow(DashboardOrderSummary order, String currency) {
    final theme = Theme.of(context);
    final completed = order.status.toLowerCase().contains('complete') ||
        order.status.toLowerCase().contains('success');
    final date = order.createdAt == null
        ? 'Recent'
        : DateFormat('MMM d • HH:mm').format(order.createdAt!.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.public_rounded, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(order.totalAmount, currency),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    completed ? 'Completed' : order.status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: completed ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final actions = <_ActionData>[
      _ActionData('Buy eSIM', Icons.shopping_bag_outlined, AppColors.violet, () => context.go('/packages')),
      _ActionData('My eSIMs', Icons.sim_card_outlined, AppColors.sky, () => context.go('/esims')),
      _ActionData('Add funds', Icons.add_card_rounded, AppColors.success, () => context.push('/wallet')),
      _ActionData('Orders', Icons.swap_horiz_rounded, AppColors.orange, () => context.go('/orders')),
      _ActionData('NekoKopla', Icons.qr_code_2_rounded, AppColors.navy, _openNekoKopla),
    ];

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(B2BRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light ? B2BShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                Expanded(child: _actionTile(actions[i])),
                if (i != actions.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionTile(_ActionData action) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(B2BRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNekoKopla() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      _message('NekoKopla is available on Android devices.');
      return;
    }

    try {
      await _channel.invokeMethod<void>('openNekoko');
    } on PlatformException catch (error) {
      _message(error.message ?? 'NekoKopla could not be opened.');
    } catch (_) {
      _message('NekoKopla could not be opened.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _staleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(B2BRadius.md),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.warning),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Could not refresh. Showing the latest available data.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value, String currency) {
    final code = currency.trim().isEmpty ? 'USD' : currency.trim().toUpperCase();
    final symbol = switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      'TRY' => '₺',
      _ => '$code ',
    };
    return '$symbol${NumberFormat('#,##0.00').format(value)}';
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap, this.badge = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
        ),
        if (badge)
          Positioned(
            right: 7,
            top: 7,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color, this.soft);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;
}

class _ActionData {
  const _ActionData(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
