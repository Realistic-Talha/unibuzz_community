import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/widgets/post_card.dart';
import 'package:unibuzz_community/models/post_model.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';
import 'package:unibuzz_community/services/feed_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Add categories list
  final List<String> _categories = [
    'Trending',
    'Events',
    'Lost & Found',
    'Academic'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users or posts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Posts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersSearch(),
                _buildPostsSearch(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSearch() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text('Type to search users...'),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .orderBy('username')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs.where((doc) {
          final userData = doc.data() as Map<String, dynamic>;
          final username = (userData['username'] ?? '').toString().toLowerCase();
          final email = (userData['email'] ?? '').toString().toLowerCase();
          final searchTerm = _searchController.text.toLowerCase();
          
          return username.contains(searchTerm) || 
                 email.contains(searchTerm);
        }).toList();
        
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No users found matching "${_searchController.text}"',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            
            return ListTile(
              leading: UserAvatar(userId: userId),
              title: Text(userData['username'] ?? 'Unknown User'),
              subtitle: Text(userData['bio'] ?? 'No bio available'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profile/:userId',
                  arguments: userId,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPostsSearch() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text('Type to search posts...'),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs.where((doc) {
          final postData = doc.data() as Map<String, dynamic>;
          final content = (postData['content'] ?? '').toString().toLowerCase();
          final searchTerm = _searchController.text.toLowerCase();
          
          return content.contains(searchTerm);
        }).map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No posts found matching "${_searchController.text}"',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}

class _TrendingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('likes', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs.map((doc) {
          return Post.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}

class _EventsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('dateTime', isGreaterThan: DateTime.now())
          .orderBy('dateTime')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final event = snapshot.data!.docs[index];
            return ListTile(
              title: Text(event['title']),
              subtitle: Text(event['description']),
              onTap: () {
                Navigator.pushNamed(context, '/event-details', arguments: event.id);
              },
            );
          },
        );
      },
    );
  }
}

class _LostFoundTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lost_items')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final item = snapshot.data!.docs[index];
            return ListTile(
              title: Text(item['title']),
              subtitle: Text(item['description']),
              leading: item['imageUrl'] != null
                  ? Image.network(item['imageUrl'])
                  : const Icon(Icons.search),
              onTap: () {
                Navigator.pushNamed(context, '/item-details', arguments: item.id);
              },
            );
          },
        );
      },
    );
  }
}

class _AcademicTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('category', isEqualTo: 'Academic')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs.map((doc) {
          return Post.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}
