import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:unibuzz_community/utils/location_utils.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    return permission != LocationPermission.deniedForever;
  }

  Future<GeoPoint?> getCurrentLocation() async {
    try {
      if (!await requestPermission()) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> findNearbyItems({
    required GeoPoint center,
    required double radiusKm,
    String? category,
    bool? isLost,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    Query query = firestore.collection('lost_items');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (isLost != null) {
      query = query.where('isLost', isEqualTo: isLost);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final itemLocation = data['coordinates'] as GeoPoint;
      return LocationUtils.isWithinRadius(center, itemLocation, radiusKm);
    }).toList();
  }

  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
