import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';  // Add this for debugPrint

class Post {
  final String id;
  final String userId;
  final String content;
  final String category;
  final String? imageUrl;  // Add single image support
  final List<String> images;  // Keep array for multiple images
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.category,
    this.imageUrl,  // Add this
    this.images = const [],
    this.likes = const [],
    this.commentCount = 0,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    // Validate imageUrl
    String? imageUrl = map['imageUrl'];
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      debugPrint('Invalid image URL found in post: $imageUrl');
      imageUrl = null;
    }

    DateTime? timestamp;
    try {
      final createdAtField = map['createdAt'];
      if (createdAtField != null) {
        if (createdAtField is Timestamp) {
          timestamp = createdAtField.toDate();
        }
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }

    return Post(
      id: id,
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'General',
      imageUrl: imageUrl,  // Add this
      images: List<String>.from(map['images'] ?? []),
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      createdAt: timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,  // Add this
      'images': images,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
