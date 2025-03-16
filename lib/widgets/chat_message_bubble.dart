import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unibuzz_community/models/chat_model.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/services/chat_service.dart';  // Add this import
import 'package:unibuzz_community/widgets/voice_message_player.dart';  // Add this import
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:unibuzz_community/utils/image_utils.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';  // Add this import

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showStatus;
  final String conversationId;  // Add this field

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.showStatus = false,
    required this.conversationId,  // Add this parameter
  });

  bool get isCurrentUser => 
      message.senderId == AuthService().currentUser?.uid;

  String _formatTime(DateTime timestamp) {
    // Show actual time for messages from today
    if (DateTime.now().difference(timestamp).inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    // Show relative time for older messages
    return timeago.format(timestamp, locale: 'en_short');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building message: ${message.content}, isRead: ${message.isRead}');
    debugPrint('Message timestamp: ${message.timestamp}');
    debugPrint('Message isRead: ${message.isRead}');
    debugPrint('ShowStatus: $showStatus');

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar on left for received messages
                if (!isCurrentUser) ...[
                  UserAvatar(
                    userId: message.senderId,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Message content
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: isCurrentUser 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildContent(context),
                        const SizedBox(height: 4),
                        // Time and read status
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),  // Use new time format
                              style: TextStyle(
                                fontSize: 11,
                                color: (isCurrentUser 
                                    ? Theme.of(context).colorScheme.onPrimary 
                                    : Theme.of(context).colorScheme.onSurfaceVariant
                                ).withOpacity(0.7),
                              ),
                            ),
                            if (isCurrentUser && showStatus) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead ? Icons.done_all : Icons.done,
                                size: 12,
                                color: message.isRead
                                    ? Colors.blue
                                    : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Avatar on right for sent messages
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  UserAvatar(
                    userId: message.senderId,
                    radius: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      
      case MessageType.image:
        if (message.mediaUrl == null) {
          return const Text('Invalid image');
        }
        return _buildImageContent(context);
      
      case MessageType.file:
        return _buildFileContent(context);
      
      case MessageType.link:
        return _buildLinkContent(context);
        
      case MessageType.location:
        return _buildLocationContent(context);
        
      case MessageType.voice:
        if (message.mediaUrl == null) {
          return const Text('Invalid voice message');
        }
        return VoiceMessagePlayer(url: message.mediaUrl!);
    }
  }

  // Add helper methods for each content type
  Widget _buildImageContent(BuildContext context) {
    if (message.mediaUrl == null) {
      return const Text('Invalid image URL');
    }
    
    final heroTag = 'chat_image_${message.id}';
    return Hero(
      tag: heroTag,
      child: GestureDetector(
        onTap: () => showImageViewer(context, message.mediaUrl!, heroTag: heroTag),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => 
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => 
                const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.attach_file),
      title: Text(
        message.content,
        style: TextStyle(
          color: isCurrentUser
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () async {
        if (message.mediaUrl != null) {
          final uri = Uri.parse(message.mediaUrl!);
          try {
            if (await url_launcher.canLaunchUrl(uri)) {
              await url_launcher.launchUrl(
                uri,
                mode: url_launcher.LaunchMode.externalApplication,
              );
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open file')),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${e.toString()}')),
              );
            }
          }
        }
      },
    );
  }

  Widget _buildLinkContent(BuildContext context) {
    return const Icon(Icons.link);
  }

  Widget _buildLocationContent(BuildContext context) {
    return const Icon(Icons.location_on);
  }

  void _showMessageOptions(BuildContext context) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  // TODO: Implement edit functionality
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                // TODO: Implement forward functionality
                Navigator.pop(context);
              },
            ),
            if (message.type == MessageType.file || message.type == MessageType.image)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Save'),
                onTap: () async {
                  // TODO: Implement save functionality
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                // TODO: Implement reply functionality
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ChatService().deleteMessage(conversationId, message.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting message: $e')),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
