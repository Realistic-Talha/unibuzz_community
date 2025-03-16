import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/post_model.dart';
import 'package:unibuzz_community/services/feed_service.dart';
import 'package:unibuzz_community/widgets/post_card.dart';
import 'package:unibuzz_community/widgets/create_post_dialog.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with title and filter button
      appBar: AppBar(
        title: const Text('UniBuzz Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality will be added here
            },
          ),
        ],
      ),

      // Main feed using StreamBuilder to get real-time posts
      body: StreamBuilder<QuerySnapshot>(
        stream: FeedService().getPostsStream(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Convert documents to Post objects
          final posts = snapshot.data?.docs.map((doc) {
            return Post.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList() ?? [];

          // Display posts in a scrollable list
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),

      // Floating action button to create new posts
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreatePostDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
