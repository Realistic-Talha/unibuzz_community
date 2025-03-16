import 'package:cloud_firestore/cloud_firestore.dart';

class LostItem {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final bool isLost;
  final DateTime date;
  final String? location;
  final GeoPoint? coordinates;
  final String? imageUrl;
  final List<String> images;
  final DateTime dateReported;
  final DateTime? dateLostFound;
  final String status;
  final List<String> tags;

  LostItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.isLost,
    required this.date,
    this.location,
    this.coordinates,
    this.imageUrl,
    this.images = const [],
    DateTime? dateReported,
    this.dateLostFound,
    this.status = 'open',
    this.tags = const [],
  }) : this.dateReported = dateReported ?? DateTime.now();

  // Make sure userId is accessible
  String get reporterId => userId;

  factory LostItem.fromMap(Map<String, dynamic> map, String id) {
    // Handle timestamps safely
    DateTime? getDateTime(dynamic field) {
      if (field == null) return null;
      if (field is Timestamp) return field.toDate();
      return null;
    }

    return LostItem(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      isLost: map['isLost'] ?? true,
      date: getDateTime(map['date']) ?? DateTime.now(),
      location: map['location'],
      coordinates: map['coordinates'] as GeoPoint?,
      imageUrl: map['imageUrl'],
      images: List<String>.from(map['images'] ?? []),
      dateReported: getDateTime(map['dateReported']) ?? DateTime.now(),
      dateLostFound: getDateTime(map['dateLostFound']),
      status: map['status'] ?? 'open',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'isLost': isLost,
      'date': Timestamp.fromDate(date),
      'location': location,
      'coordinates': coordinates,
      'imageUrl': imageUrl,
      'images': images,
      'dateReported': Timestamp.fromDate(dateReported),
      'dateLostFound': dateLostFound != null 
          ? Timestamp.fromDate(dateLostFound!) 
          : null,
      'status': status,
      'tags': tags,
    };
  }
}
