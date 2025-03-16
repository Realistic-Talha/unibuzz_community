import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/lost_found_service.dart';
import 'package:unibuzz_community/utils/location_utils.dart';
import 'package:unibuzz_community/models/lost_item_model.dart';
import 'package:unibuzz_community/screens/lost_found/item_details_screen.dart';

class ItemSearchDelegate extends SearchDelegate<String> {
  final bool? isLost;
  final GeoPoint? currentLocation;

  ItemSearchDelegate({this.isLost, this.currentLocation});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: LostFoundService().searchItems(
        query: query,
        isLost: isLost,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return const Center(child: Text('No items found'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index].data() as Map<String, dynamic>;
            final location = item['coordinates'] as GeoPoint;
            String? distance;
            
            if (currentLocation != null) {
              final distanceKm = LocationUtils.calculateDistance(
                currentLocation!,
                location,
              );
              distance = LocationUtils.formatDistance(distanceKm);
            }

            return ListTile(
              leading: item['images']?.isNotEmpty == true
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(item['images'][0]),
                    )
                  : const CircleAvatar(child: Icon(Icons.search)),
              title: Text(item['title']),
              subtitle: Text(
                distance != null
                    ? '${item['location']} • $distance away'
                    : item['location'],
              ),
              trailing: Chip(
                label: Text(item['category']),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(
                      itemId: items[index].id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Enter at least 2 characters to search'),
      );
    }
    return buildResults(context);
  }
}
