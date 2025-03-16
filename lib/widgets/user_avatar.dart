import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAvatar extends StatelessWidget {
  final String? userId;
  final String? imageUrl;
  final String? username;
  final double radius;

  const UserAvatar({
    super.key,
    this.userId,
    this.imageUrl,
    this.username,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (userId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final profileImageUrl = userData?['profileImageUrl'] as String?;
            final displayName = userData?['username'] as String?;
            
            return _buildAvatar(context, profileImageUrl, displayName);
          }
          return _buildAvatar(context, null, null);
        },
      );
    }

    return _buildAvatar(context, imageUrl, username);
  }

  void _handleImageError(String imageUrl) {
    debugPrint('Error loading avatar image: $imageUrl');
  }

  Widget _buildAvatar(BuildContext context, String? imageUrl, String? displayName) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        backgroundImage: CachedNetworkImageProvider(
          imageUrl,
          // Remove errorListener as it's causing type issues
          // We can handle errors through the errorWidget in CircleAvatar if needed
        ),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Error loading avatar image: $imageUrl - $exception');
        },
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: displayName != null && displayName.isNotEmpty
          ? Text(
              displayName[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: radius * 0.8,
              ),
            )
          : Icon(
              Icons.person,
              size: radius * 0.8,
              color: Theme.of(context).colorScheme.primary,
            ),    );  }}
