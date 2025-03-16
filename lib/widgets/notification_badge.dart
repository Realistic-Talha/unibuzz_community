import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: NotificationService().getNotifications(), // Changed from getNotificationsStream
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final unreadCount = snapshot.data?.docs
            .where((doc) => doc['isRead'] == false)
            .length ?? 0;

        if (unreadCount == 0) return const SizedBox();

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            shape: BoxShape.circle,
          ),
          constraints: const BoxConstraints(
            minWidth: 16,
            minHeight: 16,
          ),
          child: Text(
            unreadCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
