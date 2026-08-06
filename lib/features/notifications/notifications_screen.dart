import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
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
    final updated = item.copyWith(isRead: !item.isRead, readAt: item.isRead ? null : DateTime.now());
    setState(() {
      final next = [..._items];
      next[index] = updated;
      _items = next;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification status could not be updated.')),
      );
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || !_items.any((item) => !item.isRead)) return;
    final previous = _items;
    setState(() {
      _markingAll = true;
      _items = _items.map((item) => item.copyWith(isRead: true, readAt: DateTime.now())).toList();
    });
    try {
      await _repository.markAllRead();
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications could not be marked as read.')),
      );
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _loading || _markingAll ? null : _markAllRead,
            child: _markingAll
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Mark all read'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 160),
            Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('You are all caught up', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text('New operational updates will appear here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final today = <MobileNotificationItem>[];
    final earlier = <MobileNotificationItem>[];
    final now = DateTime.now();
    for (final item in _items) {
      final date = item.createdAt?.toLocal();
      if (date != null && date.year == now.year && date.month == now.month && date.day == now.day) {
        today.add(item);
      } else {
        earlier.add(item);
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (today.isNotEmpty) ...[
            const _SectionLabel('Today'),
            const SizedBox(height: 10),
            ..._tiles(today),
          ],
          if (earlier.isNotEmpty) ...[
            if (today.isNotEmpty) const SizedBox(height: 20),
            const _SectionLabel('Earlier'),
            const SizedBox(height: 10),
            ..._tiles(earlier),
          ],
        ],
      ),
    );
  }

  List<Widget> _tiles(List<MobileNotificationItem> items) {
    return [
      for (var index = 0; index < items.length; index++) ...[
        _NotificationTile(item: items[index], onTap: () => _toggle(items[index])),
        if (index != items.length - 1) const SizedBox(height: 10),
      ],
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900));
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final MobileNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(item.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: item.isRead ? AppColors.border : AppColors.primary.withOpacity(.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(color: visual.$2.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
              child: Icon(visual.$1, color: visual.$2),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900))),
                    if (!item.isRead) Container(height: 8, width: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 5),
                  Text(item.message, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(_timeLabel(item.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
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
