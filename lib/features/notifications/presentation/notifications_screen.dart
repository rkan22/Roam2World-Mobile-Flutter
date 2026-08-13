import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No notifications')),
          ],
        ),
      ),
    );
  }
}
