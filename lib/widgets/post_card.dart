import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unibuzz_community/models/post_model.dart';
import 'package:unibuzz_community/services/feed_service.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/widgets/comment_section.dart';
import 'package:unibuzz_community/screens/lost_found/item_details_screen.dart';
import 'package:unibuzz_community/utils/image_utils.dart';
import 'package:unibuzz_community/services/post_service.dart';  // Add this import
import 'package:unibuzz_community/screens/posts/edit_post_screen.dart';  // Add this import
import 'package:unibuzz_community/services/report_service.dart';
import 'package:unibuzz_community/widgets/report_dialog.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';

class PostCard extends StatelessWidget {
  final dynamic post; // Change to dynamic to handle both Post and LostItem

  const PostCard({super.key, required this.post});

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is DateTime) {
      return timeago.format(timestamp);
    }
    if (timestamp is Timestamp) {
      return timeago.format(timestamp.toDate());
    }
    return 'Just now';
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes modal expandable
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, // Start at 90% of screen height
        minChildSize: 0.5, // Minimum 50% of screen height
        maxChildSize: 0.95, // Maximum 95% of screen height
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar for dragging
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Comments list with scroll controller
              Expanded(
                child: CommentSection(
                  postId: post.id,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, String? imageUrl) {
    if (imageUrl == null || !imageUrl.startsWith('http')) {
      return const SizedBox.shrink();
    }

    return Hero(
      tag: 'post_image_${post.id}',
      child: GestureDetector(
        onTap: () => showImageViewer(context, imageUrl, heroTag: 'post_image_${post.id}'),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) {
              debugPrint('Error loading image: $error for URL: $url'); // Changed from print to debugPrint
              return Container(
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String userId) {
    return UserAvatar(userId: userId);
  }

  Widget _buildPopupMenu(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final isOwner = currentUser?.uid == (post is Map ? post['userId'] : post.userId);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            if (post is Post) {  // Only allow editing for regular posts
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPostScreen(post: post),
                ),
              );
              
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post updated successfully')),
                );
              }
            }
            break;
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Post'),
                content: const Text('Are you sure you want to delete this post?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            
            if (confirmed == true) {
              await PostService().deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted successfully')),
              );
            }
            break;
          case 'report':
            final reason = await showDialog<String>(
              context: context,
              builder: (context) => const ReportDialog(),
            );
            
            if (reason != null) {
              try {
                await ReportService().reportPost(post.id, reason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post reported successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error reporting post: $e')),
                  );
                }
              }
            }
            break;
        }
      },
      itemBuilder: (context) {
        if (isOwner) {
          return [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ];
        } else {
          return [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag),
                  SizedBox(width: 8),
                  Text('Report'),
                ],
              ),
            ),
          ];
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;  // Add this line
    // Check if this is a lost/found item
    final bool isLostItem = post is Map && post['isLost'] != null;
    
    // Changed print to debugPrint
    debugPrint('Building PostCard with imageUrl: ${post.imageUrl}');

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and category
          ListTile(
            leading: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/profile/:userId',
                arguments: isLostItem ? post['userId'] : post.userId,
              ),
              child: UserAvatar(
                userId: isLostItem ? post['userId'] : post.userId,
              ),
            ),
            title: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/profile/:userId',
                arguments: isLostItem ? post['userId'] : post.userId,
              ),
              child: FutureBuilder<String>(
                future: FeedService().getUserName(
                  isLostItem ? post['userId'] : post.userId,
                ),
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
            subtitle: Text(
              isLostItem 
                ? post['title'] 
                : _getTimeAgo(post.createdAt)
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isLostItem 
                        ? post['isLost'] ? 'Lost Item' : 'Found Item'
                        : post.category,
                  ),
                ),
                _buildPopupMenu(context),
              ],
            ),
            onTap: isLostItem
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(itemId: post.id),
                    ),
                  )
                : null,
          ),
          
          // Caption/Content first
          if (post.content != null && post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                post.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),

          // Image below caption
          _buildImageWidget(context, post.imageUrl),

          // Interaction buttons
          OverflowBar(
            alignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  post.likes.contains(currentUser?.uid)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                onPressed: () {
                  FeedService().toggleLike(post.id);
                },
              ),
              Text('${post.likes.length}'),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => _showComments(context),
              ),
              Text('${post.commentCount}'),
            ],
          ),
        ],
      ),
    );
  }
}
