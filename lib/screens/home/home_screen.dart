import 'package:flutter/material.dart';
import 'package:unibuzz_community/screens/community_feed_screen.dart';
import 'package:unibuzz_community/screens/explore_screen.dart';
import 'package:unibuzz_community/screens/chat/chat_list_screen.dart';
import 'package:unibuzz_community/screens/profile/profile_screen.dart';
import 'package:unibuzz_community/widgets/search/post_search_delegate.dart';  // Add this import
import 'package:unibuzz_community/services/auth_service.dart';  // Add this import
import 'package:unibuzz_community/models/user_model.dart';  // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import
import 'package:cached_network_image/cached_network_image.dart';  // Add this import if not present
import 'package:unibuzz_community/widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const CommunityFeedScreen(),
    const ExploreScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    // Convert bottom nav index to screen index
    setState(() {
      if (index >= 2) {
        _currentIndex = index - 1;  // Adjust for FAB gap
      } else {
        _currentIndex = index;
      }
    });
  }

  void _openProfileMenu(BuildContext context) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    final userData = userDoc.data();
    if (userData == null || !context.mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('View Profile'),
            onTap: () => Navigator.pop(context, 'profile'),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context, 'settings'),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.pop(context, 'logout'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    switch (result) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'edit':
        final userModel = UserModel.fromMap(userData, user.uid);
        Navigator.pushNamed(
          context,
          '/edit-profile',
          arguments: userModel,
        );
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'logout':
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        break;
    }
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final user = AuthService().currentUser;
    
    return UserAccountsDrawerHeader(
      currentAccountPicture: UserAvatar(
        userId: user?.uid,
        radius: 30,
      ),
      accountName: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          return Text(userData?['username'] ?? 'User');
        },
      ),
      accountEmail: Text(user?.email ?? ''),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildProfileSection() {
    final user = AuthService().currentUser;
    return GestureDetector(
      onTap: () => _openProfileMenu(context),
      child: UserAvatar(userId: user?.uid),
    );
  }

  Widget _buildLoadingHeader(ColorScheme colorScheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: colorScheme.primaryContainer,
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: 12),
        Container(
          width: 100,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 150,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  // Add this function to get total unread messages
  Stream<int> _getTotalUnreadMessages() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[currentUser.uid] ?? 0;
        total += unreadCount as int;
      }
      return total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.background,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(context),  // Replace the old DrawerHeader
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Events'),
              onTap: () => Navigator.pushNamed(context, '/events'),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Lost & Found'),
              onTap: () => Navigator.pushNamed(context, '/lost-found'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(
                'Logout',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Text(
              'UniBUZZ',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search dialog instead of navigating
              showSearch(
                context: context,
                delegate: PostSearchDelegate(),
              );
            },
          ),
        ],
        backgroundColor: colorScheme.background,
        elevation: 0,
      ),
      body: _screens[_currentIndex],  // Use direct index since screens array matches actual indices
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none, // Add this to prevent button clipping
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: StreamBuilder<int>(
              stream: _getTotalUnreadMessages(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                
                return BottomAppBar(
                  elevation: 0,
                  color: colorScheme.background,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home')),
                        Expanded(child: _buildNavItem(1, Icons.explore_outlined, Icons.explore, 'Explore')),
                        const Expanded(child: SizedBox(width: 48)), // Space for center button
                        Expanded(
                          child: Stack(
                            children: [
                              _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 16,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.error,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(child: _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: -24, // Adjust this value to position button higher
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/create-post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.add, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    // Convert screen index to bottom nav index for highlighting
    final isSelected = index == (_currentIndex >= 2 ? _currentIndex + 1 : _currentIndex);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => _onTabTapped(index),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? colorScheme.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? colorScheme.primary : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}