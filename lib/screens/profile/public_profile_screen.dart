import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/user_model.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/services/feed_service.dart';
import 'package:unibuzz_community/widgets/post_card.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';
import 'package:unibuzz_community/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unibuzz_community/services/chat_service.dart';  // Add this import
import 'package:unibuzz_community/screens/chat/chat_detail_screen.dart';  // Add this import

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTab = _tabController.index);
    });
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (mounted) {
      setState(() {
        _isFollowing = (userDoc.data()?['following'] as List<dynamic>?)
            ?.contains(widget.userId) ?? false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users');
      final batch = FirebaseFirestore.instance.batch();

      if (_isFollowing) {
        batch.update(userRef.doc(currentUser.uid), {
          'following': FieldValue.arrayRemove([widget.userId])
        });
        batch.update(userRef.doc(widget.userId), {
          'followers': FieldValue.arrayRemove([currentUser.uid])
        });
      } else {
        batch.update(userRef.doc(currentUser.uid), {
          'following': FieldValue.arrayUnion([widget.userId])
        });
        batch.update(userRef.doc(widget.userId), {
          'followers': FieldValue.arrayUnion([currentUser.uid])
        });
      }

      await batch.commit();
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleMessageButtonPress(BuildContext context) async {
    try {
      // Get or create conversation with this user
      final conversationId = await ChatService().createOrGetConversation(widget.userId);
      
      if (!mounted) return;

      // Navigate to chat detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: conversationId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        final user = UserModel.fromMap(userData, snapshot.data!.id);

        return Scaffold(
          backgroundColor: colorScheme.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (user.coverPhotoUrl != null && 
                          user.coverPhotoUrl!.isNotEmpty && 
                          user.coverPhotoUrl!.startsWith('http'))
                        CachedNetworkImage(
                          imageUrl: user.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => _buildDefaultBackground(context),
                        )
                      else
                        _buildDefaultBackground(context),
                      // Add gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.block),
                              title: const Text('Block User'),
                              onTap: () {
                                // Implement block functionality
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.report),
                              title: const Text('Report User'),
                              onTap: () {
                                // Implement report functionality
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(userId: user.id, radius: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.bio ?? '',
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _toggleFollow,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _isFollowing ? Colors.transparent : colorScheme.primaryContainer,
                                side: _isFollowing ? BorderSide(color: colorScheme.outline) : BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(_isFollowing ? 'Following' : 'Follow'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleMessageButtonPress(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Message'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(user.postsCount.toString(), 'Posts'),
                          _buildStatDivider(),
                          _buildStat(user.followers.length.toString(), 'Followers'),
                          _buildStatDivider(),
                          _buildStat(user.following.length.toString(), 'Following'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Events'),
                      Tab(text: 'Photos'),
                      Tab(text: 'About'),
                    ],
                  ),
                ),
                pinned: true,
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(user.id),
                    _buildEventsTab(),
                    _buildPhotosTab(),
                    _buildAboutTab(user),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildPostsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FeedService().getUserPosts(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Post.fromMap(data, doc.id);
        }).toList();

        if (posts.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return const Center(child: Text('No events yet'));
  }

  Widget _buildPhotosTab() {
    return const Center(child: Text('No photos yet'));
  }

  Widget _buildAboutTab(UserModel user) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildInfoCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            color: Colors.blue,
            children: [
              if (user.gender != null && user.gender!.isNotEmpty)
                _buildInfoTile(Icons.people_outline, 'Gender', user.gender!),
              if (user.birthDate != null)
                _buildInfoTile(
                  Icons.cake_outlined,
                  'Birth Date',
                  _formatDate(user.birthDate!),
                ),
              if (user.bio?.isNotEmpty ?? false)
                _buildInfoTile(Icons.info_outline, 'Bio', user.bio!),
            ],
          ),
          const SizedBox(height: 16),
          
          // Contact Information Section
          _buildInfoCard(
            title: 'Contact Information',
            icon: Icons.contact_mail_outlined,
            color: Colors.green,
            children: [
              _buildInfoTile(Icons.email_outlined, 'Email', user.email),
              if (user.phone?.isNotEmpty ?? false)
                _buildInfoTile(Icons.phone_outlined, 'Phone', user.phone!),
              if (user.location?.isNotEmpty ?? false)
                _buildInfoTile(Icons.location_on_outlined, 'Location', user.location!),
              if (user.website?.isNotEmpty ?? false)
                _buildInfoTile(Icons.language_outlined, 'Website', user.website!),
            ],
          ),
          const SizedBox(height: 16),
          
          // Social Links Section
          if (_hasSocialLinks(user))
            _buildInfoCard(
              title: 'Social Links',
              icon: Icons.share_outlined,
              color: Colors.purple,
              children: [
                if (user.socialLinks['instagram']?.isNotEmpty ?? false)
                  _buildInfoTile(
                    Icons.camera_alt_outlined,
                    'Instagram',
                    user.socialLinks['instagram']!,
                    isLink: true,
                  ),
                if (user.socialLinks['linkedin']?.isNotEmpty ?? false)
                  _buildInfoTile(
                    Icons.work_outline,
                    'LinkedIn',
                    user.socialLinks['linkedin']!,
                    isLink: true,
                  ),
                if (user.socialLinks['github']?.isNotEmpty ?? false)
                  _buildInfoTile(
                    Icons.code,
                    'GitHub',
                    user.socialLinks['github']!,
                    isLink: true,
                  ),
              ],
            ),
          const SizedBox(height: 16),
          
          // Account Statistics Section
          _buildInfoCard(
            title: 'Account Statistics',
            icon: Icons.analytics_outlined,
            color: Colors.orange,
            children: [
              _buildInfoTile(Icons.post_add, 'Posts', user.postsCount.toString()),
              _buildInfoTile(Icons.people, 'Followers', user.followers.length.toString()),
              _buildInfoTile(Icons.person_add, 'Following', user.following.length.toString()),
              _buildInfoTile(Icons.calendar_today, 'Member Since', _formatDate(user.lastSeen)),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasSocialLinks(UserModel user) {
    return (user.socialLinks['instagram']?.isNotEmpty ?? false) ||
           (user.socialLinks['linkedin']?.isNotEmpty ?? false) ||
           (user.socialLinks['github']?.isNotEmpty ?? false);
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (children.isNotEmpty) const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {bool isLink = false}) {
    return ListTile(
      leading: Icon(icon, color: isLink ? Colors.blue : null),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: isLink ? Colors.blue : null,
          decoration: isLink ? TextDecoration.underline : null,
        ),
      ),
      dense: true,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDefaultBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        // Add subtle pattern overlay
        image: const DecorationImage(
          image: AssetImage('assets/patterns/subtle_dots.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.1,
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}