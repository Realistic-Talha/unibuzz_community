import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unibuzz_community/services/map_service.dart';
import 'package:unibuzz_community/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import

class LocationMapPicker extends StatefulWidget {
  final void Function(String name, String address, LatLng coordinates) onLocationSelected;

  const LocationMapPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await LocationService().getCurrentLocation();
      if (location != null && mounted) {
        final latLng = LatLng(location.latitude, location.longitude);
        setState(() {
          _selectedLocation = latLng;
          _markers = {
            Marker(
              markerId: const MarkerId('current'),
              position: latLng,
              infoWindow: const InfoWindow(title: 'Current Location'),
            ),
          };
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
    } catch (e) {
      // Handle location error
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await MapService().searchNearbyPlaces(query);
      setState(() => _searchResults = results);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search location...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _searchPlaces,
          ),
        ),
        if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(place['name']),
                  subtitle: Text(place['address']),
                  onTap: () {
                    final coordinates = place['coordinates'] as GeoPoint;
                    widget.onLocationSelected(
                      place['name'],
                      place['address'],
                      LatLng(coordinates.latitude, coordinates.longitude),
                    );
                    Navigator.pop(context);
                  },
                );
              },
            ),
          )
        else
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? const LatLng(0, 0),
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) => _mapController = controller,
              onTap: (latLng) async {
                final placeDetails = await MapService().getPlaceDetails(latLng);
                widget.onLocationSelected(
                  placeDetails['name'],
                  placeDetails['address'],
                  latLng,
                );
                Navigator.pop(context);
              },
            ),
          ),
      ],
    );
  }
}
