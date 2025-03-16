import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/models/lost_item_model.dart';  // Updated import path
import 'package:unibuzz_community/services/lost_found_service.dart';
import 'package:unibuzz_community/widgets/map_view.dart';
import 'package:unibuzz_community/widgets/user_avatar.dart';
import 'package:unibuzz_community/services/feed_service.dart';  // Add this import
import 'package:unibuzz_community/services/chat_service.dart';
import 'package:unibuzz_community/screens/chat/chat_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
  });

  Widget _buildContactButton(BuildContext context, String userId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            // Create or get existing conversation
            final conversationId = await ChatService().createOrGetConversation(userId);
            
            if (context.mounted) {
              // Navigate to chat detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: conversationId,
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error starting conversation: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.chat),
        label: const Text('Contact Owner'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: LostFoundService().getItem(itemId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(child: Text('Item not found'));
          }

          final item = LostItem.fromMap(data, snapshot.data!.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(item.category),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(item.date.toString()),  // Changed from dateFound to date
                ),
                if (item.location != null)  // Changed from locationFound to location
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(item.location!),  // Changed from locationFound to location
                    onTap: () {
                      if (item.coordinates != null) {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => SizedBox(
                            height: 300,
                            child: MapView(
                              initialLocation: item.coordinates!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                const Divider(height: 32),
                ListTile(
                  leading: UserAvatar(
                    imageUrl: null,
                    username: null,
                  ),
                  title: FutureBuilder<String>(
                    future: FeedService().getUserName(item.userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Unknown User');
                      }
                      return Text(snapshot.data ?? 'Loading...');
                    },
                  ),
                  subtitle: const Text('Posted by'),
                ),
                const SizedBox(height: 32),
                _buildContactButton(context, item.userId),
              ],
            ),
          );
        },
      ),
    );
  }
}