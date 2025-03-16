import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' show cos, sqrt, asin, pi, sin;

class LocationUtils {
  static double calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // kilometers
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  static bool isWithinRadius(GeoPoint center, GeoPoint point, double radiusKm) {
    return calculateDistance(center, point) <= radiusKm;
  }
}
