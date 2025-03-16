import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final GeoPoint coordinates;
  final DateTime dateTime;
  final String organizerId;
  final String imageUrl;
  final int maxAttendees;
  final List<String> attendees;
  final DateTime createdAt;

  bool get isFull => maxAttendees > 0 && attendees.length >= maxAttendees;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.coordinates,
    required this.dateTime,
    required this.organizerId,
    this.imageUrl = '',
    this.maxAttendees = 0,
    this.attendees = const [],
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      coordinates: map['coordinates'] as GeoPoint? ?? const GeoPoint(0, 0),
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      organizerId: map['organizerId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      maxAttendees: map['maxAttendees'] ?? 0,
      attendees: List<String>.from(map['attendees'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'coordinates': coordinates,
      'dateTime': Timestamp.fromDate(dateTime),
      'organizerId': organizerId,
      'imageUrl': imageUrl,
      'maxAttendees': maxAttendees,
      'attendees': attendees,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
