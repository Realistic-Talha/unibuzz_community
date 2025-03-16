import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/chat_model.dart';
import 'package:unibuzz_community/services/chat_service.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/services/presence_service.dart';
import 'package:unibuzz_community/widgets/chat_input.dart';
import 'dart:async';
import 'dart:io';
import 'package:unibuzz_community/widgets/chat_message_bubble.dart';  // Add this import
import 'package:unibuzz_community/widgets/user_avatar.dart';  // Add this import

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with WidgetsBindingObserver {
  bool _isTyping = false;
  Timer? _typingTimer;

  // Add these variables at the top of the class
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // Add a cache for blocked status
  bool? _isBlockedCache;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    // Set up periodic marking of messages as read
    _setupMessageReadTimer();
  }

  Timer? _readTimer;

  void _setupMessageReadTimer() {
    // Mark messages as read every 2 seconds while the chat is open
    _readTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        ChatService().markAsRead(widget.conversationId);
      }
    });
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  Future<void> _initializeChat() async {
    ChatService().markAsRead(widget.conversationId);
    _scrollController.addListener(_onScroll);
    _prefetchBlockedStatus();
  }

  Future<void> _markMessagesAsRead() async {
    await ChatService().markAsRead(widget.conversationId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _markMessagesAsRead();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      final QuerySnapshot snapshot = _lastDocument == null
          ? await query.get()
          : await query.startAfterDocument(_lastDocument!).get();

      if (snapshot.docs.isNotEmpty) {
        final newMessages = snapshot.docs.map((doc) {
          try {
            return ChatMessage.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          } catch (e) {
            debugPrint('Error parsing message: $e');
            return null;
          }
        }).where((msg) => msg != null).cast<ChatMessage>().toList();

        if (mounted) {
          setState(() {
            _messages.addAll(newMessages);
            _lastDocument = snapshot.docs.last;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _prefetchBlockedStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .get();
    
    if (!mounted) return;
    
    if (doc.exists) {
      final participants = List<String>.from(doc['participants']);
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        final otherUserId = participants.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );
        _isBlockedCache = await AuthService().isUserBlocked(otherUserId);
        setState(() {});
      }
    }
  }

  void _handleTypingStart() {
    if (!_isTyping) {
      setState(() => _isTyping = true);
      PresenceService().setTypingStatus(widget.conversationId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _handleTypingStop);
  }

  void _handleTypingStop() {
    if (_isTyping) {
      setState(() => _isTyping = false);
      PresenceService().setTypingStatus(widget.conversationId, false);
    }
  }

  void _handleSendMessage(String content, MessageType type, {File? mediaFile}) {
    ChatService().sendMessage(
      widget.conversationId,
      content,
      type,
      mediaFile: mediaFile,
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Chat'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat'),
                    content: const Text('Are you sure you want to clear this chat?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  await ChatService().clearChat(widget.conversationId);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Block User'),
                    content: const Text(
                      'Are you sure you want to block this user? You won\'t receive messages from them.',
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  // Get other user's ID
                  final doc = await FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(widget.conversationId)
                      .get();
                      
                  if (doc.exists) {
                    final participants = List<String>.from(doc['participants']);
                    final currentUser = AuthService().currentUser;
                    if (currentUser != null) {
                      final otherUserId = participants.firstWhere(
                        (id) => id != currentUser.uid,
                      );
                      await AuthService().blockUser(otherUserId);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                // Show report dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Report User'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Select a reason for reporting:'),
                        const SizedBox(height: 16),
                        ...['Harassment', 'Spam', 'Inappropriate Content', 'Other']
                            .map((reason) => ListTile(
                                  title: Text(reason),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Show confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Report submitted'),
                                      ),
                                    );
                                  },
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBlockUser(String otherUserId, BuildContext blockContext) async {
    try {
      await AuthService().blockUser(otherUserId);
      if (!mounted) return;
      
      Navigator.of(context).pop(); // Pop the current screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error blocking user: $e')),
      );
    }
  }

  Future<void> _handleUnblockUser(String otherUserId) async {
    try {
      await AuthService().unblockUser(otherUserId);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unblocked')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unblocking user: $e')),
      );
    }
  }

  Widget _buildChatTitle() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('Chat');
        
        final participants = List<String>.from(snapshot.data!['participants']);
        final otherUserId = participants.firstWhere(
          (id) => id != AuthService().currentUser?.uid,
          orElse: () => '',
        );

        return Row(
          children: [
            UserAvatar(
              userId: otherUserId,
              radius: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
                    future: ChatService().getOtherParticipantName(participants),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Chat',
                        style: Theme.of(context).textTheme.titleMedium,
                      );
                    },
                  ),
                  // Update this StreamBuilder to use otherUserId instead of conversationId
                  StreamBuilder<bool>(
                    stream: PresenceService().getUserOnlineStatus(otherUserId),
                    builder: (context, snapshot) {
                      final isOnline = snapshot.data ?? false;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputSection(String otherUserId) {
    return FutureBuilder<bool>(
      future: AuthService().isUserBlocked(otherUserId),
      builder: (context, snapshot) {
        final isBlocked = snapshot.data ?? false;

        if (isBlocked) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'You have blocked this user',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService().unblockUser(otherUserId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User unblocked')),
                      );
                    }
                  },
                  child: const Text('Unblock'),
                ),
              ],
            ),
          );
        }

        return ChatInput(
          conversationId: widget.conversationId,  // Add this line
          onSendMessage: _handleSendMessage,
        );
      },
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Remove redundant loading check
        // Only show loading if we have no cached messages
        if (!snapshot.hasData && _messages.isEmpty) {
          return const SizedBox(); // Return empty widget instead of loading indicator
        }

        // Update messages list with new data
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          _messages.clear();
          _messages.addAll(
            snapshot.data!.docs.map((doc) {
              try {
                return ChatMessage.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              } catch (e) {
                debugPrint('Error parsing message: $e');
                return null;
              }
            }).where((msg) => msg != null).cast<ChatMessage>(),
          );
          _lastDocument = snapshot.data!.docs.last;
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _messages.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _buildMessage(_messages[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .snapshots(),
      builder: (context, snapshot) {
        // Remove this loading check and rely on only one loading indicator
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Safely cast the data to Map<String, dynamic>
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final participants = List<String>.from(data?['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != AuthService().currentUser?.uid,
          orElse: () => '',
        );

        // Use cached blocked status if available
        return Scaffold(
          appBar: AppBar(
            title: _buildChatTitle(),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showOptionsMenu,
              ),
            ],
          ),
          body: Column(
            children: [
              if (_isBlockedCache == true)
                _buildBlockedBanner(otherUserId),
              Expanded(
                child: _isBlockedCache == true
                    ? const Center(child: Text('Unblock user to view messages'))
                    : Column(
                        children: [
                          _buildTypingIndicator(),
                          Expanded(child: _buildMessagesList()),
                        ],
                      ),
              ),
              if (_isBlockedCache != true) 
                ChatInput(
                  conversationId: widget.conversationId,
                  onSendMessage: _handleSendMessage,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockedBanner(String otherUserId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.brightness == Brightness.light
            ? Colors.red.shade50  // Light red background for light theme
            : colorScheme.errorContainer,  // Default dark theme color
        border: Border(
          bottom: BorderSide(
            color: colorScheme.brightness == Brightness.light
                ? Colors.red.shade200  // Light red border for light theme
                : colorScheme.error.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.block,
            color: colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have blocked this user',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.error),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () async {
              await AuthService().unblockUser(otherUserId);
              if (mounted) {
                setState(() => _isBlockedCache = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User unblocked')),
                );
              }
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: PresenceService().getTypingStatus(widget.conversationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final typingUsers = snapshot.data!.entries
            .where((e) => e.value == true)
            .map((e) => e.key)
            .toList();

        if (typingUsers.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Typing...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return ChatMessageBubble(
      message: message,
      showStatus: true,
      conversationId: widget.conversationId,  // Add this parameter
    );
  }
}
