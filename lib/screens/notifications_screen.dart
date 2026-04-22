import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const String routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<UserProvider>().notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(item.title),
              subtitle: Text(
                '${item.message}\n${DateFormat('d MMM, hh:mm a').format(item.timestamp)}',
              ),
            ),
          );
        },
      ),
    );
  }
}
