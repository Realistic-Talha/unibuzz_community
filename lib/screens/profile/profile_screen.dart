import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import
import 'package:cached_network_image/cached_network_image.dart';  // Add this import
import 'package:image_picker/image_picker.dart';  // Add this import
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/services/image_hosting_service.dart';
import 'package:unibuzz_community/widgets/profile_image_picker.dart';
import 'package:unibuzz_community/models/user_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:unibuzz_community/utils/image_utils.dart';
import 'package:unibuzz_community/services/post_service.dart';
import 'package:unibuzz_community/screens/profile/edit_profile_screen.dart';  // Add this import
import 'package:unibuzz_community/models/post_model.dart'; // Add this import
import 'package:unibuzz_community/widgets/post_card.dart'; // Add this import
import 'package:unibuzz_community/services/feed_service.dart'; // Add this import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _imageHosting = ImageHostingService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    AuthService().migrateUserPostCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateProfileImage(File imageFile) async {
    try {
      final imgurUrl = await _imageHosting.uploadImage(imageFile);
      debugPrint('Profile image uploaded to Imgur: $imgurUrl');
      
      // Update both profile URL and Firestore document
      await AuthService().updateProfile(
        photoUrl: imgurUrl,
        profileImageUrl: imgurUrl,  // Add this line
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e')),
        );
      }
    }
  }

  Future<void> _updateCoverPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (pickedFile == null) return;

    try {
      final imgurUrl = await _imageHosting.uploadImage(File(pickedFile.path));
      debugPrint('Cover photo uploaded to Imgur: $imgurUrl');
      
      await AuthService().updateProfile(coverPhotoUrl: imgurUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover photo updated')),
        );
      }
    } catch (e) {
      debugPrint('Error updating cover photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update cover photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Changed from background to surface
      body: StreamBuilder<UserModel?>(
        stream: AuthService().userModelStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final user = snapshot.data;
          if (user == null) return const Center(child: Text('User not found'));

          return CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Banner Image with gradient overlay
                    Container(
                      height: 240, // Increased height to accommodate button
                      decoration: BoxDecoration(
                        image: user.coverPhotoUrl != null && user.coverPhotoUrl!.startsWith('http')
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  user.coverPhotoUrl!,
                                ),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to load cover image'),
                                      ),
                                    );
                                  }
                                },
                              )
                            : null,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary.withOpacity(0.8),
                            colorScheme.primary,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 16,
                            top: 16,
                            child: Material(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _updateCoverPhoto,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: colorScheme.onPrimary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Change Cover',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Profile Image - Moved down in the Stack order
                    Positioned(
                      left: 20,
                      top: 120,
                      child: _buildProfileImage(user),
                    ),
                  ],
                ),
              ),

              // Profile Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), // Changed from 48 to 16
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.orange,
                            elevation: 4,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                debugPrint('Edit button tapped');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      userModel: user,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats Row with dividers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat(user.postsCount.toString(), 'Posts'),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          _buildStat(user.followers.length.toString(), 'Followers'),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          _buildStat(user.following.length.toString(), 'Following'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tabs
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: colorScheme.primary,
                    indicatorWeight: 3,
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

              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(theme),
                    _buildEventsTab(),
                    _buildPhotosTab(),
                    _buildAboutTab(theme),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 180,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildAboutTab(ThemeData theme) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().userModelStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final user = snapshot.data!;
        final colorScheme = theme.colorScheme;
        
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
                  if (user.gender != null)
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
              if (user.socialLinks.isNotEmpty)
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
                  _buildInfoTile(Icons.calendar_today, 'Joined', _formatDate(user.lastSeen)),
                ],
              ),
            ],
          ),
        );
      },
    );
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
          const Divider(height: 1),
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

  Widget _buildPostsTab(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FeedService().getPostsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final currentUserId = AuthService().currentUser?.uid;
        final userPosts = docs.where((doc) => 
          doc.get('userId') == currentUserId).toList();

        if (userPosts.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: userPosts.length,
          itemBuilder: (context, index) {
            final data = userPosts[index].data() as Map<String, dynamic>;
            return PostCard(post: Post.fromMap(data, userPosts[index].id));
          },
        );
      },
    );
  }

  void _showPostOptions(String postId) {
    final context = this.context; // Store context reference
    showModalBottomSheet(
      context: context,
      builder: (dialogContext) => Column( // Use dialogContext instead
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Post'),
            onTap: () async {
              Navigator.pop(dialogContext); // Use dialogContext
              try {
                await PostService().deletePost(postId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete post: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 4),
        Text(count),
      ],
    );
  }

  Widget _buildEventsTab() {
    return const Center(
      child: Text('No events yet'),
    );
  }

  Widget _buildPhotosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FeedService().getPostsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final currentUserId = AuthService().currentUser?.uid;
        final userPhotoPosts = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return doc.get('userId') == currentUserId && 
                 data['imageUrl'] != null && 
                 data['imageUrl'].toString().startsWith('http');
        }).toList();

        if (userPhotoPosts.isEmpty) {
          return const Center(child: Text('No photos yet'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: userPhotoPosts.length,
          itemBuilder: (context, index) {
            final data = userPhotoPosts[index].data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] as String;
            return GestureDetector(
              onTap: () => showImageViewer(
                context, 
                imageUrl,
                heroTag: 'photo_${userPhotoPosts[index].id}',
              ),
              child: Hero(
                tag: 'photo_${userPhotoPosts[index].id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileImage(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ProfileImagePicker(
        currentImageUrl: user.profileImageUrl, // Changed from photoUrl to profileImageUrl
        onImagePicked: _updateProfileImage,
        radius: 45,
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