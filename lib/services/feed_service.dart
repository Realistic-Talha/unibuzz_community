import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:unibuzz_community/services/image_hosting_service.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageHostingService _imageHosting = ImageHostingService();

  Stream<QuerySnapshot> getPostsStream({String? category}) {
    Query query = _firestore.collection('posts')
        .orderBy('createdAt', descending: true);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots();
  }

  Future<void> createPost(
    String content, 
    String category, {
    String? imageUrl,  // Only accept image URL, not File
  }) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (imageUrl != null && !imageUrl.startsWith('http')) {
      debugPrint('Invalid image URL detected: $imageUrl');
      throw Exception('Invalid image URL');
    }

    final postData = {
      'userId': user.uid,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
      'commentCount': 0,
    };

    debugPrint('Creating post with data: $postData');
    await _firestore.collection('posts').add(postData);
  }

  Future<void> toggleLike(String postId) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    final postRef = _firestore.collection('posts').doc(postId);
    final post = await postRef.get();
    
    if (post.exists) {
      final likes = List<String>.from(post.data()?['likes'] ?? []);
      if (likes.contains(user.uid)) {
        likes.remove(user.uid);
      } else {
        likes.add(user.uid);
      }
      await postRef.update({'likes': likes});
    }
  }

  Future<String> getUserName(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['username'] ?? 'Unknown User';
  }

  Future<void> addComment(String postId, String content) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('User not authenticated');

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments');

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      // Add comment
      transaction.set(commentRef.doc(), {
        'userId': user.uid,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update comment count
      final postSnap = await transaction.get(postRef);
      final currentCount = postSnap.data()?['commentCount'] ?? 0;
      transaction.update(postRef, {'commentCount': currentCount + 1});
    });
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPosts(String userId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (!userDoc.exists) {
      return {
        'username': 'Unknown User',
        'email': '',
        'profileImageUrl': null,
      };
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    return {
      'username': userData['username'] ?? 'Unknown User',
      'email': userData['email'] ?? '',
      'profileImageUrl': userData['profileImageUrl'],
    };
  }

  Stream<QuerySnapshot> searchUsers(String query) {
    if (query.length < 2) return const Stream.empty();
    
    return FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '${query}z')
        .limit(20)
        .snapshots();
  }
}
