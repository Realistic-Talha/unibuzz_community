import 'package:flutter/material.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';
import 'package:unibuzz_community/services/presence_service.dart';

class UserAvatarWithStatus extends StatelessWidget {
  final String? imageUrl;
  final String? username;
  final String? userId;
  final double radius;

  const UserAvatarWithStatus({
    super.key,
    this.imageUrl,
    this.username,
    this.userId,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        UserAvatar(
          key: ValueKey(imageUrl), // Add a key to force rebuild when imageUrl changes
          imageUrl: imageUrl,
          username: username,
          radius: radius,
        ),
        if (userId != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: StreamBuilder<bool>(
              stream: PresenceService().getUserOnlineStatus(userId!),
              builder: (context, snapshot) {
                final isOnline = snapshot.data ?? false;
                return Container(
                  width: radius * 0.6,
                  height: radius * 0.6,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
