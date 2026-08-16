import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/notifications/push_notification_service.dart';
import '../../core/notifications/push_route_resolver.dart';
import '../../core/theme/app_colors.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'notification_data.dart';
import 'notifications_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsRepository _repository = NotificationsRepository();
  List<MobileNotificationItem> _items = const [];
  bool _loading = true;
  bool _markingAll = false;
  bool _unreadOnly = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchNotifications();
      if (!mounted) return;
      setState(() => _items = items);
      _syncUnreadCount();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Notifications could not be loaded.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(MobileNotificationItem item) async {
    final index = _items.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    final updated = item.copyWith(
      isRead: !item.isRead,
      readAt: item.isRead ? null : DateTime.now(),
    );
    setState(() {
      final next = [..._items];
      next[index] = updated;
      _items = next;
    });
    _syncUnreadCount();
    try {
      if (item.isRead) {
        await _repository.markUnread(item.id);
      } else {
        await _repository.markRead(item.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final next = [..._items];
        next[index] = item;
        _items = next;
      });
      _syncUnreadCount();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification status could not be updated.'),
        ),
      );
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || !_items.any((item) => !item.isRead)) return;
    final previous = _items;
    setState(() {
      _markingAll = true;
      _items = _items
          .map((item) => item.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
    });
    _syncUnreadCount();
    try {
      await _repository.markAllRead();
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = previous);
      _syncUnreadCount();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications could not be marked as read.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  void _syncUnreadCount() {
    mobileNotificationUnreadCount.value = _items
        .where((item) => !item.isRead)
        .length;
  }

  Future<void> _openNotification(MobileNotificationItem item) async {
    if (!item.isRead) await _toggle(item);
    if (!mounted) return;
    final data = <String, dynamic>{...item.metadata, 'type': item.type};
    context.go(resolvePushRoute(data));
  }

  List<MobileNotificationItem> get _visibleItems => _unreadOnly
      ? _items.where((item) => !item.isRead).toList(growable: false)
      : _items;

  @override
  Widget build(BuildContext context) {
    final unreadCount = _items.where((item) => !item.isRead).length;
    return Scaffold(body: SafeArea(child: _buildBody(unreadCount)));
  }

  Widget _buildBody(int unreadCount) {
    if (_loading) {
      return const ContentLoadingState(label: 'Loading notifications...');
    }
    if (_error != null) {
      return ContentErrorState(message: _error!, onRetry: _load);
    }

    final visible = _visibleItems;
    return RefreshIndicator(
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
          _PageHeader(
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            onRefresh: _load,
          ),
          const SizedBox(height: B2BSpacing.lg),
          _InboxHero(
            totalCount: _items.length,
            unreadCount: unreadCount,
            unreadOnly: _unreadOnly,
            markingAll: _markingAll,
            onUnreadToggle: () => setState(() => _unreadOnly = !_unreadOnly),
            onMarkAllRead: _markAllRead,
          ),
          const SizedBox(height: B2BSpacing.xl),
          if (visible.isEmpty)
            ContentEmptyState(
              icon: _unreadOnly
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_rounded,
              title: _unreadOnly
                  ? 'No unread notifications'
                  : 'You are all caught up',
              message: _unreadOnly
                  ? 'All operational updates have been reviewed.'
                  : 'New operational updates will appear here.',
              actionLabel: _unreadOnly ? 'Show all' : null,
              onAction: _unreadOnly
                  ? () => setState(() => _unreadOnly = false)
                  : null,
            )
          else
            ..._notificationSections(visible),
        ],
      ),
    );
  }

  List<Widget> _notificationSections(List<MobileNotificationItem> items) {
    final today = <MobileNotificationItem>[];
    final thisWeek = <MobileNotificationItem>[];
    final earlier = <MobileNotificationItem>[];
    final now = DateTime.now();

    for (final item in items) {
      final date = item.createdAt?.toLocal();
      if (date == null) {
        earlier.add(item);
        continue;
      }
      final difference = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(date.year, date.month, date.day)).inDays;
      if (difference == 0) {
        today.add(item);
      } else if (difference < 7) {
        thisWeek.add(item);
      } else {
        earlier.add(item);
      }
    }

    final widgets = <Widget>[];
    void addSection(String title, List<MobileNotificationItem> sectionItems) {
      if (sectionItems.isEmpty) return;
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: B2BSpacing.xl));
      }
      widgets
        ..add(_SectionLabel(title: title, count: sectionItems.length))
        ..add(const SizedBox(height: B2BSpacing.sm));
      for (var index = 0; index < sectionItems.length; index++) {
        widgets.add(
          _NotificationTile(
            item: sectionItems[index],
            onTap: () => _openNotification(sectionItems[index]),
            onToggle: () => _toggle(sectionItems[index]),
          ),
        );
        if (index != sectionItems.length - 1) {
          widgets.add(const SizedBox(height: B2BSpacing.sm));
        }
      }
    }

    addSection('Today', today);
    addSection('This week', thisWeek);
    addSection('Earlier', earlier);
    return widgets;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: B2BSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business inbox',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: B2BSpacing.xxs),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _InboxHero extends StatelessWidget {
  const _InboxHero({
    required this.totalCount,
    required this.unreadCount,
    required this.unreadOnly,
    required this.markingAll,
    required this.onUnreadToggle,
    required this.onMarkAllRead,
  });

  final int totalCount;
  final int unreadCount;
  final bool unreadOnly;
  final bool markingAll;
  final VoidCallback onUnreadToggle;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return B2BSurface(
      padding: const EdgeInsets.all(B2BSpacing.md),
      backgroundColor: AppColors.card,
      borderColor: AppColors.border,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: B2BSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unreadCount unread',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$totalCount operational updates',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: unreadOnly ? 'Show all' : 'Unread only',
            onPressed: onUnreadToggle,
            icon: Icon(
              unreadOnly
                  ? Icons.inbox_rounded
                  : Icons.mark_email_unread_outlined,
            ),
          ),
          TextButton.icon(
            onPressed: unreadCount == 0 || markingAll ? null : onMarkAllRead,
            icon: markingAll
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Read all'),
          ),
        ],
      ),
    );
    /* Legacy hero retained below for reference.
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(B2BRadius.md),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: B2BSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operational updates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: B2BSpacing.xxs),
                    Text(
                      '$unreadCount unread · $totalCount total',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(label: 'Unread', value: '$unreadCount'),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: _HeroMetric(label: 'Total', value: '$totalCount'),
              ),
            ],
          ),
          const SizedBox(height: B2BSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onUnreadToggle,
                  icon: Icon(
                    unreadOnly
                        ? Icons.inbox_rounded
                        : Icons.mark_email_unread_outlined,
                  ),
                  label: Text(unreadOnly ? 'Show all' : 'Unread only'),
                ),
              ),
              const SizedBox(width: B2BSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: .35),
                    ),
                  ),
                  onPressed: unreadCount == 0 || markingAll
                      ? null
                      : onMarkAllRead,
                  icon: markingAll
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.done_all_rounded, size: 19),
                  label: const Text('Mark all read'),
                ),
              ),
            ],
          ),
        ],
      ),
    ); */
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(B2BSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(B2BRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: B2BSpacing.xxs),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(B2BRadius.pill),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
    required this.onToggle,
  });

  final MobileNotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(item.type);
    return B2BSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(B2BSpacing.md),
      backgroundColor: item.isRead ? AppColors.card : AppColors.primaryLight,
      borderColor: item.isRead
          ? AppColors.border
          : AppColors.primary.withValues(alpha: .22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: visual.$2.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(B2BRadius.md),
            ),
            child: Icon(visual.$1, color: visual.$2),
          ),
          const SizedBox(width: B2BSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        height: 9,
                        width: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: B2BSpacing.xs),
                Text(
                  item.message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: B2BSpacing.sm),
                Row(
                  children: [
                    Text(
                      _timeLabel(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onToggle,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(item.isRead ? 'Mark unread' : 'Mark read'),
                    ),
                    const SizedBox(width: B2BSpacing.xs),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _visualFor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return (Icons.receipt_long_rounded, AppColors.success);
      case 'wallet':
        return (Icons.account_balance_wallet_rounded, AppColors.primary);
      case 'esim':
      case 'activation':
        return (Icons.sim_card_rounded, AppColors.warning);
      case 'system':
        return (Icons.settings_suggest_rounded, AppColors.primaryDark);
      default:
        return (Icons.notifications_rounded, AppColors.primaryDark);
    }
  }

  static String _timeLabel(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final difference = DateTime.now().difference(local);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }
}
