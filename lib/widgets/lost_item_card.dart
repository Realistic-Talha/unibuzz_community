import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:unibuzz_community/models/lost_item_model.dart';
import 'package:unibuzz_community/screens/lost_found/item_details_screen.dart';
import 'package:unibuzz_community/services/lost_found_service.dart';

class LostItemCard extends StatelessWidget {
  final LostItem item;

  const LostItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailsScreen(itemId: item.id),  // Fix: use itemId parameter
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.images.isNotEmpty)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: item.images.first,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => 
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => 
                      const Icon(Icons.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Chip(
                        label: Text(item.isLost ? 'Lost' : 'Found'),
                        backgroundColor: item.isLost
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location ?? 'Location not specified',  // Fix: handle nullable location
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text(timeago.format(item.dateReported)),
                      const Spacer(),
                      if (item.category != null)
                        Chip(
                          label: Text(item.category!),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
