import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/utils/location_utils.dart';

class LocationPicker extends StatefulWidget {
  final void Function(String location, GeoPoint coordinates) onLocationSelected;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _searchController = TextEditingController();
  GeoPoint? _currentLocation;
  
  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Main Library',
      'coordinates': const GeoPoint(40.7128, -74.0060),
      'description': 'Central library building',
    },
    {
      'name': 'Student Center',
      'coordinates': const GeoPoint(40.7129, -74.0061),
      'description': 'Main student activities hub',
    },
    {
      'name': 'Science Building',
      'coordinates': const GeoPoint(40.7127, -74.0062),
      'description': 'Science and research facilities',
    },
  ];

  List<Map<String, dynamic>> get _filteredLocations {
    final query = _searchController.text.toLowerCase();
    return _locations.where((location) {
      return location['name'].toLowerCase().contains(query) ||
          location['description'].toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search locations...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_currentLocation != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Showing distances from current location',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredLocations.length,
            itemBuilder: (context, index) {
              final location = _filteredLocations[index];
              String? distance;
              
              if (_currentLocation != null) {
                final distanceKm = LocationUtils.calculateDistance(
                  _currentLocation!,
                  location['coordinates'],
                );
                distance = LocationUtils.formatDistance(distanceKm);
              }

              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(location['name']),
                subtitle: Text(
                  distance != null
                      ? '${location['description']} • $distance away'
                      : location['description'],
                ),
                onTap: () {
                  widget.onLocationSelected(
                    location['name'],
                    location['coordinates'],
                  );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
