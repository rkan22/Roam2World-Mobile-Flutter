import 'package:flutter/material.dart';

import '../../features/notifications/notifications_repository.dart';

class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  final NotificationsRepository _repository = NotificationsRepository();

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repository.fetchNotifications();

      if (!mounted) return;

      setState(() {
        _unreadCount = items.where((item) => !item.isRead).length;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: widget.onTap,
      tooltip: 'Notifications',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (_unreadCount > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
