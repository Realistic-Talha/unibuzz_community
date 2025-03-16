import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/post_model.dart';
import 'package:unibuzz_community/widgets/post_card.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';  // Add this import
import 'package:unibuzz_community/services/feed_service.dart';  // Add this if needed for username/email

class PostSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.length < 2) {
      return const Center(
        child: Text('Enter at least 2 characters to search'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs
            .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((post) =>
                post.content.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (posts.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            
            // Get user info from FeedService
            return FutureBuilder<Map<String, dynamic>>(
              future: FeedService().getUserInfo(post.userId),
              builder: (context, userSnapshot) {
                final username = userSnapshot.data?['username'] ?? 'Unknown';
                final email = userSnapshot.data?['email'] ?? '';
                
                return Column(
                  children: [
                    ListTile(
                      leading: UserAvatar(userId: post.userId),
                      title: Text(username),
                      subtitle: Text(email),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/profile/:userId',
                          arguments: post.userId,
                        );
                      },
                    ),
                    PostCard(post: post),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
