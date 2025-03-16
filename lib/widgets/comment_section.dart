import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:unibuzz_community/services/feed_service.dart';
import 'package:unibuzz_community/services/auth_service.dart';  // Add this import
import 'package:unibuzz_community/widgets/user_avatar.dart';  // Add this import

class CommentSection extends StatelessWidget {
  final String postId;
  final ScrollController? scrollController;  // Add this parameter

  const CommentSection({
    super.key, 
    required this.postId,
    this.scrollController,  // Add this parameter
  });

  @override
  Widget build(BuildContext context) {  // Get context from build method
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final comments = snapshot.data?.docs ?? [];

              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No comments yet'),
                );
              }

              return ListView.builder(
                controller: scrollController,  // Add this line
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildCommentItem(context, comment),  // Pass context to helper method
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: _CommentInput(postId: postId),
        ),
      ],
    );
  }

  Widget _buildCommentItem(BuildContext context, Map<String, dynamic> comment) {  // Accept context as parameter
    return ListTile(
      leading: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          '/profile/:userId',
          arguments: comment['userId'],
        ),
        child: UserAvatar(userId: comment['userId']),
      ),
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/profile/:userId',
              arguments: comment['userId'],
            ),
            child: FutureBuilder<String>(
              future: FeedService().getUserName(comment['userId']),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Loading...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeago.format(
              (comment['createdAt'] as Timestamp).toDate(),
              locale: 'en_short',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      subtitle: Text(comment['content']),
    );
  }
}

class _CommentInput extends StatefulWidget {
  final String postId;

  const _CommentInput({required this.postId});

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      final currentUser = AuthService().currentUser;  // Now this will work
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // First read the post document
        final postDoc = await transaction.get(postRef);
        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        // Then create the comment
        final commentRef = postRef.collection('comments').doc();
        transaction.set(commentRef, {
          'content': _commentController.text,
          'userId': currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Finally update the post's comment count
        transaction.update(postRef, {
          'commentCount': (postDoc.data()?['commentCount'] ?? 0) + 1,
        });
      });

      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: _isSubmitting
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            onPressed: _isSubmitting ? null : _submitComment,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
