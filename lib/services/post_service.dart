import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/auth_service.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final _firestore = FirebaseFirestore.instance;

  Future<void> createPost(Map<String, dynamic> postData) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final batch = _firestore.batch();
    
    // Add the post with user data
    final postRef = _firestore.collection('posts').doc();
    batch.set(postRef, {
      ...postData,
      'userId': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'id': postRef.id,  // Add post ID to the document
    });

    // Get current posts count
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    final currentCount = userDoc.data()?['postsCount'] ?? 0;

    // Update user's post count and posts array
    final userRef = _firestore.collection('users').doc(currentUser.uid);
    batch.update(userRef, {
      'postsCount': currentCount + 1,  // Increment existing count
      'posts': FieldValue.arrayUnion([postRef.id]),
    });

    await batch.commit();
  }

  Future<void> deletePost(String postId) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    final batch = _firestore.batch();
    
    // Delete the post
    final postRef = _firestore.collection('posts').doc(postId);
    batch.delete(postRef);

    // Decrement user's post count
    final userRef = _firestore.collection('users').doc(currentUser.uid);
    batch.update(userRef, {
      'postsCount': FieldValue.increment(-1),
      'posts': FieldValue.arrayRemove([postId]),
    });

    await batch.commit();
  }

  Future<void> updatePost(String postId, String content, String category) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) throw Exception('Not authenticated');

    await _firestore.collection('posts').doc(postId).update({
      'content': content,
      'category': category,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
