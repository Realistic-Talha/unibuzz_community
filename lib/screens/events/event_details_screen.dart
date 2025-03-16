import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unibuzz_community/models/event_model.dart';
import 'package:unibuzz_community/services/event_service.dart';
import 'package:unibuzz_community/services/auth_service.dart';
import 'package:unibuzz_community/widgets/map_view.dart';
import 'package:unibuzz_community/screens/events/edit_event_screen.dart';  // Add this import

class EventDetailsScreen extends StatelessWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  void _showOptionsMenu(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final isOwner = currentUser?.uid == event.organizerId;

    if (!isOwner) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Event'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEventScreen(event: event),
                  ),
                );
                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event updated successfully')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Event', style: TextStyle(color: Colors.red)),
              onTap: () => _showDeleteConfirmation(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Event'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              try {
                await EventService().deleteEvent(event.id);
                if (context.mounted) {
                  Navigator.pop(context); // Return to events list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting event: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final isOwner = currentUser?.uid == event.organizerId;
    final isAttending = event.attendees.contains(currentUser?.uid);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Event Image or Placeholder
                  if (event.imageUrl != null && 
                      event.imageUrl!.isNotEmpty && 
                      event.imageUrl!.startsWith('http'))
                    CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.event, size: 64),
                      ),
                    )
                  else
                    Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.event, size: 64),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Title and category at the bottom
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer
                                    .withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                event.category,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.people_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.attendees.length} attending',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showOptionsMenu(context),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(event.description),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year}',
                    ),
                    subtitle: Text(
                      '${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(event.location),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SizedBox(
                          height: 300,
                          child: MapView(initialLocation: event.coordinates),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (event.maxAttendees > 0)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: event.attendees.length / event.maxAttendees,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${event.attendees.length}/${event.maxAttendees} spots filled',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (isOwner) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Event'),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditEventScreen(event: event),
                        ),
                      );
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event updated successfully')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(isAttending ? Icons.event_busy : Icons.event_available),
                  label: Text(isAttending ? 'Cancel' : 'Attend'),
                  onPressed: event.isFull && !isAttending
                      ? null
                      : () => EventService().toggleAttendance(event.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
