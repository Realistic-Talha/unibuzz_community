import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/chat_model.dart';
import 'package:unibuzz_community/services/chat_service.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/screens/chat/chat_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:unibuzz_community/widgets/user_avatar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'Recent'];
  
  // Add new method to handle refresh
  Future<void> _handleRefresh() async {
    // Wait a moment to simulate refresh
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Force rebuild of the stream
    if (mounted) {
      setState(() {});
    }
  }

  void _startNewChat() async {
    final selectedUserId = await showSearch(
      context: context,
      delegate: ChatSearchDelegate(),
    );
    
    if (selectedUserId != null && selectedUserId.isNotEmpty && mounted) {
      final conversationId = await ChatService().createConversation([selectedUserId]);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(conversationId: conversationId),
          ),
        );
      }
    }
  }

  List<ChatConversation> _filterConversations(List<ChatConversation> conversations) {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return conversations;

    switch (_selectedFilter) {
      case 'Unread':
        return conversations.where((conv) {
          final unreadCount = conv.unreadCount[currentUserId] ?? 0;
          return unreadCount > 0;
        }).toList();
      case 'Recent':
        // Sort by most recent first (already handled by Firestore query)
        return conversations;
      case 'All':
      default:
        return conversations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: _selectedFilter == filter,
                    label: Text(filter),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: ChatService().getConversations(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final conversations = snapshot.data?.map((doc) {
                    return ChatConversation.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );
                  }).toList() ?? [];

                  final filteredConversations = _filterConversations(conversations);

                  if (filteredConversations.isEmpty) {
                    if (_selectedFilter == 'Unread') {
                      return const Center(
                        child: Text('No unread messages'),
                      );
                    }
                    return const Center(
                      child: Text('No conversations yet'),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(), // Important for refresh to work even when list is short
                    itemCount: filteredConversations.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];
                      return _ChatListTile(conversation: conversation);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        child: const Icon(Icons.message), // Use message icon
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatConversation conversation;

  const _ChatListTile({required this.conversation});

  void _showOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);
    final otherUserId = conversation.participants.firstWhere(
      (id) => id != ChatService().currentUser?.uid,
      orElse: () => '',
    );
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive Chat'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement archive functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Archive feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('Mute Notifications'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement mute functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mute feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Chat'),
              onTap: () async {
                Navigator.pop(context); // Close bottom sheet
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Chat'),
                    content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await ChatService().deleteConversation(conversation.id);
                    if (context.mounted) {
                      // Pop back to the chat list if we're in the chat detail screen
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting chat: $e')),
                      );
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog(context, otherUserId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context, String otherUserId) async {
    // Create a StateSetter variable to hold the setState function
    late StateSetter modalSetState;
    bool deleteChat = false;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            modalSetState = setModalState;  // Store setState function
            return AlertDialog(
              title: const Text('Block User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Are you sure you want to block this user?'),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: deleteChat,
                    onChanged: (bool? value) {
                      modalSetState(() {
                        deleteChat = value ?? false;
                      });
                    },
                    title: const Text('Delete chat history'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Block',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && context.mounted) {
      try {
        // First, block the user
        await AuthService().blockUser(otherUserId);

        // Then delete the chat if selected
        if (deleteChat) {
          await ChatService().deleteConversation(conversation.id);
        }

        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                deleteChat ? 'User blocked and chat deleted' : 'User blocked'
              ),
            ),
          );

          // Pop back to chat list if needed
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ChatService().currentUser?.uid;
    final unreadCount = currentUserId != null ? 
        (conversation.unreadCount[currentUserId] ?? 0) : 0;

    final otherUserId = conversation.participants.firstWhere(
      (id) => id != ChatService().currentUser?.uid,
      orElse: () => '',
    );

    return InkWell(
      onTap: () {
        // Remove the markAsRead call here and let ChatDetailScreen handle it
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(conversationId: conversation.id),
          ),
        );
      },
      onLongPress: () => _showOptionsMenu(context),
      child: ListTile(
        leading: UserAvatar(userId: otherUserId),
        title: FutureBuilder<String>(
          future: ChatService().getOtherParticipantName(conversation.participants),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Loading...');
          },
        ),
        subtitle: Text(
          conversation.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeago.format(conversation.lastMessageTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (unreadCount > 0)  // Fixed boolean condition
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unreadCount',  // Use the local variable
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  @override
  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Start typing to search users'),
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
          final searchTerm = query.toLowerCase();
          
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
                  'No users found matching "$query"',
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
              leading: CircleAvatar(
                backgroundImage: userData['photoUrl'] != null
                    ? NetworkImage(userData['photoUrl'])
                    : null,
                child: userData['photoUrl'] == null
                    ? Text((userData['username'] ?? '?')[0].toUpperCase())
                    : null,
              ),
              title: Text(userData['username'] ?? 'Unknown'),
              subtitle: Text(userData['email'] ?? ''),
              onTap: () => close(context, userId),
            );
          },
        );
      },
    );
  }
}
