import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unibuzz_community/services/location_service.dart';

class MapView extends StatefulWidget {
  /// Initial location to center the map on
  final GeoPoint initialLocation;
  final bool showUserLocation;
  final void Function(LatLng)? onLocationSelected;
  final Set<Marker>? markers;

  const MapView({
    super.key,
    required this.initialLocation,
    this.showUserLocation = true,
    this.onLocationSelected,
    this.markers,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers = widget.markers?.toSet() ?? {};
    if (widget.showUserLocation) {
      _addUserLocationMarker();
    }
  }

  Future<void> _addUserLocationMarker() async {
    final location = await LocationService().getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(location.latitude, location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.initialLocation.latitude,
          widget.initialLocation.longitude,
        ),
        zoom: 15,
      ),
      markers: _markers,
      myLocationEnabled: widget.showUserLocation,
      myLocationButtonEnabled: widget.showUserLocation,
      onMapCreated: (controller) => _controller = controller,
      onTap: widget.onLocationSelected != null
          ? (latLng) => widget.onLocationSelected!(latLng)
          : null,
    );
  }
}
