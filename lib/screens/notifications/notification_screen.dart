import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/notification_service.dart';
import 'package:unibuzz_community/screens/lost_found/item_details_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              // TODO: Implement clear all notifications
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService().getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  NotificationService().clearAll();
                },
                child: ListTile(
                  leading: _buildNotificationIcon(data['type']),
                  title: Text(_buildNotificationTitle(data)),
                  subtitle: Text(
                    timeago.format(
                      (data['createdAt'] as Timestamp).toDate(),
                    ),
                  ),
                  trailing: data['isRead']
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () {
                    NotificationService().markAsRead(notification.id);
                    _handleNotificationTap(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    switch (type) {
      case 'potential_match':
        return const CircleAvatar(
          child: Icon(Icons.search),
        );
      default:
        return const CircleAvatar(
          child: Icon(Icons.notifications),
        );
    }
  }

  String _buildNotificationTitle(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'potential_match':
        return 'Potential match found for your item! '
            '(${(data['matchScore'] * 100).toStringAsFixed(0)}% match)';
      default:
        return 'New notification';
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    switch (data['type']) {
      case 'potential_match':
        // Navigate to item details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(itemId: data['lostItemId']),
          ),
        );
        break;
      default:
        break;
    }
  }
}
