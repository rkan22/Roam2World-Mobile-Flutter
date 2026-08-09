import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
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
  static const _primary = Color(0xFF0868F7);
  static const _background = Color(0xFFF7F9FC);
  static const _text = Color(0xFF0C1733);
  static const _muted = Color(0xFF758097);
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
      backgroundColor: _background,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const ContentLoadingState(label: 'Loading your workspace...');
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
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          if (_showingStaleData) ...[
            _staleBanner(),
            const SizedBox(height: 12),
          ],
          _header(data),
          const SizedBox(height: 22),
          _walletCard(data),
          const SizedBox(height: 18),
          _metricsGrid(data),
          const SizedBox(height: 20),
          _recentPurchases(data),
          const SizedBox(height: 18),
          _quickActions(),
        ],
      ),
    );
  }

  Widget _header(DashboardData data) {
    final role = data.role.trim().isEmpty ? 'Partner' : data.role.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Admin 👋',
                style: TextStyle(
                  color: _text,
                  fontSize: 29,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                role,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none_rounded, size: 30),
              color: _text,
            ),
            Positioned(
              right: 9,
              top: 8,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(99),
          child: const CircleAvatar(
            radius: 25,
            backgroundColor: _primary,
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down_rounded, color: _text),
      ],
    );
  }

  Widget _walletCard(DashboardData data) {
    final amount = '${data.currency} ${data.balance.toStringAsFixed(2)}';
    return _surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _iconBox(
                icon: Icons.account_balance_wallet_rounded,
                foreground: _primary,
                background: const Color(0xFFEAF2FF),
                size: 58,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _balanceVisible ? amount : '••••••••',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 36,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () => setState(() => _balanceVisible = !_balanceVisible),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F5FF),
                  foregroundColor: _primary,
                  minimumSize: const Size(52, 52),
                ),
                icon: Icon(
                  _balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE8EDF5)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => context.push('/wallet'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 19),
              label: const Text(
                'Add Money',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid(DashboardData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.trending_up_rounded,
                iconColor: _primary,
                iconBackground: const Color(0xFFEDF4FF),
                label: 'Today Sales',
                value: '${data.currency} ${_compactMoney(data.todaySales)}',
                badge: 'Live',
                badgeColor: _primary,
                badgeBackground: const Color(0xFFF4F8FF),
              ),
            ),
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.calendar_month_rounded,
                iconColor: _primary,
                iconBackground: const Color(0xFFEDF4FF),
                label: 'Monthly Sales',
                value: '${data.currency} ${_compactMoney(data.monthlySales)}',
                badge: 'This month',
                badgeColor: _primary,
                badgeBackground: const Color(0xFFF4F8FF),
              ),
            ),
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.sim_card_outlined,
                iconColor: const Color(0xFF0BB77A),
                iconBackground: const Color(0xFFECFBF5),
                label: 'Active eSIMs',
                value: '${data.activeEsimCount}',
                badge: 'Active',
                badgeColor: const Color(0xFF0AAE73),
                badgeBackground: const Color(0xFFECFBF5),
                onTap: () => context.go('/esims'),
              ),
            ),
            SizedBox(
              width: width,
              child: _metricCard(
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFFFF7A00),
                iconBackground: const Color(0xFFFFF4E8),
                label: 'Expired eSIMs',
                value: '${data.expiredEsimCount}',
                badge: 'Needs attention',
                badgeColor: const Color(0xFFF27900),
                badgeBackground: const Color(0xFFFFF5E9),
                onTap: () => context.go('/esims'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required String value,
    required String badge,
    required Color badgeColor,
    required Color badgeBackground,
    VoidCallback? onTap,
  }) {
    return _surface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconCircle(icon, iconColor, iconBackground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: .14)),
                  ),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
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

  Widget _recentPurchases(DashboardData data) {
    return _surface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Purchases',
                  style: TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (data.recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  _iconCircle(
                    Icons.receipt_long_outlined,
                    _primary,
                    const Color(0xFFEDF4FF),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Your latest eSIM purchases will appear here.',
                      style: TextStyle(color: _muted, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final order in data.recentOrders.take(2)) ...[
              _purchaseRow(order, data.currency),
              if (order != data.recentOrders.take(2).last)
                const Divider(height: 1, color: Color(0xFFE8EDF5)),
            ],
        ],
      ),
    );
  }

  Widget _purchaseRow(DashboardOrderSummary order, String currency) {
    final date = order.createdAt == null
        ? ''
        : DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt!.toLocal());
    final completed = order.status.toLowerCase() == 'completed' ||
        order.status.toLowerCase() == 'success';
    final statusColor = completed ? const Color(0xFF0AAE73) : const Color(0xFFF27900);
    final statusBg = completed ? const Color(0xFFECFBF5) : const Color(0xFFFFF5E9);

    return InkWell(
      onTap: () => context.go('/orders'),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _iconCircle(
              Icons.business_rounded,
              const Color(0xFF7EA9EF),
              const Color(0xFFF0F5FF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productName.isEmpty ? 'eSIM purchase' : order.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.orderNumber.isEmpty ? 'Roam2World order' : order.orderNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12.5),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(date, style: const TextStyle(color: _muted, fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency ${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.isEmpty ? 'Pending' : _titleCase(order.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    final actions = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.shopping_cart_rounded,
        label: 'Buy eSIM',
        onTap: () => context.go('/packages'),
      ),
      (
        icon: Icons.qr_code_2_rounded,
        label: 'NekoKopla',
        onTap: _openNekoko,
      ),
      (
        icon: Icons.history_rounded,
        label: 'eSIM History',
        onTap: () => context.go('/esims'),
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        label: 'Wallet Request',
        onTap: () => context.go('/wallet'),
      ),
      (
        icon: Icons.sim_card_rounded,
        label: 'TGT SIM Recharge',
        onTap: () => _showMessage('TGT SIM Recharge is not configured yet.'),
      ),
    ];

    return _surface(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final tileWidth = (constraints.maxWidth - (gap * 4)) / 5;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    SizedBox(
                      width: tileWidth,
                      child: _quickActionTile(actions[i]),
                    ),
                    if (i != actions.length - 1) const SizedBox(width: gap),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile(({IconData icon, String label, VoidCallback onTap}) action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 106),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4EAF3)),
        ),
        child: Column(
          children: [
            Icon(action.icon, color: _primary, size: 29),
            const SizedBox(height: 10),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 10.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNekoko() async {
    try {
      await _channel.invokeMethod<void>('openNekoko');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'NekoKopla could not be opened.');
    } on MissingPluginException {
      _showMessage('NekoKopla launcher is available on Android.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _staleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFF27900), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing the latest saved dashboard data.',
              style: TextStyle(color: Color(0xFF9A5B00), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0B1F3A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: content);
  }

  Widget _iconBox({
    required IconData icon,
    required Color foreground,
    required Color background,
    double size = 54,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: foreground, size: 29),
    );
  }

  Widget _iconCircle(IconData icon, Color foreground, Color background) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 27),
    );
  }

  String _compactMoney(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return NumberFormat('#,##0').format(value);
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _titleCase(String value) {
    final clean = value.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return clean;
    return clean
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }
}
