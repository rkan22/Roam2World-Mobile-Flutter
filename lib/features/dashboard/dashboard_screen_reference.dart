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
  const DashboardScreen({
    super.key,
    this.repository,
    this.allowDemoFallback = true,
  });

  final DashboardRepository? repository;
  final bool allowDemoFallback;

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
      final result = await _repository.fetchDashboard(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _data = result;
        _showingStaleData = _repository.lastFetchUsedStale;
      });
    } catch (error) {
      if (!mounted) return;
      if (kDebugMode && widget.allowDemoFallback) {
        setState(() {
          _data = _demoData;
          _error = null;
          _showingStaleData = true;
        });
      } else {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DashboardData get _demoData => DashboardData(
    role: 'Reseller',
    balance: 12540,
    currency: 'USD',
    todaySales: 8760.50,
    monthlySales: 98760.50,
    totalEsimCount: 1290,
    activeEsimCount: 1248,
    expiredEsimCount: 42,
    recentOrders: [
      DashboardOrderSummary(
        id: 1,
        orderNumber: 'R2W-1042',
        productName: 'United States • 10 GB • 30 Days',
        status: 'completed',
        totalAmount: 23.09,
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      DashboardOrderSummary(
        id: 2,
        orderNumber: 'R2W-1041',
        productName: 'Türkiye • 20 GB • 30 Days',
        status: 'completed',
        totalAmount: 25.08,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      DashboardOrderSummary(
        id: 3,
        orderNumber: 'R2W-1040',
        productName: 'Japan • 5 GB • 15 Days',
        status: 'completed',
        totalAmount: 12.50,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(child: _buildBody()),
  );

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
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          if (_showingStaleData) ...[
            _staleBanner(),
            const SizedBox(height: 12),
          ],
          _header(data),
          const SizedBox(height: 18),
          _walletHero(data),
          const SizedBox(height: 14),
          _metricStrip(data),
          const SizedBox(height: 14),
          _recentOrders(data),
          const SizedBox(height: 14),
          _quickActions(),
        ],
      ),
    );
  }

  Widget _header(DashboardData data) {
    final role = _friendlyRole(data.role);
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.menu_rounded,
          onTap: () => context.push('/profile'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, $role',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Here’s what’s happening with your business today.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _SquareIconButton(
          icon: Icons.notifications_none_rounded,
          badge: true,
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              role.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _walletHero(DashboardData data) {
    final currency = data.currency.trim().isEmpty ? 'USD' : data.currency;
    final balance = _balanceVisible
        ? _money(data.balance, currency)
        : '••••••••';
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.heroStart,
            AppColors.heroMiddle,
            AppColors.heroEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: B2BShadows.hero,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -54,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 8,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 105,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                balance,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  height: 1,
                                  letterSpacing: -0.8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              currency,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            balance,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 38,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/wallet'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 17),
                          label: const Text('Add Funds'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 102,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A24),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.public_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Roam2World',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                onPressed: () => setState(
                                  () => _balanceVisible = !_balanceVisible,
                                ),
                                icon: Icon(
                                  _balanceVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'B2B WALLET',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              letterSpacing: .9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Secure partner balance',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricStrip(DashboardData data) {
    final metrics = [
      _MetricData(
        label: 'Total Sales',
        value: _money(data.monthlySales, data.currency),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.primary,
        soft: AppColors.primaryLight,
      ),
      _MetricData(
        label: 'Total eSIMs',
        value: '${data.totalEsimCount}',
        icon: Icons.sim_card_outlined,
        color: AppColors.sky,
        soft: const Color(0xFFEAF7FE),
      ),
      _MetricData(
        label: 'Active eSIMs',
        value: '${data.activeEsimCount}',
        icon: Icons.groups_2_outlined,
        color: AppColors.success,
        soft: AppColors.successSoft,
      ),
      _MetricData(
        label: 'Expired',
        value: '${data.expiredEsimCount}',
        icon: Icons.pie_chart_outline_rounded,
        color: AppColors.warning,
        soft: AppColors.warningSoft,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) => _metricCard(metrics[index]),
    );
  }

  Widget _metricCard(_MetricData metric) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: B2BShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: metric.soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, size: 16, color: metric.color),
          ),
          const Spacer(),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 3),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _metricCaption(metric.label),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 9.5,
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _metricCaption(String label) {
    if (label == 'Expired') return 'Live status';
    if (label == 'Active eSIMs') return 'In service';
    return 'Updated now';
  }

  Widget _recentOrders(DashboardData data) {
    final theme = Theme.of(context);
    final orders = data.recentOrders.take(4).toList(growable: false);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: B2BShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Orders',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Text(
                'Your latest eSIM orders will appear here.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            for (var i = 0; i < orders.length; i++) ...[
              _orderRow(orders[i], data.currency),
              if (i != orders.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
            ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _orderRow(DashboardOrderSummary order, String currency) {
    final theme = Theme.of(context);
    final completed =
        order.status.toLowerCase().contains('complete') ||
        order.status.toLowerCase().contains('success');
    final date = order.createdAt == null
        ? order.orderNumber
        : DateFormat('MMM d, HH:mm').format(order.createdAt!.toLocal());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.public_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(order.totalAmount, currency),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    completed ? 'Completed' : order.status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9.5,
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
      _ActionData(
        label: 'Buy eSIM',
        icon: Icons.shopping_bag_outlined,
        color: AppColors.primary,
        onTap: () => context.go('/packages'),
      ),
      _ActionData(
        label: 'My eSIMs',
        icon: Icons.sim_card_outlined,
        color: AppColors.sky,
        onTap: () => context.go('/esims'),
      ),
      _ActionData(
        label: 'Add Funds',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
        onTap: () => context.push('/wallet'),
      ),
      _ActionData(
        label: 'Orders',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.orange,
        onTap: () => context.go('/orders'),
      ),
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        _ActionData(
          label: 'NekoKopla',
          icon: Icons.qr_code_2_rounded,
          color: AppColors.navy,
          onTap: _openNekoKopla,
        ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: B2BShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                Expanded(child: _actionItem(actions[i])),
                if (i != actions.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionItem(_ActionData action) => InkWell(
    onTap: action.onTap,
    borderRadius: BorderRadius.circular(14),
    child: Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: action.color.withValues(alpha: .10)),
          ),
          child: Center(
            child: Icon(action.icon, color: action.color, size: 21),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          action.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Future<void> _openNekoKopla() async {
    try {
      await _channel.invokeMethod<void>('openNekoko');
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showMessage(error.message ?? 'NekoKopla could not be opened.');
    } on MissingPluginException {
      if (!mounted) return;
      _showMessage('NekoKopla is available on supported Android devices.');
    }
  }

  Widget _staleBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.warning.withValues(alpha: .25)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: AppColors.warning,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            kDebugMode && widget.allowDemoFallback
                ? 'Preview data is shown while dashboard API access is unavailable.'
                : 'Showing the last available dashboard data.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyRole(String role) {
    final value = role.trim();
    if (value.isEmpty) return 'Partner';
    final lower = value.toLowerCase();
    if (lower.contains('admin')) return 'Admin';
    if (lower.contains('dealer')) return 'Dealer';
    if (lower.contains('reseller')) return 'Reseller';
    if (lower.contains('client')) return 'Client';
    return value;
  }

  String _money(double value, String currency) {
    final normalized = currency.trim().toUpperCase();
    final symbol = switch (normalized) {
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'TRY' => '₺',
      _ => '$normalized ',
    };
    return '$symbol${NumberFormat('#,##0.00', 'en_US').format(value)}';
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
        if (badge)
          const Positioned(
            right: 4,
            top: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 7, height: 7),
            ),
          ),
      ],
    ),
  );
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.soft,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;
}

class _ActionData {
  const _ActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
